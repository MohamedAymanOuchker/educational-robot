import 'dart:async';
import 'dart:collection';

import '../widgets/block_editor/block_types.dart';
import 'robot_client.dart';

enum ProgramStatus { completed, stopped, failed }

class ProgramResult {
  const ProgramResult(
    this.status,
    this.message, {
    this.stopConfirmed = true,
    this.executedTypes = const {},
    this.distanceReactionExecuted = false,
  });
  final ProgramStatus status;
  final String message;
  final bool stopConfirmed;
  final Set<BlockType> executedTypes;
  final bool distanceReactionExecuted;
}

/// Runs a snapshot of a typed block tree. Generated Dart is only a preview.
class ProgramExecutor {
  ProgramExecutor(this.robot, {this.autoDuration = const Duration(seconds: 3)});
  final RobotClient robot;
  final Duration autoDuration;
  bool _running = false;
  bool _cancelled = false;
  Completer<void>? _cancellation;
  Completer<void>? _disconnection;
  Completer<String>? _fault;
  String? _faultMessage;
  Future<bool>? _stopping;
  bool? _stopResult;
  Timer? _waitTimer;
  int _finished = 0;
  int _total = 0;
  final Set<BlockType> _executedTypes = {};
  bool _distanceReactionExecuted = false;
  void Function(int completed, int total, String message)? _onProgress;
  bool get isRunning => _running;

  static String? validationError(List<Block> blocks) {
    if (blocks.isEmpty) return 'Add at least one block.';
    final seen = HashSet<Block>.identity();
    String? visit(Block block) {
      if (!seen.add(block))
        return 'A block appears more than once or contains a cycle.';
      if (seen.length > 100) return 'Use at most 100 blocks.';
      final spec = BlockParameter.forType(block.type);
      if (spec != null && !spec.isValid(block.parameters[spec.key])) {
        return '${block.getDisplayName()}: ${spec.label} must be a whole number from ${spec.minimum} to ${spec.maximum} ${spec.unit}.';
      }
      if (block.type != BlockType.ifDistance && block.children.isNotEmpty) {
        return 'Only If Distance can contain other blocks.';
      }
      for (final child in block.children) {
        final error = visit(child);
        if (error != null) return error;
      }
      return null;
    }

    for (final block in blocks) {
      final error = visit(block);
      if (error != null) return error;
    }
    return null;
  }

  Future<ProgramResult> run(
    List<Block> blocks, {
    void Function(int completed, int total, String message)? onProgress,
  }) async {
    if (_running)
      return const ProgramResult(
        ProgramStatus.failed,
        'A program is already running.',
      );
    final error = validationError(blocks);
    if (error != null) return ProgramResult(ProgramStatus.failed, error);
    if (!robot.isConnected)
      return const ProgramResult(
        ProgramStatus.failed,
        'Robot is not connected.',
      );
    final program = blocks.map((block) => block.clone()).toList()
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    _running = true;
    _cancelled = false;
    _cancellation = Completer<void>();
    _disconnection = Completer<void>();
    _fault = Completer<String>();
    _faultMessage = null;
    _stopping = null;
    _stopResult = null;
    _finished = 0;
    _executedTypes.clear();
    _distanceReactionExecuted = false;
    _total = program.fold(0, (sum, block) => sum + _count(block));
    _onProgress = onProgress;
    final subscription = robot.connectionStatus.listen((status) {
      if (status != ConnectionStatus.connected &&
          !_disconnection!.isCompleted) {
        _disconnection!.complete();
      }
    });
    final faultSubscription = robot.faults.listen((message) {
      _faultMessage = message;
      if (!_fault!.isCompleted) _fault!.complete(message);
    });
    try {
      for (final block in program) {
        await _execute(block);
      }
      _checkActive();
      // Completion also means the robot is in its stopped mode.
      await _require(robot.stopRobot(), 'Final STOP');
      return ProgramResult(
        ProgramStatus.completed,
        'Program completed successfully.',
        executedTypes: Set.unmodifiable(_executedTypes),
        distanceReactionExecuted: _distanceReactionExecuted,
      );
    } on _ProgramCancelled {
      final stopped = await _requestStop();
      return ProgramResult(
        ProgramStatus.stopped,
        stopped
            ? 'Program stopped.'
            : 'Program cancelled; robot STOP was not confirmed.',
        stopConfirmed: stopped,
      );
    } catch (error) {
      final stopped = await _requestStop();
      return ProgramResult(
        ProgramStatus.failed,
        '$error${stopped ? '' : ' Robot STOP was not confirmed.'}',
        stopConfirmed: stopped,
      );
    } finally {
      _waitTimer?.cancel();
      await subscription.cancel();
      await faultSubscription.cancel();
      _running = false;
      _onProgress = null;
    }
  }

  Future<bool> cancel() {
    _cancelled = true;
    if (_cancellation != null && !_cancellation!.isCompleted)
      _cancellation!.complete();
    return _requestStop(retry: true);
  }

  Future<bool> _requestStop({bool retry = false}) {
    if (_stopping != null) return _stopping!;
    if (retry) _stopResult = null;
    // The run's cancellation handler shares the user's STOP outcome. A later
    // explicit Stop press starts a new attempt, including after a failed STOP.
    if (_stopResult != null) return Future.value(_stopResult!);
    return _stopping =
        () async {
              if (!robot.isConnected) return false;
              try {
                return await robot.stopRobot();
              } catch (_) {
                return false;
              }
            }()
            .then((result) {
              _stopResult = result;
              return result;
            })
            .whenComplete(() => _stopping = null);
  }

  void _checkActive() {
    if (_cancelled) throw const _ProgramCancelled();
    if (_faultMessage != null)
      throw StateError('Robot stopped: $_faultMessage');
    if (!robot.isConnected || _disconnection?.isCompleted == true) {
      throw StateError('Robot disconnected.');
    }
  }

  Future<T> _await<T>(Future<T> operation) async {
    final result = await Future.any<T>([
      operation,
      _cancellation!.future.then<T>((_) => throw const _ProgramCancelled()),
      _disconnection!.future.then<T>(
        (_) => throw StateError('Robot disconnected.'),
      ),
      _fault!.future.then<T>(
        (message) => throw StateError('Robot stopped: $message'),
      ),
    ]);
    _checkActive();
    return result;
  }

  Future<void> _require(Future<bool> operation, String label) async {
    if (!await _await(operation))
      throw StateError('$label failed or was cancelled by the robot.');
  }

  Future<void> _wait(Duration duration) async {
    final done = Completer<void>();
    _waitTimer = Timer(duration, done.complete);
    try {
      await _await(done.future);
    } finally {
      _waitTimer?.cancel();
      _waitTimer = null;
    }
  }

  int _count(Block block) =>
      1 + block.children.fold(0, (sum, child) => sum + _count(child));

  Future<void> _execute(Block block, {bool insideCondition = false}) async {
    _checkActive();
    _onProgress?.call(_finished, _total, 'Executing ${block.getDisplayName()}');
    final parameters = block.parameters;
    switch (block.type) {
      case BlockType.moveForward:
        await _require(
          robot.moveForward((parameters['distance'] as num).toDouble()),
          'Move forward',
        );
        break;
      case BlockType.moveBackward:
        await _require(
          robot.moveBackward((parameters['distance'] as num).toDouble()),
          'Move backward',
        );
        break;
      case BlockType.turnLeft:
        await _require(
          robot.turnLeft((parameters['angle'] as num).toDouble()),
          'Turn left',
        );
        break;
      case BlockType.turnRight:
        await _require(
          robot.turnRight((parameters['angle'] as num).toDouble()),
          'Turn right',
        );
        break;
      case BlockType.stop:
        await _require(robot.stopRobot(), 'STOP');
        break;
      case BlockType.wait:
        await _wait(
          Duration(milliseconds: (parameters['time'] as num).toInt()),
        );
        break;
      case BlockType.ifDistance:
        final distance = await _await(robot.getDistance());
        if (distance == null)
          throw StateError('A fresh valid distance reading is unavailable.');
        if (distance < (parameters['distance'] as num)) {
          for (final child in block.children) {
            await _execute(child, insideCondition: true);
          }
        } else {
          _finished += _count(block) - 1;
          _onProgress?.call(
            _finished,
            _total,
            'Condition false; child blocks skipped',
          );
        }
        break;
      case BlockType.autoNavigate:
        await _require(robot.autoNavigate(), 'Auto navigation');
        await _wait(autoDuration);
        await _require(robot.stopRobot(), 'Stop auto navigation');
        break;
    }
    final parameter = BlockParameter.forType(block.type);
    // A zero-distance move or zero-duration wait does not demonstrate practice.
    if (parameter == null || (parameters[parameter.key] as num) > 0) {
      _executedTypes.add(block.type);
      if (insideCondition &&
          block.type != BlockType.ifDistance &&
          block.type != BlockType.wait) {
        _distanceReactionExecuted = true;
      }
    }
    _finished++;
    _onProgress?.call(_finished, _total, '${block.getDisplayName()} finished');
  }
}

class _ProgramCancelled implements Exception {
  const _ProgramCancelled();
}
