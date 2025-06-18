import 'package:flutter/material.dart';
import '../widgets/block_editor/block_types.dart';

class BlockEditorService {
  static String generateCodeFromBlocks(List<Block> blocks) {
    String code = '';
    try {
      // Sort blocks by vertical position to maintain execution order
      blocks.sort((a, b) => a.position.dy.compareTo(b.position.dy));

      code += '// Generated robot control code\n';
      code += 'import \'../services/robot_service.dart\';\n\n';
      code += 'Future<void> executeProgram() async {\n';
      code += '  final robotService = RobotService();\n';
      code += '  \n';
      code += '  if (!robotService.isConnected) {\n';
      code += '    throw Exception(\'Robot not connected!\');\n';
      code += '  }\n\n';

      for (var block in blocks) {
        code += _generateCodeForBlock(block, 2); // 2 spaces indentation
      }

      code += '}\n';
    } catch (e) {
      throw Exception('Error generating code: $e');
    }
    return code;
  }

  static String _generateCodeForBlock(Block block, int indent) {
    String indentation = '  ' * indent;
    String code = '';

    switch (block.type) {
      case BlockType.moveForward:
        int distance = block.parameters["distance"]?.toInt() ?? 100;
        code += '${indentation}await robotService.moveForward($distance);\n';
        code +=
            '${indentation}await Future.delayed(Duration(milliseconds: ${_calculateMovementDelay(distance)}));\n';
        break;

      case BlockType.moveBackward:
        int distance = block.parameters["distance"]?.toInt() ?? 100;
        code += '${indentation}await robotService.moveBackward($distance);\n';
        code +=
            '${indentation}await Future.delayed(Duration(milliseconds: ${_calculateMovementDelay(distance)}));\n';
        break;

      case BlockType.turnLeft:
        int angle = block.parameters["angle"]?.toInt() ?? 90;
        code += '${indentation}await robotService.turnLeft($angle);\n';
        code +=
            '${indentation}await Future.delayed(Duration(milliseconds: ${_calculateTurnDelay(angle)}));\n';
        break;

      case BlockType.turnRight:
        int angle = block.parameters["angle"]?.toInt() ?? 90;
        code += '${indentation}await robotService.turnRight($angle);\n';
        code +=
            '${indentation}await Future.delayed(Duration(milliseconds: ${_calculateTurnDelay(angle)}));\n';
        break;

      case BlockType.stop:
        code += '${indentation}await robotService.stopRobot();\n';
        break;

      case BlockType.wait:
        int time = block.parameters["time"]?.toInt() ?? 1000;
        code +=
            '${indentation}await Future.delayed(Duration(milliseconds: $time));\n';
        break;

      case BlockType.ifDistance:
        int distance = block.parameters["distance"]?.toInt() ?? 20;
        code += '${indentation}// Check distance sensor\n';
        code +=
            '${indentation}double? currentDistance = await robotService.getDistance();\n';
        code +=
            '${indentation}if (currentDistance != null && currentDistance < $distance) {\n';

        // Generate code for child blocks
        for (var child in block.children) {
          code += _generateCodeForBlock(child, indent + 1);
        }

        code += '$indentation}\n';
        break;

      case BlockType.autoNavigate:
        code += '${indentation}await robotService.autoNavigate();\n';
        code += '${indentation}// Wait for autonomous navigation to complete\n';
        code += '${indentation}await Future.delayed(Duration(seconds: 3));\n';
        break;
    }

    return code;
  }

  // Calculate realistic movement delays based on distance
  static int _calculateMovementDelay(int distance) {
    // Assume robot moves at ~10cm/second
    return (distance * 100).clamp(500, 5000); // Min 500ms, max 5s
  }

  // Calculate realistic turn delays based on angle
  static int _calculateTurnDelay(int angle) {
    // Assume robot turns at ~90 degrees/second
    return ((angle / 90) * 1000).round().clamp(250, 4000); // Min 250ms, max 4s
  }

  static List<Block> getBlocksForLevel(int levelId) {
    List<Block> blocks = [];

    // Basic movement blocks (available in all levels)
    blocks.addAll([
      Block(
        type: BlockType.moveForward,
        position: Offset.zero,
        color: Colors.blue,
        parameters: {"distance": 100},
      ),
      Block(
        type: BlockType.moveBackward,
        position: Offset.zero,
        color: Colors.blue,
        parameters: {"distance": 100},
      ),
      Block(
        type: BlockType.turnLeft,
        position: Offset.zero,
        color: Colors.blue,
        parameters: {"angle": 90},
      ),
      Block(
        type: BlockType.turnRight,
        position: Offset.zero,
        color: Colors.blue,
        parameters: {"angle": 90},
      ),
      Block(
        type: BlockType.stop,
        position: Offset.zero,
        color: Colors.red,
      ),
    ]);

    // Level-specific blocks
    switch (levelId) {
      case 2: // Path Planning
        blocks.add(Block(
          type: BlockType.wait,
          position: Offset.zero,
          color: Colors.orange,
          parameters: {"time": 1000},
          canHaveChildren: false,
        ));
        break;

      case 3: // Sensor Integration
        blocks.add(Block(
          type: BlockType.ifDistance,
          position: Offset.zero,
          color: Colors.purple,
          parameters: {"distance": 20},
          canHaveChildren: true,
        ));
        break;

      case 4: // Auto Mode
      case 5: // Advanced Navigation
        blocks.addAll([
          Block(
            type: BlockType.ifDistance,
            position: Offset.zero,
            color: Colors.purple,
            parameters: {"distance": 20},
            canHaveChildren: true,
          ),
          Block(
            type: BlockType.autoNavigate,
            position: Offset.zero,
            color: Colors.teal,
          ),
        ]);
        break;
    }

    return blocks;
  }

  // Enhanced validation with more specific feedback
  static bool validateBlockSequence(List<Block> blocks) {
    if (blocks.isEmpty) {
      print('Validation failed: No blocks in workspace');
      return false;
    }

    try {
      // Collect all blocks including nested ones
      List<Block> allBlocks = [];
      void collectBlocks(Block block) {
        allBlocks.add(block);
        for (var child in block.children) {
          collectBlocks(child);
        }
      }

      for (var block in blocks) {
        collectBlocks(block);
      }

      // Check for at least one action block
      bool hasAnyAction = allBlocks.any((b) =>
          b.type == BlockType.moveForward ||
          b.type == BlockType.moveBackward ||
          b.type == BlockType.turnLeft ||
          b.type == BlockType.turnRight ||
          b.type == BlockType.autoNavigate);

      if (!hasAnyAction) {
        print('Validation failed: No action blocks found');
        return false;
      }

      // Validate container blocks have appropriate children
      for (var block in allBlocks) {
        if (block.isContainer && block.children.isEmpty) {
          print(
              'Warning: Container block "${block.getDisplayName()}" has no children');
          // Allow empty containers but warn
        }
      }

      // Check for infinite loops (basic detection)
      if (_hasInfiniteLoop(blocks)) {
        print('Validation failed: Potential infinite loop detected');
        return false;
      }

      // Validate parameter values
      for (var block in allBlocks) {
        if (!_validateBlockParameters(block)) {
          print(
              'Validation failed: Invalid parameters in block "${block.getDisplayName()}"');
          return false;
        }
      }

      print('Validation passed: ${allBlocks.length} blocks validated');
      return true;
    } catch (e) {
      print('Error validating block sequence: $e');
      return false;
    }
  }

  // Basic infinite loop detection
  static bool _hasInfiniteLoop(List<Block> blocks) {
    // Simple check: if there are more than 100 total blocks (including nested),
    // it might be an infinite loop or too complex
    int totalBlocks = 0;
    void countBlocks(Block block) {
      totalBlocks++;
      for (var child in block.children) {
        countBlocks(child);
      }
    }

    for (var block in blocks) {
      countBlocks(block);
    }

    return totalBlocks > 100;
  }

  // Validate individual block parameters
  static bool _validateBlockParameters(Block block) {
    switch (block.type) {
      case BlockType.moveForward:
      case BlockType.moveBackward:
        if (block.parameters.containsKey("distance")) {
          int? distance = block.parameters["distance"]?.toInt();
          if (distance == null || distance <= 0 || distance > 1000) {
            return false; // Invalid distance
          }
        }
        break;

      case BlockType.turnLeft:
      case BlockType.turnRight:
        if (block.parameters.containsKey("angle")) {
          int? angle = block.parameters["angle"]?.toInt();
          if (angle == null || angle <= 0 || angle > 360) {
            return false; // Invalid angle
          }
        }
        break;

      case BlockType.wait:
        if (block.parameters.containsKey("time")) {
          int? time = block.parameters["time"]?.toInt();
          if (time == null || time <= 0 || time > 10000) {
            return false; // Invalid wait time
          }
        }
        break;

      case BlockType.ifDistance:
        if (block.parameters.containsKey("distance")) {
          int? distance = block.parameters["distance"]?.toInt();
          if (distance == null || distance <= 0 || distance > 200) {
            return false; // Invalid sensor distance
          }
        }
        break;

      default:
        // Other blocks don't need parameter validation
        break;
    }
    return true;
  }

  // Get validation error message for better user feedback
  static String getValidationErrorMessage(List<Block> blocks) {
    if (blocks.isEmpty) {
      return 'Add some blocks to your workspace to create a program!';
    }

    List<Block> allBlocks = [];
    void collectBlocks(Block block) {
      allBlocks.add(block);
      for (var child in block.children) {
        collectBlocks(child);
      }
    }

    for (var block in blocks) {
      collectBlocks(block);
    }

    // Check for action blocks
    bool hasAnyAction = allBlocks.any((b) =>
        b.type == BlockType.moveForward ||
        b.type == BlockType.moveBackward ||
        b.type == BlockType.turnLeft ||
        b.type == BlockType.turnRight ||
        b.type == BlockType.autoNavigate);

    if (!hasAnyAction) {
      return 'Add at least one movement block to make your robot do something!';
    }

    // Check for parameter issues
    for (var block in allBlocks) {
      if (!_validateBlockParameters(block)) {
        switch (block.type) {
          case BlockType.moveForward:
          case BlockType.moveBackward:
            return 'Distance must be between 1 and 1000 cm in your movement blocks!';
          case BlockType.turnLeft:
          case BlockType.turnRight:
            return 'Angle must be between 1 and 360 degrees in your turn blocks!';
          case BlockType.wait:
            return 'Wait time must be between 1 and 10000 ms!';
          case BlockType.ifDistance:
            return 'Sensor distance must be between 1 and 200 cm!';
          default:
            return 'Check the parameters in your "${block.getDisplayName()}" block!';
        }
      }
    }

    // Check for empty container blocks
    for (var block in allBlocks) {
      if (block.isContainer && block.children.isEmpty) {
        return 'The "${block.getDisplayName()}" block needs some blocks inside it to work!';
      }
    }

    // Check for potential infinite loops
    if (_hasInfiniteLoop(blocks)) {
      return 'Your program might be too complex or have infinite loops. Try simplifying it!';
    }

    return 'Your program looks good!';
  }

  // Generate simple command string for quick execution (used by run screen)
  static String generateSimpleCommands(List<Block> blocks) {
    String commands = '';

    for (var block in blocks) {
      commands += _generateSimpleCommand(block);
    }

    return commands.trim();
  }

  static String _generateSimpleCommand(Block block) {
    switch (block.type) {
      case BlockType.moveForward:
        int distance = block.parameters["distance"]?.toInt() ?? 100;
        return 'await sendCommand("F$distance");\n';
      case BlockType.moveBackward:
        int distance = block.parameters["distance"]?.toInt() ?? 100;
        return 'await sendCommand("B$distance");\n';
      case BlockType.turnLeft:
        int angle = block.parameters["angle"]?.toInt() ?? 90;
        return 'await sendCommand("L$angle");\n';
      case BlockType.turnRight:
        int angle = block.parameters["angle"]?.toInt() ?? 90;
        return 'await sendCommand("R$angle");\n';
      case BlockType.stop:
        return 'await sendCommand("STOP");\n';
      case BlockType.wait:
        int time = block.parameters["time"]?.toInt() ?? 1000;
        return 'await Future.delayed(Duration(milliseconds: $time));\n';
      case BlockType.ifDistance:
        int distance = block.parameters["distance"]?.toInt() ?? 20;
        String childCommands = '';
        for (var child in block.children) {
          childCommands += _generateSimpleCommand(child);
        }
        return 'if ((await getDistance()) < $distance) {\n$childCommands}\n';
      case BlockType.autoNavigate:
        return 'await sendCommand("AUTO_NAV");\n';
      default:
        return '';
    }
  }
}
