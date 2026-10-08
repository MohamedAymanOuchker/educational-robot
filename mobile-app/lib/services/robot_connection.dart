import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'robot_client.dart';

/// Bluetooth connection controls, separate from commands that move the robot.
abstract class RobotConnection {
  ConnectionStatus get status;
  Stream<ConnectionStatus> get connectionStatus;
  BluetoothDevice? get connectedBluetoothDevice;
  Stream<List<ScanResult>> scanForDevices();
  Future<void> stopScan();
  Future<bool> connectBluetooth(BluetoothDevice device);
  Future<void> disconnect();
}
