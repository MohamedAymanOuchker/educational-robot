import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/block_editor/block_types.dart';
import 'program_executor.dart';

/// Stable names, rather than enum indices, keep stored programs readable.
class BlockCodec {
  static List<Map<String, Object?>> encode(List<Block> blocks) {
    if (blocks.isNotEmpty) {
      final error = ProgramExecutor.validationError(blocks);
      if (error != null) throw FormatException(error);
    }
    Map<String, Object?> visit(Block block) {
      if (!_coordinate(block.position.dx) || !_coordinate(block.position.dy)) {
        throw const FormatException('Invalid block position.');
      }
      final parameter = BlockParameter.forType(block.type);
      return {
        'type': block.type.name,
        'parameters': {
          if (parameter != null)
            parameter.key: (block.parameters[parameter.key] as num).toInt(),
        },
        'x': block.position.dx,
        'y': block.position.dy,
        'color': block.color.toARGB32(),
        'children': block.children.map(visit).toList(),
      };
    }

    return blocks.map(visit).toList();
  }

  static bool _coordinate(dynamic value) =>
      value is num && value.isFinite && value >= 0 && value <= 100000;

  static List<Block> decode(dynamic data) {
    var count = 0;
    Block visit(dynamic value) {
      if (++count > 100 || value is! Map<String, dynamic>) {
        throw const FormatException('Invalid program or more than 100 blocks.');
      }
      final type = BlockType.values.where((type) => type.name == value['type']);
      if (type.length != 1 ||
          !_coordinate(value['x']) ||
          !_coordinate(value['y']) ||
          value['color'] is! int ||
          value['color'] < 0 ||
          value['color'] > 0xffffffff ||
          value['parameters'] is! Map<String, dynamic> ||
          value['children'] is! List) {
        throw const FormatException('Invalid saved block.');
      }
      final parameter = BlockParameter.forType(type.single);
      final parameters = value['parameters'] as Map<String, dynamic>;
      if (parameters.length != (parameter == null ? 0 : 1) ||
          (parameter != null &&
              !parameter.isValid(parameters[parameter.key]))) {
        throw const FormatException('Invalid saved block parameter.');
      }
      final children = value['children'] as List;
      if (type.single != BlockType.ifDistance && children.isNotEmpty) {
        throw const FormatException('Only If Distance can contain blocks.');
      }
      return Block(
        type: type.single,
        parameters: parameters,
        position: Offset(
          (value['x'] as num).toDouble(),
          (value['y'] as num).toDouble(),
        ),
        color: Color(value['color'] as int),
        children: children.map(visit).toList(),
      );
    }

    if (data is! List) throw const FormatException('Invalid saved program.');
    return data.map(visit).toList();
  }

  static String fingerprint(List<Block> blocks) => jsonEncode(encode(blocks));
}

class SavedProgram {
  SavedProgram({
    required this.name,
    required this.level,
    required this.savedAt,
    required List<Block> blocks,
  }) : _blocks = BlockCodec.encode(blocks);

  final String name;
  final int level;
  final DateTime savedAt;
  final List<Map<String, Object?>> _blocks;

  // Every caller receives its own editable tree, including parent references.
  List<Block> get blocks => BlockCodec.decode(jsonDecode(jsonEncode(_blocks)));

  Map<String, Object?> toJson() => {
    'name': name,
    'level': level,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'blocks': _blocks,
  };

  static SavedProgram fromJson(dynamic value) {
    if (value is! Map<String, dynamic> ||
        value['name'] is! String ||
        value['name'].trim().isEmpty ||
        value['name'].length > 64 ||
        value['level'] is! int ||
        value['level'] < 1 ||
        value['level'] > 5 ||
        value['savedAt'] is! String ||
        DateTime.tryParse(value['savedAt']) == null) {
      throw const FormatException('Invalid saved program details.');
    }
    return SavedProgram(
      name: value['name'],
      level: value['level'],
      savedAt: DateTime.parse(value['savedAt']),
      blocks: BlockCodec.decode(value['blocks']),
    );
  }
}

/// One versioned preference value; corrupt or newer data is never overwritten.
class ProgramStore {
  static const storageKey = 'savedPrograms.v1';
  static Future<void>? _writes;

  Future<List<SavedProgram>> load() async {
    final pending = _writes;
    if (pending != null) await pending;
    return _read(await SharedPreferences.getInstance());
  }

  Future<List<SavedProgram>> _read(SharedPreferences prefs) async {
    await prefs.reload();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    if (raw.length > 2000000)
      throw const FormatException('Program library is too large.');
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        data['programs'] is! List ||
        data['programs'].length > 50) {
      throw const FormatException('Unsupported or damaged program library.');
    }
    final programs = (data['programs'] as List)
        .map(SavedProgram.fromJson)
        .toList();
    final names = programs.map((p) => p.name.trim().toLowerCase()).toSet();
    if (names.length != programs.length) {
      throw const FormatException('Duplicate names in the program library.');
    }
    programs.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return programs;
  }

  Future<SavedProgram> save({
    required String name,
    required int level,
    required List<Block> blocks,
    bool replace = false,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 64 || level < 1 || level > 5) {
      throw const FormatException(
        'Use a name of 1–64 characters and a valid level.',
      );
    }
    final saved = SavedProgram(
      name: trimmed,
      level: level,
      savedAt: DateTime.now(),
      blocks: blocks,
    );
    final operation = (_writes ?? Future<void>.value()).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final programs = await _read(prefs);
      final index = programs.indexWhere(
        (p) => p.name.trim().toLowerCase() == trimmed.toLowerCase(),
      );
      if (index >= 0 && !replace)
        throw StateError('A program with that name already exists.');
      if (index < 0 && programs.length >= 50)
        throw StateError(
          'Library full (50 programs). Replace an existing program.',
        );
      if (index >= 0) {
        programs[index] = saved;
      } else {
        programs.add(saved);
      }
      if (!await prefs.setString(
        storageKey,
        jsonEncode({
          'version': 1,
          'programs': programs.map((p) => p.toJson()).toList(),
        }),
      )) {
        await prefs.reload();
        throw StateError(
          'Storage did not accept the program. Try saving again.',
        );
      }
      return saved;
    });
    late final Future<void> tail;
    tail = operation
        .then<void>((_) {}, onError: (Object _, StackTrace __) {})
        .whenComplete(() {
          // Retain only outstanding work; later calls need no completed future.
          if (identical(_writes, tail)) _writes = null;
        });
    _writes = tail;
    return operation;
  }
}
