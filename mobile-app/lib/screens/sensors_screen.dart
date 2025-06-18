import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/robot_service.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({Key? key}) : super(key: key);

  @override
  _SensorsScreenState createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final RobotService _robotService = RobotService();

  double currentDistance = 0.0;
  double batteryLevel = 100.0;
  double temperature = 25.0;
  double heading = 0.0;
  bool isMonitoring = false;
  bool isConnected = false;
  String connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    // Listen to robot service streams
    _robotService.connectionStatus.listen((status) {
      setState(() {
        isConnected = status == ConnectionStatus.connected;
        connectionStatus = _getStatusText(status);
      });
    });

    _robotService.sensorData.listen((data) {
      setState(() {
        currentDistance = data['distance']?.toDouble() ?? currentDistance;
        batteryLevel = data['battery']?.toDouble() ?? batteryLevel;
        temperature = data['temperature']?.toDouble() ?? temperature;
        heading = data['heading']?.toDouble() ?? heading;
      });
    });

    // Check initial connection status
    isConnected = _robotService.isConnected;
    connectionStatus = _getStatusText(_robotService.status);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }

  void startMonitoring() {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please connect to your robot first!'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isMonitoring = true;
    });

    // Request initial sensor data
    _robotService.requestSensorData();
  }

  void stopMonitoring() {
    setState(() {
      isMonitoring = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with connection status
          Row(
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 0.2,
                    child: Icon(
                      Icons.sensors,
                      size: 32,
                      color: isConnected ? Colors.indigo : Colors.grey,
                    ),
                  );
                },
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Robot Sensors',
                      style: GoogleFonts.comicNeue(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      connectionStatus,
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: isConnected
                    ? (isMonitoring ? stopMonitoring : startMonitoring)
                    : null,
                icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
                label: Text(
                  isMonitoring ? 'Stop' : 'Start',
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMonitoring ? Colors.red : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          if (!isConnected)
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Connect to your robot in the Connect tab to view real sensor data!',
                        style: GoogleFonts.comicNeue(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Distance Sensor Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildSensorIcon(
                        icon: Icons.straighten,
                        color: Colors.blue,
                        isActive: isConnected,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Distance Sensor',
                        style: GoogleFonts.comicNeue(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 20,
                            ),
                          ),
                        ),
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getDistanceColor(currentDistance)
                                .withOpacity(0.1),
                          ),
                        ),
                        Text(
                          '${currentDistance.toStringAsFixed(1)}\ncm',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.comicNeue(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _getDistanceColor(currentDistance),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildDistanceIndicator(currentDistance),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Battery Level Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildSensorIcon(
                        icon: _getBatteryIcon(batteryLevel),
                        color: _getBatteryColor(batteryLevel),
                        isActive: isConnected,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Battery Level',
                        style: GoogleFonts.comicNeue(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: batteryLevel / 100,
                      minHeight: 30,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getBatteryColor(batteryLevel),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${batteryLevel.toStringAsFixed(1)}%',
                      style: GoogleFonts.comicNeue(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getBatteryColor(batteryLevel),
                      ),
                    ),
                  ),
                  if (batteryLevel <= 20)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Battery Low! Please charge soon!',
                              style: GoogleFonts.comicNeue(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Additional sensors if available
          if (temperature > 0) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSensorIcon(
                            icon: Icons.thermostat,
                            color: Colors.orange,
                            isActive: isConnected,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Temperature',
                            style: GoogleFonts.comicNeue(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${temperature.toStringAsFixed(1)}°C',
                            style: GoogleFonts.comicNeue(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSensorIcon(
                            icon: Icons.explore,
                            color: Colors.purple,
                            isActive: isConnected,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Heading',
                            style: GoogleFonts.comicNeue(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${heading.toStringAsFixed(0)}°',
                            style: GoogleFonts.comicNeue(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensorIcon(
      {required IconData icon, required Color color, bool isActive = true}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isActive ? color : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: isActive ? color : Colors.grey, size: 24),
    );
  }

  Widget _buildDistanceIndicator(double distance) {
    String message = '';
    Color color = Colors.green;
    IconData icon = Icons.check_circle;

    if (distance < 10) {
      message = 'Very Close!';
      color = Colors.red;
      icon = Icons.warning_rounded;
    } else if (distance < 20) {
      message = 'Too Close!';
      color = Colors.red;
      icon = Icons.warning_rounded;
    } else if (distance < 50) {
      message = 'Getting Close!';
      color = Colors.orange;
      icon = Icons.info_rounded;
    } else {
      message = 'All Clear!';
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(
            message,
            style: GoogleFonts.comicNeue(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDistanceColor(double distance) {
    if (distance < 20) return Colors.red;
    if (distance < 50) return Colors.orange;
    return Colors.blue;
  }

  Color _getBatteryColor(double level) {
    if (level <= 20) return Colors.red;
    if (level <= 50) return Colors.orange;
    return Colors.green;
  }

  IconData _getBatteryIcon(double level) {
    if (level <= 20) return Icons.battery_0_bar;
    if (level <= 40) return Icons.battery_2_bar;
    if (level <= 60) return Icons.battery_4_bar;
    if (level <= 80) return Icons.battery_5_bar;
    return Icons.battery_full;
  }
}
