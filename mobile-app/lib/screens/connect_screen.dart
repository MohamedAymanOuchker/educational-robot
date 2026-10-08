import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/robot_connection.dart';
import '../services/robot_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, this.connection});
  final RobotConnection? connection;
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late final RobotConnection _robot = widget.connection ?? RobotService();
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  List<ScanResult> _devices = [];
  late ConnectionStatus _status;
  bool _scanning = false;
  bool _busy = false;
  bool _hasScanned = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = _robot.status;
    _statusSubscription = _robot.connectionStatus.listen((status) {
      if (mounted) setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    // Cancelling the discovery stream owns native scan cleanup, including a
    // permission request which completes after this screen was removed.
    unawaited(_scanSubscription?.cancel());
    unawaited(_statusSubscription?.cancel());
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning || _busy || _status == ConnectionStatus.connected) return;
    setState(() {
      _scanning = true;
      _hasScanned = true;
      _devices = [];
      _error = null;
    });
    await _scanSubscription?.cancel();
    if (!mounted) return;
    _scanSubscription = _robot.scanForDevices().listen(
      (devices) {
        if (mounted) setState(() => _devices = devices);
      },
      onError: (Object error) {
        if (mounted)
          setState(() {
            _scanning = false;
            _error = '$error';
          });
      },
      onDone: () {
        if (mounted) setState(() => _scanning = false);
      },
    );
  }

  Future<void> _stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _stopScan();
      if (!mounted) return;
      final success = await _robot.connectBluetooth(device);
      if (mounted && !success) {
        setState(
          () => _error =
              'Connection failed. Check the robot power and matching firmware, then try again.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Connection failed: $error');
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
          _status = _robot.status;
        });
    }
  }

  Future<void> _disconnect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _robot.disconnect();
    } catch (error) {
      if (mounted) setState(() => _error = 'Disconnect failed: $error');
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
          _status = _robot.status;
        });
    }
  }

  String get _statusText => switch (_status) {
    ConnectionStatus.connected => 'Robot connected',
    ConnectionStatus.connecting => 'Connecting to robot...',
    ConnectionStatus.disconnected => 'Robot disconnected',
    ConnectionStatus.error => 'Connection failed',
  };

  @override
  Widget build(BuildContext context) {
    final connected = _status == ConnectionStatus.connected;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Connect with Bluetooth',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Power on the robot and enable Bluetooth on your phone. Scan for E-Bug ESP32, then tap Connect.',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusText,
                  key: const Key('connection-status'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (connected) ...[
                  Text(
                    _robot.connectedBluetoothDevice?.platformName.isNotEmpty ==
                            true
                        ? _robot.connectedBluetoothDevice!.platformName
                        : 'E-Bug ESP32',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _disconnect,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              key: const Key('connection-error'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: connected || _busy || _scanning ? null : _scan,
              icon: const Icon(Icons.search),
              label: const Text('Scan for robots'),
            ),
            if (_scanning)
              OutlinedButton(
                onPressed: _stopScan,
                child: const Text('Stop scan'),
              ),
          ],
        ),
        if (_scanning)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LinearProgressIndicator(),
          ),
        if (_hasScanned && !_scanning && _devices.isEmpty && _error == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No matching robots found. Check power, Bluetooth permissions and the firmware, then scan again.',
            ),
          ),
        for (final result in _devices)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    result.advertisementData.advName.isNotEmpty
                        ? result.advertisementData.advName
                        : (result.device.platformName.isNotEmpty
                              ? result.device.platformName
                              : 'E-Bug robot'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${result.device.remoteId.str} · ${result.rssi} dBm'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: connected || _busy
                          ? null
                          : () => _connect(result.device),
                      child: const Text('Connect'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'The current app uses Bluetooth Low Energy. A scan lists devices advertising this robot service; connection checks the firmware before use.',
        ),
      ],
    );
  }
}
