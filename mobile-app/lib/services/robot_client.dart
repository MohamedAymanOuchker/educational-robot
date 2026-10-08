enum ConnectionStatus { disconnected, connecting, connected, error }

/// Commands complete only when the robot acknowledges completion, not on write.
abstract class RobotClient {
  bool get isConnected;
  Stream<ConnectionStatus> get connectionStatus;
  Stream<String> get commandResponse;
  Stream<Map<String, dynamic>> get sensorData;
  Stream<String> get faults;
  Future<bool> moveForward(double distance);
  Future<bool> moveBackward(double distance);
  Future<bool> turnLeft(double angle);
  Future<bool> turnRight(double angle);
  Future<bool> stopRobot();
  Future<bool> autoNavigate();
  Future<double?> getDistance();
}
