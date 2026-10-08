import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/services/program_store.dart';
import 'package:robocode/widgets/block_editor/block_types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/failing_preferences.dart';

Block block(BlockType type, {List<Block>? children}) => Block(
  type: type,
  position: const Offset(18.5, 420),
  color: Colors.purple,
  children: children,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'all block types and nested trees survive a fresh store with independent parents',
    () async {
      final nested = block(
        BlockType.ifDistance,
        children: [block(BlockType.turnLeft)],
      );
      final root = block(
        BlockType.ifDistance,
        children: [nested, block(BlockType.wait)],
      );
      final program = [root, for (final type in BlockType.values) block(type)];
      nested.children.single.parameters['angle'] = 123;
      final expected = BlockCodec.fingerprint(program);
      final save = ProgramStore().save(
        name: '  My path  ',
        level: 3,
        blocks: program,
      );
      nested.children.single.parameters['angle'] = 45;
      await save;
      final loaded = (await ProgramStore().load()).single;
      expect(loaded.name, 'My path');
      expect(loaded.level, 3);
      expect(BlockCodec.fingerprint(loaded.blocks), expected);
      final copy = loaded.blocks;
      expect(copy.first.parent, isNull);
      expect(copy.first.children.first.parent, same(copy.first));
      copy.first.children.clear();
      expect(loaded.blocks.first.children, hasLength(2));
    },
  );

  test(
    'case-insensitive replacement is explicit, and simultaneous saves do not lose programs',
    () async {
      await Future.wait([
        ProgramStore().save(name: 'First', level: 1, blocks: []),
        ProgramStore().save(name: 'Second', level: 1, blocks: []),
      ]);
      await expectLater(
        ProgramStore().save(name: 'FIRST', level: 2, blocks: []),
        throwsStateError,
      );
      expect(await ProgramStore().load(), hasLength(2));
      await ProgramStore().save(
        name: 'first',
        level: 2,
        blocks: [block(BlockType.stop)],
        replace: true,
      );
      final programs = await ProgramStore().load();
      expect(programs, hasLength(2));
      expect(
        programs.firstWhere((p) => p.name == 'first').blocks.single.type,
        BlockType.stop,
      );
    },
  );

  test(
    'invalid or future libraries stay intact when opening or saving fails',
    () async {
      final valid = SavedProgram(
        name: 'A',
        level: 1,
        savedAt: DateTime.utc(2026),
        blocks: [block(BlockType.wait)],
      ).toJson();
      final invalidBlock =
          jsonDecode(jsonEncode(valid)) as Map<String, dynamic>;
      invalidBlock['blocks'][0]['parameters']['time'] = -1;
      for (final raw in [
        '{',
        jsonEncode({'version': 2, 'programs': []}),
        jsonEncode({
          'version': 1,
          'programs': [invalidBlock],
        }),
        jsonEncode({
          'version': 1,
          'programs': [valid, valid],
        }),
      ]) {
        SharedPreferences.setMockInitialValues({ProgramStore.storageKey: raw});
        await expectLater(ProgramStore().load(), throwsFormatException);
        await expectLater(
          ProgramStore().save(name: 'B', level: 1, blocks: []),
          throwsFormatException,
        );
        expect(
          (await SharedPreferences.getInstance()).getString(
            ProgramStore.storageKey,
          ),
          raw,
        );
      }
    },
  );

  test(
    'bad types, positions, leaf children, excessive trees and cycles are rejected',
    () {
      final template = BlockCodec.encode([block(BlockType.wait)]);
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (v) => v['type'] = 'unknown',
        (v) => v['x'] = -1,
        (v) => v['parameters'] = {},
        (v) => v['children'] = BlockCodec.encode([block(BlockType.stop)]),
      ]) {
        final entry =
            (jsonDecode(jsonEncode(template)) as List).single
                as Map<String, dynamic>;
        mutate(entry);
        expect(() => BlockCodec.decode([entry]), throwsFormatException);
      }
      final tooMany = List.generate(101, (_) => block(BlockType.stop));
      expect(() => BlockCodec.encode(tooMany), throwsFormatException);
      expect(
        () => BlockCodec.decode(List.generate(101, (_) => template.single)),
        throwsFormatException,
      );
      final cycle = block(BlockType.ifDistance);
      cycle.children.add(cycle);
      expect(() => BlockCodec.encode([cycle]), throwsFormatException);
    },
  );

  for (final throws in [false, true]) {
    test(
      'failed storage (throws=$throws) is reported and a later save can succeed',
      () async {
        final platform = FailingPreferences()..throwOnWrite = throws;
        SharedPreferencesStorePlatform.instance = platform;
        await expectLater(
          ProgramStore().save(name: 'Draft', level: 1, blocks: []),
          throwsStateError,
        );
        expect(await ProgramStore().load(), isEmpty);
        platform.fail = false;
        await ProgramStore().save(name: 'Draft', level: 1, blocks: []);
        expect((await ProgramStore().load()).single.name, 'Draft');
      },
    );
  }
}
