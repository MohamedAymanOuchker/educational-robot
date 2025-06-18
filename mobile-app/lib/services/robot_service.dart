import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConnectionType { bluetooth, wifi }

enum ConnectionStatus { disconnected, connecting, connected, error }

class RobotService {
  static final RobotService _instance = RobotService._internal();
  factory RobotService() => _instance;
  RobotService._internal();

  // UUIDs for ESP32 communication (you can customize these)
  static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
  static const String COMMAND_CHAR_UUID =
      "12345678-1234-1234-1234-123456789abd";
  static const String SENSOR_CHAR_UUID = "12345678-1234-1234-1234-123456789abe";

  // Connection state
  ConnectionType? _connectionType;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  BluetoothDevice? _bluetoothDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _sensorCharacteristic;
  String? _wifiIp;
  Timer? _sensorTimer;

  // Stream controllers
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final _sensorDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _commandResponseController = StreamController<String>.broadcast();

  // Getters
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get sensorData => _sensorDataController.stream;
  Stream<String> get commandResponse => _commandResponseController.stream;
  ConnectionStatus get status => _status;
  ConnectionType? get connectionType => _connectionType;
  bool get isConnected => _status == ConnectionStatus.connected;
  BluetoothDevice? get connectedBluetoothDevice => _bluetoothDevice;
  String? get connectedWifiIp => _wifiIp;

  // Request permissions for Bluetooth
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Scan for Bluetooth devices
  Stream<List<ScanResult>> scanForDevices() async* {
    try {
      bool permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        throw Exception('Bluetooth permissions not granted');
      }

      // Check if Bluetooth is available and on
      if (await FlutterBluePlus.isAvailable == false) {
        throw Exception('Bluetooth not available');
      }

      if (await FlutterBluePlus.isOn == false) {
        throw Exception('Bluetooth is turned off');
      }

      // Start scanning with timeout
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 10),
        withServices: [], // Can filter by service UUIDs if needed
      );

      yield* FlutterBluePlus.scanResults;
    } catch (e) {
      print('Error scanning for devices: $e');
      yield [];
    }
  }

  // Connect via Bluetooth
  Future<bool> connectBluetooth(BluetoothDevice device) async {
    try {
      _updateStatus(ConnectionStatus.connecting);

      // Connect to device
      await device.connect(timeout: Duration(seconds: 10));

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      BluetoothService? targetService;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          targetService = service;
          break;
        }
      }

      if (targetService == null) {
        throw Exception(
            'Robot service not found. Make sure your ESP32 is running the correct firmware.');
      }

      // Find characteristics
      for (var characteristic in targetService.characteristics) {
        String charUuid = characteristic.uuid.toString().toLowerCase();

        if (charUuid == COMMAND_CHAR_UUID.toLowerCase()) {
          _commandCharacteristic = characteristic;
        } else if (charUuid == SENSOR_CHAR_UUID.toLowerCase()) {
          _sensorCharacteristic = characteristic;
          // Enable notifications for sensor data
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen(_handleSensorData);
        }
      }

      if (_commandCharacteristic == null) {
        throw Exception('Command characteristic not found');
      }

      _bluetoothDevice = device;
      _connectionType = ConnectionType.bluetooth;
      _updateStatus(ConnectionStatus.connected);

      // Start periodic sensor reading if sensor characteristic is available
      if (_sensorCharacteristic != null) {
        _startSensorReading();
      }

      print('Successfully connected to ${device.name}');
      return true;
    } catch (e) {
      print('Bluetooth connection error: $e');
      _updateStatus(ConnectionStatus.error);
      await disconnect();
      return false;
    }
  }

  // Connect via WiFi (basic TCP socket implementation)
  Future<bool> connectWifi(String ip, {int port = 80}) async {
    try {
      _updateStatus(ConnectionStatus.connecting);

      // TODO: Implement TCP socket connection to ESP32
      // This would require additional dependencies like socket_io_client
      // For now, we'll focus on Bluetooth which is more common for robotics

      throw UnimplementedError(
          'WiFi connection not yet implemented. Please use Bluetooth.');
    } catch (e) {
      print('WiFi connection error: $e');
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    try {
      _sensorTimer?.cancel();

      if (_bluetoothDevice != null) {
        await _bluetoothDevice!.disconnect();
      }

      _bluetoothDevice = null;
      _commandCharacteristic = null;
      _sensorCharacteristic = null;
      _wifiIp = null;
      _connectionType = null;
      _updateStatus(ConnectionStatus.disconnected);

      print('Disconnected from robot');
    } catch (e) {
      print('Error during disconnect: $e');
    }
  }

  // Send command to robot
  Future<bool> sendCommand(String command) async {
    if (!isConnected || _commandCharacteristic == null) {
      print('Cannot send command: not connected or no command characteristic');
      return false;
    }

    try {
      // Add newline terminator for ESP32 parsing
      String fullCommand = command + '\n';
      List<int> bytes = utf8.encode(fullCommand);

      await _commandCharacteristic!.write(bytes, withoutResponse: false);
      print('Sent command: $command');

      // Notify listeners
      _commandResponseController.add('Command sent: $command');

      return true;
    } catch (e) {
      print('Error sending command: $e');
      return false;
    }
  }

  // Send movement command with distance/angle
  Future<bool> sendMovementCommand(String direction,
      {double value = 100}) async {
    String command = '$direction:${value.toInt()}';
    return await sendCommand(command);
  }

  // Specific movement commands
  Future<bool> moveForward(double distance) =>
      sendMovementCommand('FORWARD', value: distance);
  Future<bool> moveBackward(double distance) =>
      sendMovementCommand('BACKWARD', value: distance);
  Future<bool> turnLeft(double angle) =>
      sendMovementCommand('LEFT', value: angle);
  Future<bool> turnRight(double angle) =>
      sendMovementCommand('RIGHT', value: angle);
  Future<bool> stopRobot() => sendCommand('STOP');
  Future<bool> autoNavigate() => sendCommand('AUTO_NAV');

  // Request sensor data
  Future<bool> requestSensorData() async {
    return await sendCommand('GET_SENSORS');
  }

  // Get distance reading
  Future<double?> getDistance() async {
    if (await sendCommand('GET_DISTANCE')) {
      // Wait a bit for response and return last known distance
      await Future.delayed(Duration(milliseconds: 100));
      return _lastSensorData['distance'];
    }
    return null;
  }

  // Handle incoming sensor data
  Map<String, dynamic> _lastSensorData = {};

  void _handleSensorData(List<int> data) {
    try {
      String message = utf8.decode(data).trim();
      print('Received sensor data: $message');

      // Parse JSON format: {"distance": 25.5, "battery": 87.2, "heading": 180}
      if (message.startsWith('{') && message.endsWith('}')) {
        Map<String, dynamic> sensorData = json.decode(message);
        _lastSensorData = sensorData;
        _sensorDataController.add(sensorData);
      } else {
        // Parse simple format: "D:25.5,B:87.2,H:180"
        Map<String, dynamic> sensorValues = {};
        message.split(',').forEach((item) {
          var parts = item.split(':');
          if (parts.length == 2) {
            double? value = double.tryParse(parts[1]);
            if (value != null) {
              switch (parts[0].trim()) {
                case 'D':
                  sensorValues['distance'] = value;
                  break;
                case 'B':
                  sensorValues['battery'] = value;
                  break;
                case 'H':
                  sensorValues['heading'] = value;
                  break;
                case 'T':
                  sensorValues['temperature'] = value;
                  break;
              }
            }
          }
        });

        if (sensorValues.isNotEmpty) {
          _lastSensorData = sensorValues;
          _sensorDataController.add(sensorValues);
        }
      }
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  // Start periodic sensor reading
  void _startSensorReading() {
    _sensorTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isConnected) {
        requestSensorData();
      } else {
        timer.cancel();
      }
    });
  }

  // Update connection status and notify listeners
  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _connectionStatusController.add(_status);
  }

  // Get available WiFi networks (placeholder for ESP32 AP mode)
  Future<List<String>> getAvailableWifiNetworks() async {
    // This would typically scan for WiFi networks or get them from ESP32
    return [
      'RoboBot-AP',
      'ESP32-Robot',
      'Arduino-Bot',
    ];
  }

  // Dispose resources
  void dispose() {
    _sensorTimer?.cancel();
    _connectionStatusController.close();
    _sensorDataController.close();
    _commandResponseController.close();
  }

  // Get last known sensor values
  Map<String, dynamic> get lastSensorData => Map.from(_lastSensorData);
}
