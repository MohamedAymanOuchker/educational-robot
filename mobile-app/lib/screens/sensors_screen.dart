import 'dart:async';
import 'package:flutter/material.dart';
import '../services/robot_service.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key, this.robot, this.now});
  final RobotClient? robot;
  final DateTime Function()? now;
  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  late final RobotClient _robot = widget.robot ?? RobotService();
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _sensorSubscription;
  Timer? _timer;
  Map<String, dynamic> _sample = {};
  DateTime? _received;
  late bool _connected;

  @override
  void initState() {
    super.initState();
    _connected = _robot.isConnected;
    _statusSubscription = _robot.connectionStatus.listen((status) {
      if (!mounted) return;
      setState(() {
        _connected = status == ConnectionStatus.connected;
        _sample = {};
        _received = null;
      });
    });
    _sensorSubscription = _robot.sensorData.listen((sample) {
      if (!mounted || !_connected) return;
      setState(() {
        _sample = Map.of(sample);
        _received = _now();
      });
    });
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && _received != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_statusSubscription?.cancel());
    unawaited(_sensorSubscription?.cancel());
    super.dispose();
  }

  int? get _age =>
      _received == null ? null : _now().difference(_received!).inMilliseconds;
  bool get _fresh => _connected && _age != null && _age! >= 0 && _age! <= 500;
  double? _number(String key) {
    final value = _sample[key];
    return _fresh && value is num && value.isFinite ? value.toDouble() : null;
  }

  double? get _distance {
    final value = _number('distance');
    final age = _number('distance_age_ms');
    return _sample['distance_valid'] == true &&
            value != null &&
            value >= 0 &&
            age != null &&
            age >= 0 &&
            age + _age! <= 500
        ? value
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final battery = _number('battery');
    final validBattery = battery != null && battery >= 0 && battery <= 100
        ? battery
        : null;
    final status = !_connected
        ? 'Robot disconnected'
        : _received == null
        ? 'Waiting for telemetry'
        : !_fresh
        ? 'Readings are stale'
        : 'Receiving live telemetry';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Robot Sensors', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(status, key: const Key('telemetry-status')),
        const SizedBox(height: 8),
        const Text(
          'Readings arrive automatically while connected. Use Stop on Robot Execution to cancel movement.',
        ),
        _reading(
          'Front distance',
          'distance-reading',
          _distance,
          'cm',
          'One forward-facing reading; it cannot check the rear, sides or floor edges.',
        ),
        _reading(
          'Battery estimate',
          'battery-reading',
          validBattery,
          '%',
          'Voltage-based estimate. Verify the battery divider and pack voltage before relying on it.',
        ),
        _reading(
          'IMU temperature',
          'temperature-reading',
          _number('temperature'),
          '°C',
          'Temperature reported by the IMU chip, not a calibrated room thermometer.',
        ),
        _reading(
          'Relative heading',
          'heading-reading',
          _number('heading'),
          '°',
          'Gyro estimate relative to startup. It can drift and is not a compass.',
        ),
        if (_connected && _fresh && _distance == null)
          const Text(
            'Front distance is unavailable or invalid. Do not treat a missing reading as a clear path.',
          ),
      ],
    );
  }

  Widget _reading(
    String title,
    String key,
    double? value,
    String unit,
    String description,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            value == null ? 'Unavailable' : '${value.toStringAsFixed(1)} $unit',
            key: Key(key),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(description),
        ],
      ),
    ),
  );
}
