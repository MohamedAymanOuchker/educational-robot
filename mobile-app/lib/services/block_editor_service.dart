import 'package:flutter/material.dart';
import '../widgets/block_editor/block_types.dart';
import 'program_executor.dart';

class BlockEditorService {
  /// Human-readable preview. Execution always uses ProgramExecutor and Blocks.
  static String generateCodeFromBlocks(List<Block> blocks) {
    final error = ProgramExecutor.validationError(blocks);
    if (error != null) throw ArgumentError(error);
    final ordered = List<Block>.of(blocks)
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    final lines = <String>[
      '// Program preview; the app executes the typed block tree.',
      '// Movement waits for completion reported by the robot.',
    ];
    void describe(Block block, String indent) {
      switch (block.type) {
        case BlockType.moveForward:
        case BlockType.moveBackward:
          lines.add(
            '$indent${block.getDisplayName()} ${block.parameters['distance']} cm',
          );
          break;
        case BlockType.turnLeft:
        case BlockType.turnRight:
          lines.add(
            '$indent${block.getDisplayName()} ${block.parameters['angle']} degrees',
          );
          break;
        case BlockType.stop:
          lines.add('${indent}Stop');
          break;
        case BlockType.wait:
          lines.add('${indent}Wait ${block.parameters['time']} ms');
          break;
        case BlockType.ifDistance:
          lines.add(
            '${indent}If fresh distance < ${block.parameters['distance']} cm:',
          );
          for (final child in block.children) {
            describe(child, '$indent  ');
          }
          break;
        case BlockType.autoNavigate:
          lines.add('${indent}Auto Navigate for 3 seconds, then Stop');
          break;
      }
    }

    for (final block in ordered) {
      describe(block, '');
    }
    lines.add('Stop (end of program)');
    return lines.join('\n');
  }

  static List<Block> getBlocksForLevel(int levelId) {
    final types = [
      BlockType.moveForward,
      BlockType.moveBackward,
      BlockType.turnLeft,
      BlockType.turnRight,
      BlockType.stop,
      if (levelId >= 2) BlockType.wait,
      if (levelId >= 3) BlockType.ifDistance,
      if (levelId >= 4) BlockType.autoNavigate,
    ];
    return types
        .map(
          (type) => Block(
            type: type,
            position: Offset.zero,
            color: type == BlockType.stop
                ? Colors.red
                : type == BlockType.wait
                ? Colors.orange
                : type == BlockType.ifDistance
                ? Colors.purple
                : type == BlockType.autoNavigate
                ? Colors.teal
                : Colors.blue,
          ),
        )
        .toList();
  }

  static bool validateBlockSequence(List<Block> blocks) =>
      ProgramExecutor.validationError(blocks) == null;

  static String getValidationErrorMessage(List<Block> blocks) =>
      ProgramExecutor.validationError(blocks) ?? 'Your program looks good!';

  static String generateSimpleCommands(List<Block> blocks) =>
      generateCodeFromBlocks(blocks);
}
