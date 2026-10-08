import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'robot_client.dart';
import 'device_discovery.dart';
import 'robot_connection.dart';
import 'robot_protocol.dart';
export 'robot_client.dart';

class RobotService implements RobotClient, RobotConnection {
  static final RobotService _instance = RobotService._internal();
  factory RobotService() => _instance;
  RobotService._internal() {
    _protocol = RobotProtocol(
      write: (bytes) {
        final characteristic = _commandCharacteristic;
        if (characteristic == null) throw StateError('Robot is disconnected');
        // FBP serializes native writes. Retain their futures after protocol
        // cancellation so no queued write can cross a reconnect boundary.
        late Future<void> pending;
        pending = characteristic
            .write(bytes, withoutResponse: false, timeout: 5)
            .whenComplete(() => _nativeWrites.remove(pending));
        _nativeWrites.add(pending);
        return pending;
      },
      onStopUnconfirmed: _closeConnection,
    );
  }

  static const String SERVICE_UUID = '12345678-1234-1234-1234-123456789abc';
  static const String COMMAND_CHAR_UUID =
      '12345678-1234-1234-1234-123456789abd';
  static const String SENSOR_CHAR_UUID = '12345678-1234-1234-1234-123456789abe';

  late final RobotProtocol _protocol;
  late final DeviceDiscovery<ScanResult> _discovery = DeviceDiscovery(
    prepare: () async {
      if (!await requestPermissions()) {
        throw StateError(
          'Bluetooth permissions not granted. Check app permissions in Android settings.',
        );
      }
      if (!await FlutterBluePlus.isSupported)
        throw StateError('Bluetooth is unavailable.');
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        throw StateError('Turn on Bluetooth before scanning.');
      }
    },
    start: () => FlutterBluePlus.startScan(
      withServices: [Guid(SERVICE_UUID)],
      timeout: const Duration(seconds: 10),
    ),
    stop: FlutterBluePlus.stopScan,
    results: () => FlutterBluePlus.onScanResults,
  );
  BluetoothDevice? _bluetoothDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceSubscription;
  final Set<Future<void>> _nativeWrites = {};
  Future<void>? _disconnectFuture;
  Future<void>? _closeFuture;
  bool _connecting = false;

  @override
  Stream<ConnectionStatus> get connectionStatus => _protocol.connectionStatus;
  @override
  Stream<Map<String, dynamic>> get sensorData => _protocol.sensorData;
  @override
  Stream<String> get commandResponse => _protocol.commandResponse;
  @override
  Stream<String> get faults => _protocol.faults;
  @override
  ConnectionStatus get status => _protocol.status;
  @override
  bool get isConnected => _protocol.isConnected;
  @override
  BluetoothDevice? get connectedBluetoothDevice => _bluetoothDevice;
  Map<String, dynamic> get lastSensorData => _protocol.lastSensorData;

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  @override
  Stream<List<ScanResult>> scanForDevices() => _discovery.scan();

  @override
  Future<void> stopScan() => _discovery.stopScanning();

  @override
  Future<bool> connectBluetooth(BluetoothDevice device) async {
    if (_connecting) return false;
    _connecting = true;
    try {
      await disconnect();
      // Never reconnect while a cancelled native write could still be queued.
      // If native I/O remains stuck, fail setup instead of reopening that link.
      await Future.wait(
        _nativeWrites.toList().map((write) => write.catchError((Object _) {})),
      ).timeout(const Duration(seconds: 15));
      _protocol.setStatus(ConnectionStatus.connecting);
      _bluetoothDevice = device;
      await stopScan();
      await device.connect(timeout: const Duration(seconds: 10));
      _deviceSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _protocol.setStatus(ConnectionStatus.disconnected);
          _commandCharacteristic = null;
          unawaited(_notificationSubscription?.cancel());
          _notificationSubscription = null;
        }
      });
      final services = await device.discoverServices();
      BluetoothCharacteristic? sensor;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() != SERVICE_UUID) continue;
        for (final characteristic in service.characteristics) {
          final uuid = characteristic.uuid.toString().toLowerCase();
          if (uuid == COMMAND_CHAR_UUID)
            _commandCharacteristic = characteristic;
          if (uuid == SENSOR_CHAR_UUID) sensor = characteristic;
        }
      }
      if (_commandCharacteristic == null || sensor == null) {
        throw StateError(
          'Robot command and notification characteristics are required',
        );
      }
      // onValueReceived does not replay a response from a previous connection.
      _notificationSubscription = sensor.onValueReceived.listen(
        _protocol.receive,
      );
      await sensor.setNotifyValue(true);
      if (!device.isConnected)
        throw StateError('Robot disconnected during setup');
      _protocol.setStatus(ConnectionStatus.connected);
      // Verify the protocol and establish a stopped state before allowing use.
      if (!await stopRobot())
        throw StateError('Robot did not acknowledge STOP');
      return true;
    } catch (_) {
      try {
        await disconnect();
      } catch (_) {
        // Keep the device reference for a later disconnect retry.
      }
      _protocol.setStatus(ConnectionStatus.error);
      return false;
    } finally {
      _connecting = false;
    }
  }

  @override
  Future<void> disconnect() => _disconnectFuture ??= () async {
    if (isConnected) await stopRobot();
    await _closeConnection();
  }().whenComplete(() => _disconnectFuture = null);

  Future<void> _closeConnection() => _closeFuture ??= () async {
    _protocol.setStatus(ConnectionStatus.disconnected);
    _commandCharacteristic = null;
    await _notificationSubscription?.cancel();
    await _deviceSubscription?.cancel();
    _notificationSubscription = null;
    _deviceSubscription = null;
    final device = _bluetoothDevice;
    if (device != null) {
      // Bypass the native write mutex: a lost STOP response must still trigger
      // the firmware's disconnect fail-safe, even if an earlier write is stuck.
      await device.disconnect(queue: false, timeout: 5);
    }
    _bluetoothDevice = null;
  }().whenComplete(() => _closeFuture = null);

  Future<bool> sendCommand(String command) => _protocol.sendCommand(command);
  Future<bool> sendMovementCommand(String direction, {double value = 100}) =>
      _protocol.sendMovementCommand(direction, value: value);
  @override
  Future<bool> moveForward(double distance) => _protocol.moveForward(distance);
  @override
  Future<bool> moveBackward(double distance) =>
      _protocol.moveBackward(distance);
  @override
  Future<bool> turnLeft(double angle) => _protocol.turnLeft(angle);
  @override
  Future<bool> turnRight(double angle) => _protocol.turnRight(angle);
  @override
  Future<bool> stopRobot() => _protocol.stopRobot();
  @override
  Future<bool> autoNavigate() => _protocol.autoNavigate();
  Future<bool> requestSensorData() => _protocol.requestSensorData();
  @override
  Future<double?> getDistance() => _protocol.getDistance();

  Future<void> dispose() async {
    await stopScan();
    await disconnect();
    _protocol.dispose();
  }
}
