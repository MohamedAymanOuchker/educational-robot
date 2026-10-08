import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/services/levels_service.dart';
import 'package:robocode/widgets/block_editor/block_editor_widget.dart';
import 'package:robocode/widgets/block_editor/block_types.dart';

void main() {
  for (final level in LevelsService.levels) {
    testWidgets('level ${level.id} exposes only its implemented toolbox', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockEditorWidget(
              currentLevel: level.id,
              onSave: (_) {},
              onRun: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );
      final types = tester
          .widgetList<LongPressDraggable<Block>>(
            find.byWidgetPredicate(
              (widget) => widget is LongPressDraggable<Block>,
            ),
          )
          .map((widget) => widget.data!.type)
          .toSet();
      expect(types, level.blocks.toSet());
      expect(types.contains(BlockType.wait), level.id >= 2);
      expect(types.contains(BlockType.ifDistance), level.id >= 3);
      expect(types.contains(BlockType.autoNavigate), level.id >= 4);
      expect(level.blocks.length, types.length);
      expect(tester.takeException(), isNull);
    });
  }
}
