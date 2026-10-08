import '../widgets/block_editor/block_types.dart';

class Level {
  const Level({
    required this.id,
    required this.name,
    required this.description,
    required this.blocks,
  });
  final int id;
  final String name;
  final String description;
  final List<BlockType> blocks;
}

/// The actual editor toolbox; future block concepts do not belong here.
class LevelsService {
  static const _movement = [
    BlockType.moveForward,
    BlockType.moveBackward,
    BlockType.turnLeft,
    BlockType.turnRight,
    BlockType.stop,
  ];
  static const _sequence = [..._movement, BlockType.wait];
  static const _sensors = [..._sequence, BlockType.ifDistance];
  static const _auto = [..._sensors, BlockType.autoNavigate];

  static const levels = [
    Level(
      id: 1,
      name: 'Basic Movement',
      description:
          'Try a short move or turn and compare the result with your prediction.',
      blocks: _movement,
    ),
    Level(
      id: 2,
      name: 'Movement Sequences',
      description: 'Arrange moves and timed waits from top to bottom.',
      blocks: _sequence,
    ),
    Level(
      id: 3,
      name: 'Distance Decisions',
      description: 'Use a distance check to decide whether child blocks run.',
      blocks: _sensors,
    ),
    Level(
      id: 4,
      name: 'Auto Mode',
      description: 'Observe a supervised three-second navigation attempt.',
      blocks: _auto,
    ),
    Level(
      id: 5,
      name: 'Combined Behaviors',
      description:
          'Combine a distance decision with a short Auto Navigate activity.',
      blocks: _auto,
    ),
  ];

  static Level getLevelById(int id) =>
      levels.firstWhere((level) => level.id == id, orElse: () => levels.first);
}
