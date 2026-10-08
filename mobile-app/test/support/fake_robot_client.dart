import 'dart:async';

import 'package:robocode/services/robot_client.dart';

class FakeRobotClient implements RobotClient {
  final calls = <String>[];
  final statuses = StreamController<ConnectionStatus>.broadcast();
  final responses = StreamController<String>.broadcast();
  final sensors = StreamController<Map<String, dynamic>>.broadcast();
  final faultEvents = StreamController<String>.broadcast();
  Future<bool> Function(String)? onCommand;
  double? distance = 10;
  bool connected = true;
  @override
  bool get isConnected => connected;
  @override
  Stream<ConnectionStatus> get connectionStatus => statuses.stream;
  @override
  Stream<String> get commandResponse => responses.stream;
  @override
  Stream<Map<String, dynamic>> get sensorData => sensors.stream;
  @override
  Stream<String> get faults => faultEvents.stream;
  Future<bool> command(String value) {
    calls.add(value);
    return onCommand?.call(value) ?? Future.value(true);
  }

  @override
  Future<bool> moveForward(double distance) => command('F${distance.toInt()}');
  @override
  Future<bool> moveBackward(double distance) => command('B${distance.toInt()}');
  @override
  Future<bool> turnLeft(double angle) => command('L${angle.toInt()}');
  @override
  Future<bool> turnRight(double angle) => command('R${angle.toInt()}');
  @override
  Future<bool> stopRobot() => command('STOP');
  @override
  Future<bool> autoNavigate() => command('AUTO_NAV');
  @override
  Future<double?> getDistance() async => distance;

  void disconnect() {
    connected = false;
    statuses.add(ConnectionStatus.disconnected);
  }

  Future<void> dispose() async {
    await statuses.close();
    await responses.close();
    await sensors.close();
    await faultEvents.close();
  }
}
