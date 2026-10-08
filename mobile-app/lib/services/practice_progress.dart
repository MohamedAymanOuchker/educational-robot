import '../widgets/block_editor/block_types.dart';
import 'program_executor.dart';

/// Practice checks attest to executed commands, not measured learning outcomes
/// or the robot's actual physical path.
class PracticeProgress {
  static bool qualifies(int level, ProgramResult result) {
    if (result.status != ProgramStatus.completed || !result.stopConfirmed)
      return false;
    final types = result.executedTypes;
    final movement = types.any(
      (type) => const {
        BlockType.moveForward,
        BlockType.moveBackward,
        BlockType.turnLeft,
        BlockType.turnRight,
      }.contains(type),
    );
    switch (level) {
      case 1:
        return movement;
      case 2:
        return movement && types.contains(BlockType.wait);
      case 3:
        return result.distanceReactionExecuted;
      case 4:
        return types.contains(BlockType.autoNavigate);
      case 5:
        return types.contains(BlockType.autoNavigate) &&
            result.distanceReactionExecuted;
      default:
        return false;
    }
  }

  static String hint(int level) => switch (level) {
    1 => 'Finish a run with a nonzero move or turn.',
    2 => 'Finish a run with a nonzero move or turn and a nonzero Wait.',
    3 =>
      'Finish a run where If Distance is true and a move, turn, Stop, or Auto Navigate inside it executes.',
    4 => 'Finish a run with the 3-second Auto Navigate block.',
    5 =>
      'Finish a run with Auto Navigate and a move, turn, Stop, or Auto Navigate inside a true If Distance.',
    _ => 'Select a level from 1 to 5.',
  };
}
