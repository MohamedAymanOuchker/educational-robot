import 'dart:async';
import 'package:flutter/material.dart';

import '../services/program_executor.dart';
import '../services/robot_service.dart';
import '../widgets/block_editor/block_types.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({
    super.key,
    required this.blocks,
    this.robot,
    this.onCompleted,
  });
  final List<Block> blocks;
  final RobotClient? robot;
  final Future<String> Function(ProgramResult result)? onCompleted;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with WidgetsBindingObserver {
  late final RobotClient _robot;
  late final ProgramExecutor _executor;
  late final List<Block> _program;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;
  StreamSubscription<String>? _responseSubscription;
  final List<String> _logs = [];
  bool _running = false;
  bool _stopping = false;
  bool _canLeave = false;
  bool _savingProgress = false;
  String? _practiceMessage;
  double _progress = 0;
  String _status = 'Ready to run';
  ProgramStatus? _resultStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _robot = widget.robot ?? RobotService();
    _executor = ProgramExecutor(_robot);
    // The editor may keep changing after this route opens.
    _program = widget.blocks.map((block) => block.clone()).toList();
    _connectionSubscription = _robot.connectionStatus.listen((_) {
      if (mounted) setState(() {});
    });
    _responseSubscription = _robot.commandResponse.listen(_log);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _running) {
      unawaited(_stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSubscription?.cancel();
    _responseSubscription?.cancel();
    if (_executor.isRunning && !_canLeave) unawaited(_executor.cancel());
    super.dispose();
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _logs.add(message);
      if (_logs.length > 200) _logs.removeAt(0);
    });
  }

  Future<void> _start() async {
    if (_running || _stopping || _savingProgress) return;
    setState(() {
      _running = true;
      _progress = 0;
      _resultStatus = null;
      _status = 'Starting program';
      _logs.clear();
      _practiceMessage = null;
    });
    final result = await _executor.run(
      _program,
      onProgress: (done, total, message) {
        if (!mounted) return;
        setState(() {
          _progress = done / total;
          _status = message;
        });
        _log(message);
      },
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _resultStatus = result.status;
      _status = result.message;
      if (result.status == ProgramStatus.completed) _progress = 1;
    });
    _log(result.message);
    if (result.status == ProgramStatus.completed &&
        widget.onCompleted != null) {
      setState(() => _savingProgress = true);
      String message;
      try {
        message = await widget.onCompleted!(result);
      } catch (_) {
        message =
            'Program ran, but practice progress could not be saved. Run again to retry.';
      }
      if (!mounted) return;
      setState(() {
        _savingProgress = false;
        _practiceMessage = message;
      });
    }
  }

  Future<void> _stop() async {
    if (_stopping) return;
    setState(() {
      _stopping = true;
      _status = 'Stopping robot...';
    });
    final stopped = await _executor.cancel();
    if (!mounted) return;
    setState(() {
      _stopping = false;
      if (!_running) {
        _resultStatus = ProgramStatus.stopped;
        _status = stopped ? 'Robot stopped.' : 'Robot STOP was not confirmed.';
      }
    });
  }

  Future<void> _leave() async {
    if (_stopping) return;
    if (_running) await _stop();
    if (!mounted) return;
    setState(() => _canLeave = true);
    // Rebuild PopScope before the actual route pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final failure = _resultStatus == ProgramStatus.failed;
    return PopScope<Object?>(
      canPop: _canLeave || (!_running && !_stopping),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Robot Execution')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _robot.isConnected ? 'Robot connected' : 'Robot disconnected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                key: const Key('execution-status'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: failure ? Colors.red : null,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        !_running &&
                            !_stopping &&
                            !_savingProgress &&
                            _robot.isConnected
                        ? _start
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                  ElevatedButton.icon(
                    onPressed: !_stopping && _robot.isConnected ? _stop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_savingProgress) const Text('Saving practice progress...'),
              if (_practiceMessage != null)
                Text(_practiceMessage!, key: const Key('practice-result')),
              const Text(
                'Leaving this screen or putting the app in the background stops the program. Auto Navigate runs for 3 seconds.',
              ),
              const Divider(height: 32),
              Text(
                'Execution log',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(_logs[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
