import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/services/program_executor.dart';
import 'package:robocode/widgets/block_editor/block_types.dart';
import 'support/fake_robot_client.dart';

Block block(
  BlockType type, {
  Map<String, dynamic>? parameters,
  List<Block>? children,
  double y = 0,
}) => Block(
  type: type,
  position: Offset(0, y),
  color: Colors.blue,
  parameters: parameters ?? {},
  children: children,
);

void main() {
  late FakeRobotClient robot;
  setUp(() => robot = FakeRobotClient());
  tearDown(() => robot.dispose());

  test('false and nested conditions preserve tree semantics', () async {
    robot.distance = 25;
    final program = [
      block(BlockType.ifDistance, children: [block(BlockType.moveForward)]),
    ];
    expect(
      (await ProgramExecutor(robot).run(program)).status,
      ProgramStatus.completed,
    );
    expect(robot.calls, ['STOP']);
    robot.calls.clear();
    robot.distance = 10;
    expect(
      (await ProgramExecutor(robot).run([
        block(
          BlockType.ifDistance,
          children: [
            block(BlockType.turnLeft),
            block(
              BlockType.ifDistance,
              parameters: {'distance': 5},
              children: [block(BlockType.moveForward)],
            ),
          ],
        ),
      ])).status,
      ProgramStatus.completed,
    );
    expect(robot.calls, ['L90', 'STOP']);
  });

  test(
    'movement waits for completion, root order is visual, and inputs are a snapshot',
    () async {
      final completion = Completer<bool>();
      robot.onCommand = (command) =>
          command == 'F10' ? completion.future : Future.value(true);
      final first = block(
        BlockType.moveForward,
        parameters: {'distance': 10},
        y: 10,
      );
      final second = block(BlockType.turnRight, y: 20);
      final run = ProgramExecutor(robot).run([second, first]);
      first.parameters['distance'] = 500;
      second.parameters['angle'] = 180;
      await Future<void>.delayed(Duration.zero);
      expect(robot.calls, ['F10']);
      completion.complete(true);
      expect((await run).status, ProgramStatus.completed);
      expect(robot.calls, ['F10', 'R90', 'STOP']);
    },
  );

  test(
    'failed movement aborts later blocks and can never report success',
    () async {
      robot.onCommand = (command) async => command != 'F100';
      final result = await ProgramExecutor(
        robot,
      ).run([block(BlockType.moveForward), block(BlockType.turnRight)]);
      expect(result.status, ProgramStatus.failed);
      expect(robot.calls, ['F100', 'STOP']);
    },
  );

  test(
    'cancel interrupts a long wait without starting the next block',
    () async {
      final executor = ProgramExecutor(robot);
      final run = executor.run([
        block(BlockType.wait, parameters: {'time': 60000}),
        block(BlockType.moveForward),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(await executor.cancel(), isTrue);
      expect(
        (await run.timeout(const Duration(seconds: 1))).status,
        ProgramStatus.stopped,
      );
      expect(robot.calls, ['STOP']);
    },
  );

  test(
    'cancel interrupts a pending movement and a second run cannot overlap',
    () async {
      robot.onCommand = (command) =>
          command == 'F100' ? Completer<bool>().future : Future.value(true);
      final executor = ProgramExecutor(robot);
      final run = executor.run([
        block(BlockType.moveForward),
        block(BlockType.turnLeft),
      ]);
      expect(
        (await executor.run([block(BlockType.turnRight)])).status,
        ProgramStatus.failed,
      );
      await executor.cancel();
      expect((await run).status, ProgramStatus.stopped);
      expect(robot.calls, ['F100', 'STOP']);
    },
  );

  test(
    'disconnect interrupts waits, and invalid distance stops before child movement',
    () async {
      final executor = ProgramExecutor(robot);
      final run = executor.run([
        block(BlockType.wait, parameters: {'time': 60000}),
      ]);
      robot.disconnect();
      expect(
        (await run.timeout(const Duration(seconds: 1))).status,
        ProgramStatus.failed,
      );
      robot.connected = true;
      robot.distance = null;
      expect(
        (await executor.run([
          block(BlockType.ifDistance, children: [block(BlockType.moveForward)]),
        ])).status,
        ProgramStatus.failed,
      );
      expect(robot.calls, ['STOP']);
    },
  );

  test(
    'auto navigation is bounded and STOP completes before following motion',
    () async {
      final executor = ProgramExecutor(
        robot,
        autoDuration: const Duration(milliseconds: 5),
      );
      final result = await executor.run([
        block(BlockType.autoNavigate),
        block(BlockType.turnRight),
      ]);
      expect(result.status, ProgramStatus.completed);
      expect(robot.calls, ['AUTO_NAV', 'STOP', 'R90', 'STOP']);
    },
  );

  test(
    'auto navigation cancellation immediately stops and skips following motion',
    () async {
      final executor = ProgramExecutor(robot);
      final run = executor.run([
        block(BlockType.autoNavigate),
        block(BlockType.turnRight),
      ]);
      await Future<void>.delayed(Duration.zero);
      await executor.cancel();
      expect((await run).status, ProgramStatus.stopped);
      expect(robot.calls, ['AUTO_NAV', 'STOP']);
    },
  );

  test(
    'an autonomous safety fault fails the run after mode enable was acknowledged',
    () async {
      final executor = ProgramExecutor(robot);
      final run = executor.run([
        block(BlockType.autoNavigate),
        block(BlockType.moveForward),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(robot.calls, ['AUTO_NAV']);
      robot.faultEvents.add('Ultrasonic sample invalid');
      final result = await run.timeout(const Duration(seconds: 1));
      expect(result.status, ProgramStatus.failed);
      expect(result.message, contains('Ultrasonic sample invalid'));
      expect(robot.calls, ['AUTO_NAV', 'STOP']);
      expect(robot.faultEvents.hasListener, isFalse);
    },
  );

  test('a failed STOP can be retried without starting a new program', () async {
    var stopAttempts = 0;
    robot.onCommand = (_) async => ++stopAttempts > 1;
    final executor = ProgramExecutor(robot);
    final run = executor.run([
      block(BlockType.wait, parameters: {'time': 60000}),
    ]);
    expect(await executor.cancel(), isFalse);
    final result = await run;
    expect(result.stopConfirmed, isFalse);
    expect(robot.calls, ['STOP']);
    expect(await executor.cancel(), isTrue);
    expect(robot.calls, ['STOP', 'STOP']);
  });

  test(
    'validation rejects cycles and out-of-range parameters before any command',
    () async {
      final cycle = block(BlockType.ifDistance);
      cycle.children.add(cycle);
      final invalidContainer = block(BlockType.wait);
      invalidContainer.children.add(block(BlockType.moveForward));
      final executor = ProgramExecutor(robot);
      for (final program in [
        [cycle],
        [
          block(BlockType.moveForward, parameters: {'distance': 501}),
        ],
        [invalidContainer],
        [
          block(BlockType.turnLeft, parameters: {'angle': 90.5}),
        ],
      ]) {
        expect((await executor.run(program)).status, ProgramStatus.failed);
      }
      expect(robot.calls, isEmpty);
    },
  );
}
