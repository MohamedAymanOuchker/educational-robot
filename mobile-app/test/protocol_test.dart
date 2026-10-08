import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/services/robot_client.dart';
import 'package:robocode/services/robot_protocol.dart';

void main() {
  late RobotProtocol robot;
  late List<String> writes;

  void reply(int id, [String status = 'done']) => robot.receive(
    utf8.encode(
      '${jsonEncode({'type': 'command', 'id': id, 'status': status})}\n',
    ),
  );

  setUp(() {
    writes = [];
    robot = RobotProtocol(
      write: (bytes) async {
        expect(bytes.length, lessThanOrEqualTo(20));
        writes.add(utf8.decode(bytes));
      },
    );
    robot.setStatus(ConnectionStatus.connected);
  });
  tearDown(() => robot.dispose());

  test('a partial telemetry record cannot refresh old optional readings', () {
    robot.receive(
      utf8.encode(
        '${jsonEncode({'type': 'telemetry', 'battery': 90, 'temperature': 25, 'heading': 40})}\n',
      ),
    );
    expect(robot.lastSensorData['battery'], 90);
    robot.receive(
      utf8.encode(
        '${jsonEncode({'type': 'telemetry', 'distance': 30, 'distance_valid': true, 'distance_age_ms': 0})}\n',
      ),
    );
    expect(robot.lastSensorData.containsKey('battery'), isFalse);
    expect(robot.lastSensorData.containsKey('temperature'), isFalse);
    expect(robot.lastSensorData.containsKey('heading'), isFalse);
  });

  test(
    'movement uses compact units and waits for its own completion',
    () async {
      var finished = false;
      final operation = robot.moveForward(100).then((value) {
        finished = true;
        return value;
      });
      expect(writes, ['1:F100\n']);
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      reply(22);
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      reply(1);
      expect(await operation, isTrue);
      final turn = robot.turnRight(90);
      expect(writes.last, '2:R90\n');
      reply(2, 'error');
      expect(await turn, isFalse);
    },
  );

  test(
    'STOP preempts an uncompleted write and rejects new motion meanwhile',
    () async {
      robot.dispose();
      robot = RobotProtocol(
        write: (bytes) {
          writes.add(utf8.decode(bytes));
          return Completer<void>().future;
        },
      )..setStatus(ConnectionStatus.connected);
      final movement = robot.moveBackward(500);
      final stop = robot.stopRobot();
      expect(writes, ['1:B500\n', '2:STOP\n']);
      expect(await movement, isFalse);
      expect(await robot.turnLeft(30), isFalse);
      reply(1); // A late completion cannot complete STOP.
      reply(2);
      expect(await stop, isTrue);
    },
  );

  test(
    'split UTF-8 frames and multiple records are assembled without data loss',
    () async {
      final messages = <String>[];
      final sub = robot.commandResponse.listen(messages.add);
      final operation = robot.turnLeft(90);
      final bytes = utf8.encode(
        '${jsonEncode({'type': 'telemetry', 'distance': 24.5, 'distance_valid': true, 'distance_age_ms': 20})}\n${jsonEncode({'type': 'command', 'id': 1, 'status': 'done', 'message': 'terminé'})}\n',
      );
      for (final byte in bytes) {
        robot.receive([byte]);
      }
      expect(await operation, isTrue);
      expect(await robot.getDistance(), 24.5);
      await Future<void>.delayed(Duration.zero);
      expect(messages.single, contains('terminé'));
      await sub.cancel();
    },
  );

  test('oversized or malformed frames recover only at their newline', () async {
    final operation = robot.moveForward(1);
    robot.receive(List.filled(2000, 120));
    robot.receive(utf8.encode('{"type":"command","id":1,"status":"done"}\n'));
    robot.receive(utf8.encode('not-json\n[1,2]\n'));
    reply(1, 'cancelled');
    expect(await operation, isFalse);
  });

  test(
    'telemetry freshness includes sensor age and status never destroys it',
    () async {
      var now = DateTime(2026);
      robot.dispose();
      robot = RobotProtocol(write: (_) async {}, now: () => now)
        ..setStatus(ConnectionStatus.connected);
      void telemetry(Object? distance, bool valid, int age) => robot.receive(
        utf8.encode(
          '${jsonEncode({'type': 'telemetry', 'distance': distance, 'distance_valid': valid, 'distance_age_ms': age})}\n',
        ),
      );
      telemetry(30, true, 100);
      robot.receive(utf8.encode('{"type":"status","state":"idle"}\n'));
      expect(await robot.getDistance(), 30.0);
      now = now.add(const Duration(milliseconds: 401));
      expect(await robot.getDistance(), isNull);
      telemetry(null, false, 0);
      expect(await robot.getDistance(), isNull);
      telemetry(20, true, 501);
      expect(await robot.getDistance(), isNull);
      telemetry(12, true, 0);
      robot.setStatus(ConnectionStatus.disconnected);
      expect(await robot.getDistance(), isNull);
      expect(robot.lastSensorData, isEmpty);
    },
  );

  test(
    'disconnect fails a pending command and clears partial frames',
    () async {
      final operation = robot.moveForward(10);
      robot.receive(utf8.encode('{"type":"command",'));
      robot.setStatus(ConnectionStatus.disconnected);
      expect(await operation, isFalse);
      robot.setStatus(ConnectionStatus.connected);
      final next = robot.turnLeft(10);
      reply(2);
      expect(await next, isTrue);
    },
  );

  test(
    'incomplete telemetry cannot reuse the previous validity and age',
    () async {
      for (final broken in [
        {'distance': 10},
        {'distance': 10, 'distance_valid': true},
        {'distance_valid': true, 'distance_age_ms': 0},
        {'distance': '10', 'distance_valid': true, 'distance_age_ms': 0},
        {'distance': 10, 'distance_valid': true, 'distance_age_ms': -1},
      ]) {
        robot.receive(
          utf8.encode(
            '{"type":"telemetry","distance":20,"distance_valid":true,"distance_age_ms":0}\n',
          ),
        );
        expect(await robot.getDistance(), 20.0);
        robot.receive(
          utf8.encode('${jsonEncode({'type': 'telemetry', ...broken})}\n'),
        );
        expect(await robot.getDistance(), isNull);
      }
    },
  );

  test('safety faults are surfaced after AUTO_NAV was acknowledged', () async {
    final fault = robot.faults.first;
    final auto = robot.autoNavigate();
    reply(1);
    expect(await auto, isTrue);
    robot.receive(utf8.encode('{"type":"fault","message":"Sensor invalid"}\n'));
    expect(await fault, 'Sensor invalid');
  });

  test(
    'failed write and command deadline are failures; timeout requests STOP',
    () async {
      robot.dispose();
      robot = RobotProtocol(
        write: (_) => Future.error(StateError('write failed')),
      )..setStatus(ConnectionStatus.connected);
      expect(await robot.moveForward(1), isFalse);
      robot.dispose();
      robot = RobotProtocol(
        write: (bytes) async => writes.add(utf8.decode(bytes)),
        commandTimeout: (_) => const Duration(milliseconds: 15),
      )..setStatus(ConnectionStatus.connected);
      expect(await robot.moveForward(1), isFalse);
      expect(writes.last, '2:STOP\n');
      reply(2);
    },
  );

  test(
    'unsupported commands and invalid parameters never reach transport',
    () async {
      for (final command in [
        'GET_SENSORS',
        'GET_DISTANCE',
        'SPEED:50',
        'F501',
        'L361',
        'F-1',
        'F2.3',
      ]) {
        expect(await robot.sendCommand(command), isFalse);
      }
      expect(await robot.moveForward(double.nan), isFalse);
      expect(await robot.moveForward(1.2), isFalse);
      expect(await robot.requestSensorData(), isFalse);
      expect(writes, isEmpty);
      expect(
        RobotProtocol.timeoutForCommand('F500'),
        greaterThan(const Duration(minutes: 3)),
      );
    },
  );

  test(
    'an unconfirmed STOP closes transport even with a hung native write',
    () async {
      robot.dispose();
      var disconnects = 0;
      robot = RobotProtocol(
        write: (_) => Completer<void>().future,
        commandTimeout: (_) => const Duration(milliseconds: 10),
        onStopUnconfirmed: () async {
          disconnects++;
          robot.setStatus(ConnectionStatus.disconnected);
        },
      )..setStatus(ConnectionStatus.connected);
      final movement = robot.moveForward(10);
      expect(await robot.stopRobot(), isFalse);
      expect(await movement, isFalse);
      expect(disconnects, 1);
      expect(robot.isConnected, isFalse);
    },
  );
}
