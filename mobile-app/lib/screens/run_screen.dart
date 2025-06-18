import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/robot_service.dart';

class RunScreen extends StatefulWidget {
  final String generatedCode;
  const RunScreen({Key? key, required this.generatedCode}) : super(key: key);

  @override
  _RunScreenState createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with TickerProviderStateMixin {
  final RobotService _robotService = RobotService();

  bool isRunning = false;
  bool isPaused = false;
  double progress = 0.0;
  String currentStatus = 'Ready to Run!';
  List<String> programLogs = [];
  List<String> commands = [];
  int currentCommandIndex = 0;
  late AnimationController _robotController;

  @override
  void initState() {
    super.initState();
    _robotController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    // Parse the generated code into executable commands
    _parseCommands();

    // Listen to robot service responses
    _robotService.commandResponse.listen((response) {
      _addLog('📡 Robot: $response');
    });

    // Listen to sensor data during execution
    _robotService.sensorData.listen((data) {
      if (isRunning && data.containsKey('distance')) {
        double distance = data['distance']?.toDouble() ?? 0.0;
        if (distance < 10) {
          _addLog(
              '⚠️ Obstacle detected! Distance: ${distance.toStringAsFixed(1)}cm');
        }
      }
    });
  }

  @override
  void dispose() {
    _robotController.dispose();
    super.dispose();
  }

  void _parseCommands() {
    commands.clear();

    // Split the generated code and extract meaningful commands
    List<String> codeLines = widget.generatedCode
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    for (String line in codeLines) {
      String trimmed = line.trim();

      // Extract command from different patterns
      if (trimmed.contains('sendCommand(')) {
        // Extract command from sendCommand("COMMAND") format
        RegExp commandRegex = RegExp(r'sendCommand\("([^"]+)"\)');
        Match? match = commandRegex.firstMatch(trimmed);
        if (match != null) {
          commands.add(match.group(1)!);
        }
      } else if (trimmed.contains('Future.delayed')) {
        // Extract wait time
        RegExp delayRegex = RegExp(r'Duration\(milliseconds:\s*(\d+)\)');
        Match? match = delayRegex.firstMatch(trimmed);
        if (match != null) {
          int milliseconds = int.parse(match.group(1)!);
          commands.add('WAIT:$milliseconds');
        }
      } else if (trimmed.contains('getDistance()')) {
        commands.add('GET_DISTANCE');
      } else if (trimmed.startsWith('await')) {
        // Handle direct command lines
        commands.add(trimmed.replaceAll('await ', '').replaceAll(';', ''));
      }
    }

    if (commands.isEmpty) {
      // If no commands parsed, try to parse as simple format
      for (String line in codeLines) {
        String trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('//')) {
          commands.add(trimmed);
        }
      }
    }

    _addLog('📋 Loaded ${commands.length} commands');
    for (int i = 0; i < commands.length; i++) {
      _addLog('${i + 1}. ${commands[i]}');
    }
  }

  void startProgram() async {
    if (!_robotService.isConnected) {
      _addLog('❌ Error: Not connected to robot!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Please connect to your robot first!'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (commands.isEmpty) {
      _addLog('❌ No commands to execute!');
      return;
    }

    setState(() {
      isRunning = true;
      isPaused = false;
      progress = 0.0;
      currentCommandIndex = 0;
      currentStatus = 'Executing program on robot...';
    });

    programLogs.clear();
    _addLog('🚀 Starting program execution on robot!');
    _robotController.repeat();

    await _executeCommands();
  }

  void pauseProgram() {
    setState(() {
      isPaused = !isPaused;
      currentStatus = isPaused ? 'Program paused' : 'Resuming execution...';
    });

    if (isPaused) {
      _addLog('⏸️ Program paused by user');
      _robotService.stopRobot(); // Stop current movement
    } else {
      _addLog('▶️ Program resumed');
    }
  }

  void stopProgram() {
    setState(() {
      isRunning = false;
      isPaused = false;
      currentStatus = 'Program stopped';
    });

    _addLog('🛑 Program stopped by user');
    _robotController.stop();
    _robotService.stopRobot(); // Send stop command to robot
  }

  Future<void> _executeCommands() async {
    try {
      for (int i = 0; i < commands.length && isRunning; i++) {
        if (isPaused) {
          // Wait while paused
          while (isPaused && isRunning) {
            await Future.delayed(Duration(milliseconds: 100));
          }
          if (!isRunning) break;
        }

        setState(() {
          currentCommandIndex = i;
          progress = i / commands.length;
          currentStatus = 'Executing command ${i + 1} of ${commands.length}';
        });

        String command = commands[i];
        bool success = await _executeCommand(command);

        if (!success) {
          _addLog('❌ Command failed: $command');
          setState(() {
            currentStatus = 'Execution failed at command ${i + 1}';
          });
          break;
        }

        // Small delay between commands
        await Future.delayed(Duration(milliseconds: 200));
      }

      if (isRunning) {
        setState(() {
          isRunning = false;
          progress = 1.0;
          currentStatus = 'Program completed successfully! 🎉';
        });
        _addLog('✨ Program execution completed successfully!');
      }
    } catch (e) {
      setState(() {
        isRunning = false;
        currentStatus = 'Execution error occurred';
      });
      _addLog('❌ Execution error: $e');
    } finally {
      _robotController.stop();
    }
  }

  Future<bool> _executeCommand(String command) async {
    try {
      // Remove 'await' and ';' if present
      command = command.replaceAll('await ', '').replaceAll(';', '').trim();

      if (command.startsWith('WAIT:')) {
        int milliseconds = int.parse(command.split(':')[1]);
        _addLog('⏳ Waiting ${milliseconds}ms...');
        await Future.delayed(Duration(milliseconds: milliseconds));
        return true;
      } else if (command == 'GET_DISTANCE' || command.contains('getDistance')) {
        _addLog('📏 Getting distance reading...');
        double? distance = await _robotService.getDistance();
        if (distance != null) {
          _addLog('📏 Distance: ${distance.toStringAsFixed(1)}cm');
        }
        return true;
      } else if (command.startsWith('sendCommand("F') ||
          command.startsWith('F')) {
        // Forward movement
        String cleanCommand =
            command.replaceAll('sendCommand("', '').replaceAll('")', '');
        String distanceStr = cleanCommand.substring(1);
        double distance = double.tryParse(distanceStr) ?? 100;
        _addLog('🤖 Moving forward ${distance.toInt()}cm...');
        return await _robotService.moveForward(distance);
      } else if (command.startsWith('sendCommand("B') ||
          command.startsWith('B')) {
        // Backward movement
        String cleanCommand =
            command.replaceAll('sendCommand("', '').replaceAll('")', '');
        String distanceStr = cleanCommand.substring(1);
        double distance = double.tryParse(distanceStr) ?? 100;
        _addLog('🤖 Moving backward ${distance.toInt()}cm...');
        return await _robotService.moveBackward(distance);
      } else if (command.startsWith('sendCommand("L') ||
          command.startsWith('L')) {
        // Left turn
        String cleanCommand =
            command.replaceAll('sendCommand("', '').replaceAll('")', '');
        String angleStr = cleanCommand.substring(1);
        double angle = double.tryParse(angleStr) ?? 90;
        _addLog('↪️ Turning left ${angle.toInt()}°...');
        return await _robotService.turnLeft(angle);
      } else if (command.startsWith('sendCommand("R') ||
          command.startsWith('R')) {
        // Right turn
        String cleanCommand =
            command.replaceAll('sendCommand("', '').replaceAll('")', '');
        String angleStr = cleanCommand.substring(1);
        double angle = double.tryParse(angleStr) ?? 90;
        _addLog('↩️ Turning right ${angle.toInt()}°...');
        return await _robotService.turnRight(angle);
      } else if (command.contains('STOP') || command.contains('stopRobot')) {
        _addLog('🛑 Stopping robot...');
        return await _robotService.stopRobot();
      } else if (command.contains('AUTO_NAV') ||
          command.contains('autoNavigate')) {
        _addLog('🎯 Starting autonomous navigation...');
        return await _robotService.autoNavigate();
      } else if (command.contains('Future.delayed')) {
        // Extract delay time
        RegExp delayRegex = RegExp(r'Duration\(milliseconds:\s*(\d+)\)');
        Match? match = delayRegex.firstMatch(command);
        if (match != null) {
          int milliseconds = int.parse(match.group(1)!);
          _addLog('⏳ Waiting ${milliseconds}ms...');
          await Future.delayed(Duration(milliseconds: milliseconds));
          return true;
        }
      } else {
        // Generic command - try to send as-is
        _addLog('⚡ Executing: $command');
        return await _robotService.sendCommand(command);
      }
    } catch (e) {
      _addLog('❌ Error executing command "$command": $e');
      return false;
    }
    return false;
  }

  void _addLog(String message) {
    setState(() {
      programLogs.add(message);
    });
    print('RunScreen: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Robot Execution",
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            tooltip: 'Copy Generated Code',
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: widget.generatedCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Code copied to clipboard'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Robot Status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _robotController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _robotController.value * 0.5,
                            child: Icon(
                              Icons.smart_toy,
                              size: 48,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Robot Program Execution',
                              style: GoogleFonts.comicNeue(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _robotService.isConnected
                                  ? 'Connected & Ready'
                                  : 'Not Connected',
                              style: GoogleFonts.comicNeue(
                                fontSize: 16,
                                color: _robotService.isConnected
                                    ? Colors.green[200]
                                    : Colors.red[200],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card with Progress
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isRunning
                                    ? Icons.play_circle_filled
                                    : Icons.play_circle_outline,
                                color: isRunning ? Colors.blue : Colors.green,
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentStatus,
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isRunning ? Colors.blue : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isRunning || progress > 0) ...[
                            SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 20,
                                backgroundColor: Colors.blue[100],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(progress * 100).toInt()}% Complete',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  'Command ${currentCommandIndex + 1} of ${commands.length}',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        onPressed: !isRunning && _robotService.isConnected
                            ? startProgram
                            : null,
                        icon: Icons.play_arrow_rounded,
                        label: 'Start',
                        color: Colors.green,
                      ),
                      SizedBox(width: 12),
                      _buildControlButton(
                        onPressed: isRunning ? pauseProgram : null,
                        icon: isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        label: isPaused ? 'Resume' : 'Pause',
                        color: Colors.orange,
                      ),
                      SizedBox(width: 12),
                      _buildControlButton(
                        onPressed: isRunning ? stopProgram : null,
                        icon: Icons.stop_rounded,
                        label: 'Stop',
                        color: Colors.red,
                      ),
                    ],
                  ),

                  if (!_robotService.isConnected) ...[
                    SizedBox(height: 16),
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Connect to your robot in the Connect tab to run programs!',
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
                  ],

                  SizedBox(height: 24),

                  // Generated Code Display Card
                  Card(
                    child: ExpansionTile(
                      title: Text(
                        "View Generated Code",
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          color: Colors.grey[100],
                          width: double.infinity,
                          child: SelectableText(
                            widget.generatedCode,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Execution Log
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.terminal, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text(
                                'Execution Log',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              if (programLogs.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      programLogs.clear();
                                    });
                                  },
                                  icon: Icon(Icons.clear_all, size: 16),
                                  label: Text('Clear'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Divider(height: 1),
                        Container(
                          height: 250,
                          child: programLogs.isEmpty
                              ? Center(
                                  child: Text(
                                    'Click Start to execute your program! 🚀',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: programLogs.length,
                                  itemBuilder: (context, index) {
                                    bool isCurrentCommand = isRunning &&
                                        index == programLogs.length - 1;

                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCurrentCommand
                                            ? Colors.blue[50]
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: isCurrentCommand
                                            ? Border.all(
                                                color: Colors.blue[200]!)
                                            : null,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isCurrentCommand
                                                  ? Colors.blue[100]
                                                  : Colors.indigo[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: GoogleFonts.comicNeue(
                                                  color: isCurrentCommand
                                                      ? Colors.blue
                                                      : Colors.indigo,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              programLogs[index],
                                              style: GoogleFonts.comicNeue(
                                                fontSize: 14,
                                                fontWeight: isCurrentCommand
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: GoogleFonts.comicNeue(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
