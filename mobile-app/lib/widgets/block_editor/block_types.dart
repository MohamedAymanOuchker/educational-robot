import 'package:flutter/material.dart';

enum BlockType {
  moveForward,
  moveBackward,
  turnLeft,
  turnRight,
  stop,
  wait,
  ifDistance,
  autoNavigate
}

class Block {
  final BlockType type;
  Map<String, dynamic> parameters;
  Offset position;
  Color color;
  Block? parent;
  List<Block> children;
  bool canHaveChildren;

  Block({
    required this.type,
    this.parameters = const {},
    required this.position,
    required this.color,
    this.parent,
    List<Block>? children,
    this.canHaveChildren = false,
  }) : children = children ?? [];

  bool get isContainer =>
      type == BlockType.ifDistance || type == BlockType.wait;

  String getDisplayName() {
    switch (type) {
      case BlockType.moveForward:
        return 'Move Forward';
      case BlockType.moveBackward:
        return 'Move Backward';
      case BlockType.turnLeft:
        return 'Turn Left';
      case BlockType.turnRight:
        return 'Turn Right';
      case BlockType.stop:
        return 'Stop';
      case BlockType.wait:
        return 'Wait';
      case BlockType.ifDistance:
        return 'If Distance <';
      case BlockType.autoNavigate:
        return 'Auto Navigate';
      default:
        return 'Unknown';
    }
  }
}
