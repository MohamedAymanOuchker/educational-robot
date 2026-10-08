import 'package:flutter/material.dart';

enum BlockType {
  moveForward,
  moveBackward,
  turnLeft,
  turnRight,
  stop,
  wait,
  ifDistance,
  autoNavigate,
}

/// The units and limits used by both the editor and program validation.
class BlockParameter {
  final String key;
  final String label;
  final String unit;
  final int minimum;
  final int maximum;
  final int defaultValue;

  const BlockParameter(
    this.key,
    this.label,
    this.unit,
    this.minimum,
    this.maximum,
    this.defaultValue,
  );

  bool isValid(dynamic value) =>
      value is num &&
      value.isFinite &&
      value == value.roundToDouble() &&
      value >= minimum &&
      value <= maximum;

  static BlockParameter? forType(BlockType type) {
    switch (type) {
      case BlockType.moveForward:
      case BlockType.moveBackward:
        return const BlockParameter('distance', 'Distance', 'cm', 0, 500, 100);
      case BlockType.turnLeft:
      case BlockType.turnRight:
        return const BlockParameter('angle', 'Angle', '°', 0, 360, 90);
      case BlockType.wait:
        return const BlockParameter('time', 'Wait time', 'ms', 0, 60000, 1000);
      case BlockType.ifDistance:
        return const BlockParameter(
          'distance',
          'Distance threshold',
          'cm',
          2,
          400,
          20,
        );
      case BlockType.stop:
      case BlockType.autoNavigate:
        return null;
    }
  }
}

class Block {
  final BlockType type;
  final Map<String, dynamic> parameters;
  Offset position;
  Color color;
  Block? parent;
  final List<Block> children = [];

  Block({
    required this.type,
    Map<String, dynamic>? parameters,
    required this.position,
    required this.color,
    Block? parent,
    List<Block>? children,
    // Kept for existing callers. Only If Distance can contain children.
    bool? canHaveChildren,
  }) : parameters = {
         if (BlockParameter.forType(type) != null)
           BlockParameter.forType(type)!.key: BlockParameter.forType(
             type,
           )!.defaultValue,
         ...?parameters,
       } {
    for (final child in List<Block>.of(children ?? [])) {
      if (!addChild(child)) {
        throw ArgumentError('This block cannot contain that child.');
      }
    }
    if (parent != null && !parent.addChild(this)) {
      throw ArgumentError('This block cannot be attached to that parent.');
    }
  }

  bool get isContainer => type == BlockType.ifDistance;
  bool get canHaveChildren => isContainer;

  bool _contains(Block block, Set<Block> visited) {
    if (identical(this, block)) return true;
    if (!visited.add(this)) return false;
    return children.any((child) => child._contains(block, visited));
  }

  bool canAcceptChild(Block child) =>
      isContainer && !child._contains(this, <Block>{});

  /// Moves a child between containers without leaving duplicate references.
  bool addChild(Block child) {
    if (!canAcceptChild(child)) return false;
    child.detach();
    children.removeWhere((existing) => identical(existing, child));
    children.add(child);
    child.parent = this;
    return true;
  }

  void detach() {
    parent?.children.removeWhere((child) => identical(child, this));
    parent = null;
  }

  /// Creates an independent program snapshot with correct parent references.
  Block clone() => _clone(<Block>{});

  Block _clone(Set<Block> ancestors) {
    if (!ancestors.add(this)) {
      throw StateError('A program cannot contain a cycle.');
    }
    final copy = Block(
      type: type,
      parameters: {
        for (final entry in parameters.entries)
          entry.key: _copyParameter(entry.value),
      },
      position: position,
      color: color,
    );
    for (final child in children) {
      if (!copy.addChild(child._clone(ancestors))) {
        throw StateError('Only If Distance blocks can contain children.');
      }
    }
    ancestors.remove(this);
    return copy;
  }

  static dynamic _copyParameter(dynamic value) {
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key, _copyParameter(entry)));
    }
    if (value is List) return value.map(_copyParameter).toList();
    return value;
  }

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
    }
  }
}
