import 'dart:async';
import 'dart:convert';

import 'robot_client.dart';

/// The same bounded, newline-framed protocol is used over every BLE MTU.
class RobotProtocol implements RobotClient {
  RobotProtocol({
    required this.write,
    this.onStopUnconfirmed,
    Duration Function(String)? commandTimeout,
    DateTime Function()? now,
  }) : _commandTimeout = commandTimeout ?? timeoutForCommand,
       _now = now ?? DateTime.now;

  final Future<void> Function(List<int>) write;
  final Future<void> Function()? onStopUnconfirmed;
  final Duration Function(String) _commandTimeout;
  final DateTime Function() _now;
  final _statuses = StreamController<ConnectionStatus>.broadcast();
  final _responses = StreamController<String>.broadcast();
  final _sensors = StreamController<Map<String, dynamic>>.broadcast();
  final _faults = StreamController<String>.broadcast();
  final Map<int, _PendingCommand> _pending = {};
  final List<int> _frame = [];
  final Map<String, dynamic> _lastSensorData = {};
  bool _discardFrame = false;
  int _nextId = 1;
  DateTime? _distanceReceivedAt;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Future<bool>? _stopFuture;

  ConnectionStatus get status => _status;
  @override
  bool get isConnected => _status == ConnectionStatus.connected;
  @override
  Stream<ConnectionStatus> get connectionStatus => _statuses.stream;
  @override
  Stream<String> get commandResponse => _responses.stream;
  @override
  Stream<Map<String, dynamic>> get sensorData => _sensors.stream;
  @override
  Stream<String> get faults => _faults.stream;
  Map<String, dynamic> get lastSensorData => Map.of(_lastSensorData);

  static Duration timeoutForCommand(String command) {
    // 28BYJ-48 half stepping is deliberately slow. These are failure deadlines,
    // never substitutes for the firmware's actual completion event.
    if (RegExp(r'^[FB]\d+$').hasMatch(command)) {
      return Duration(seconds: 10 + int.parse(command.substring(1)));
    }
    if (RegExp(r'^[LR]\d+$').hasMatch(command)) {
      return Duration(
        milliseconds: 10000 + 120 * int.parse(command.substring(1)),
      );
    }
    return const Duration(seconds: 5);
  }

  void setStatus(ConnectionStatus value) {
    _status = value;
    if (!isConnected) {
      _cancelPending('Connection closed');
      _frame.clear();
      _discardFrame = false;
      _lastSensorData.clear();
      _distanceReceivedAt = null;
    }
    _statuses.add(value);
  }

  Future<bool> sendCommand(String command) {
    if (command == 'STOP') {
      return _stopFuture ??= _send(
        command,
      ).whenComplete(() => _stopFuture = null);
    }
    if (_stopFuture != null || _pending.isNotEmpty) {
      _responses.add('Command rejected: robot is busy');
      return Future.value(false);
    }
    return _send(command);
  }

  Future<bool> _send(String command) async {
    if (!isConnected || !_validCommand(command)) return false;
    if (command == 'STOP') _cancelPending('Cancelled by STOP');
    final id = _nextId;
    _nextId = _nextId == 65535 ? 1 : _nextId + 1;
    final bytes = utf8.encode('$id:$command\n');
    if (bytes.length > 20) return false;
    final pending = _PendingCommand();
    _pending[id] = pending;
    pending.timer = Timer(_commandTimeout(command), () {
      _complete(id, false, 'Command $id timed out');
      if (command != 'STOP' && isConnected) unawaited(stopRobot());
    });
    // Do not await a hung write before starting the deadline. STOP can preempt
    // this pending command immediately; no application command queue exists.
    unawaited(
      Future<void>.sync(() => write(bytes)).catchError((Object error) {
        _complete(id, false, 'Write failed: $error');
      }),
    );
    final succeeded = await pending.result.future;
    if (command == 'STOP' && !succeeded && onStopUnconfirmed != null) {
      try {
        await onStopUnconfirmed!();
      } catch (_) {
        // The result remains unconfirmed even if the transport cannot close.
      }
    }
    return succeeded;
  }

  bool _validCommand(String command) {
    if (const ['STOP', 'AUTO_NAV', 'AUTO_OFF'].contains(command)) return true;
    final match = RegExp(r'^([FBLR])(\d+)$').firstMatch(command);
    if (match == null) return false;
    final value = int.tryParse(match.group(2)!);
    final max = 'FB'.contains(match.group(1)!) ? 500 : 360;
    return value != null && value >= 0 && value <= max;
  }

  void _complete(int id, bool success, String message) {
    final pending = _pending.remove(id);
    if (pending == null) return;
    pending.timer?.cancel();
    _responses.add(message);
    pending.result.complete(success);
  }

  void _cancelPending(String message) {
    for (final id in _pending.keys.toList()) {
      _complete(id, false, message);
    }
  }

  /// Accept arbitrary notification fragments, including split UTF-8 characters.
  void receive(List<int> bytes) {
    if (!isConnected) return;
    for (final byte in bytes) {
      if (byte == 10) {
        if (!_discardFrame && _frame.isNotEmpty) _handleFrame(_frame);
        _frame.clear();
        _discardFrame = false;
      } else if (!_discardFrame) {
        if (_frame.length >= 1024) {
          _frame.clear();
          _discardFrame = true;
        } else {
          _frame.add(byte);
        }
      }
    }
  }

  void _handleFrame(List<int> bytes) {
    try {
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic>) return;
      if (value['type'] == 'command') {
        final id = value['id'];
        final status = value['status'];
        if (id is! int ||
            !const ['done', 'error', 'cancelled'].contains(status)) {
          return;
        }
        _complete(
          id,
          status == 'done',
          'Command $id: $status${value['message'] == null ? '' : ' (${value['message']})'}',
        );
      } else if (value['type'] == 'telemetry') {
        _lastSensorData
          ..clear()
          ..addAll(value);
        // Treat the sample as an atomic value. A partial packet cannot inherit
        // validity or age from an older reading and authorize new movement.
        final distance = value['distance'];
        final age = value['distance_age_ms'];
        final valid =
            value['distance_valid'] == true &&
            distance is num &&
            distance.isFinite &&
            distance >= 0 &&
            age is num &&
            age.isFinite &&
            age >= 0;
        _lastSensorData['distance'] = valid ? distance : null;
        _lastSensorData['distance_valid'] = valid;
        _lastSensorData['distance_age_ms'] = valid ? age : null;
        _distanceReceivedAt = valid ? _now() : null;
        _sensors.add(lastSensorData);
      } else if (value['type'] == 'fault') {
        final message = value['message'];
        final reason = message is String ? message : 'Robot safety fault';
        _faults.add(reason);
        _cancelPending(reason);
      }
      // Status/command replies do not replace the last sensor reading.
    } on FormatException {
      // A malformed frame is isolated at its newline; the next frame can recover.
    }
  }

  Future<bool> sendMovementCommand(String direction, {double value = 100}) {
    const names = {'FORWARD': 'F', 'BACKWARD': 'B', 'LEFT': 'L', 'RIGHT': 'R'};
    if (!value.isFinite || value != value.truncateToDouble())
      return Future.value(false);
    return sendCommand('${names[direction] ?? direction}${value.toInt()}');
  }

  @override
  Future<bool> moveForward(double distance) =>
      sendMovementCommand('F', value: distance);
  @override
  Future<bool> moveBackward(double distance) =>
      sendMovementCommand('B', value: distance);
  @override
  Future<bool> turnLeft(double angle) => sendMovementCommand('L', value: angle);
  @override
  Future<bool> turnRight(double angle) =>
      sendMovementCommand('R', value: angle);
  @override
  Future<bool> stopRobot() => sendCommand('STOP');
  @override
  Future<bool> autoNavigate() => sendCommand('AUTO_NAV');

  // Firmware streams readings continuously; GET_* is not a command.
  Future<bool> requestSensorData() async => await getDistance() != null;

  @override
  Future<double?> getDistance() async {
    final received = _distanceReceivedAt;
    final distance = _lastSensorData['distance'];
    final age = _lastSensorData['distance_age_ms'];
    if (!isConnected ||
        received == null ||
        _lastSensorData['distance_valid'] != true ||
        distance is! num ||
        !distance.isFinite ||
        distance < 0 ||
        age is! num ||
        !age.isFinite ||
        age < 0 ||
        age + _now().difference(received).inMilliseconds > 500) {
      return null;
    }
    return distance.toDouble();
  }

  void dispose() {
    _cancelPending('Service disposed');
    _statuses.close();
    _responses.close();
    _sensors.close();
    _faults.close();
  }
}

class _PendingCommand {
  final result = Completer<bool>();
  Timer? timer;
}
