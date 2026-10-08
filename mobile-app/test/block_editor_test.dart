import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/widgets/block_editor/block_editor_widget.dart';
import 'package:robocode/widgets/block_editor/block_types.dart';
import 'package:robocode/widgets/block_editor/block_widget.dart';

Block makeBlock(BlockType type, {Map<String, dynamic>? parameters}) => Block(
  type: type,
  parameters: parameters,
  position: const Offset(12, 34),
  color: Colors.blue,
);

Future<void> showBlock(WidgetTester tester, Block block) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 300, child: BlockWidget(block: block)),
      ),
    ),
  ),
);

void main() {
  test('each block owns mutable parameters and sensible defaults', () {
    final first = makeBlock(BlockType.moveForward);
    final second = makeBlock(BlockType.moveForward);
    first.parameters['distance'] = 25;
    expect(second.parameters['distance'], 100);
    expect(makeBlock(BlockType.turnRight).parameters['angle'], 90);
    expect(makeBlock(BlockType.wait).parameters['time'], 1000);
    expect(makeBlock(BlockType.ifDistance).parameters['distance'], 20);
    final supplied = <String, dynamic>{'angle': 45};
    final turn = makeBlock(BlockType.turnLeft, parameters: supplied);
    turn.parameters['angle'] = 60;
    expect(supplied['angle'], 45);
  });

  test(
    'reparenting removes old references and rejects cycles and leaf children',
    () {
      final first = makeBlock(BlockType.ifDistance);
      final second = makeBlock(BlockType.ifDistance);
      final move = makeBlock(BlockType.moveForward);
      expect(first.addChild(move), isTrue);
      expect(second.addChild(move), isTrue);
      expect(first.children, isEmpty);
      expect(second.children, [move]);
      expect(move.parent, same(second));
      expect(second.addChild(move), isTrue);
      expect(second.children, [move]);
      expect(first.addChild(second), isTrue);
      expect(second.addChild(first), isFalse);
      expect(first.addChild(first), isFalse);
      final wait = makeBlock(BlockType.wait);
      expect(wait.isContainer, isFalse);
      expect(wait.canHaveChildren, isFalse);
      expect(wait.addChild(move), isFalse);
      move.detach();
      expect(second.children, isEmpty);
      expect(move.parent, isNull);
    },
  );

  test(
    'clone snapshots preserve positions and rebuild independent parent links',
    () {
      final root = makeBlock(BlockType.ifDistance);
      final nested = makeBlock(BlockType.ifDistance);
      final move = makeBlock(
        BlockType.moveForward,
        parameters: {
          'metadata': {
            'values': [1, 2],
          },
        },
      );
      root.addChild(nested);
      nested.addChild(move);
      final copy = root.clone();
      expect(copy, isNot(same(root)));
      expect(copy.position, root.position);
      expect(copy.parent, isNull);
      expect(copy.children.single.parent, same(copy));
      final copiedMove = copy.children.single.children.single;
      expect(copiedMove.parent, same(copy.children.single));
      copiedMove.parameters['distance'] = 400;
      copiedMove.parameters['metadata']['values'][0] = 99;
      expect(move.parameters['distance'], 100);
      expect(move.parameters['metadata']['values'], [1, 2]);
      // Defensive snapshotting must not recurse forever on externally corrupted data.
      nested.children.add(root);
      expect(root.clone, throwsStateError);
    },
  );

  for (final type in [
    BlockType.moveForward,
    BlockType.moveBackward,
    BlockType.turnLeft,
    BlockType.turnRight,
    BlockType.wait,
    BlockType.ifDistance,
  ]) {
    testWidgets('${type.name} validates and edits both allowed limits', (
      tester,
    ) async {
      final block = makeBlock(type);
      final parameter = BlockParameter.forType(type)!;
      await showBlock(tester, block);
      await tester.tap(find.text(block.getDisplayName()));
      await tester.pumpAndSettle();
      for (final invalid in [
        '',
        '1.5',
        '${parameter.minimum - 1}',
        '${parameter.maximum + 1}',
      ]) {
        await tester.enterText(find.byType(TextFormField), invalid);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(block.parameters[parameter.key], parameter.defaultValue);
        expect(
          find.text(
            'Enter a whole number from ${parameter.minimum} to ${parameter.maximum}',
          ),
          findsOneWidget,
        );
      }
      await tester.enterText(
        find.byType(TextFormField),
        '${parameter.maximum}',
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(block.parameters[parameter.key], parameter.maximum);
      await tester.tap(find.text(block.getDisplayName()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        '${parameter.minimum}',
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(block.parameters[parameter.key], parameter.minimum);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('nested blocks render inline and Wait has no child drop target', (
    tester,
  ) async {
    final condition = makeBlock(BlockType.ifDistance);
    final nested = makeBlock(BlockType.ifDistance);
    nested.addChild(makeBlock(BlockType.wait));
    condition.addChild(nested);
    await showBlock(tester, condition);
    expect(find.byType(Positioned), findsNothing);
    expect(find.byType(DragTarget<Block>), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'toolbox clones, nesting, reparenting and moving back keep one instance',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      List<Block> program = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockEditorWidget(
              currentLevel: 3,
              onSave: (_) {},
              onRun: (blocks) => program = blocks,
              onClear: () {},
            ),
          ),
        ),
      );
      final grid = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GridPainter,
      );
      final origin = tester.getTopLeft(grid);
      Future<void> toolboxDrag(BlockType type, Offset destination) async {
        final source = find.byWidgetPredicate(
          (widget) =>
              widget is LongPressDraggable<Block> && widget.data?.type == type,
        );
        final gesture = await tester.startGesture(tester.getCenter(source));
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.moveTo(destination);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      Future<void> readProgram() async {
        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();
      }

      await toolboxDrag(BlockType.ifDistance, origin + const Offset(170, 100));
      await toolboxDrag(BlockType.ifDistance, origin + const Offset(520, 100));
      await readProgram();
      expect(program, hasLength(2));
      final first = program[0];
      final second = program[1];
      expect(first, isNot(same(second)));
      await toolboxDrag(
        BlockType.moveForward,
        tester.getCenter(find.text('Drop blocks here').first),
      );
      await readProgram();
      expect(program, hasLength(2));
      expect(first.children, hasLength(1));
      final move = first.children.single;
      move.parameters['distance'] = 123;
      final drag = find.byWidgetPredicate(
        (widget) => widget is Draggable<Block> && identical(widget.data, move),
      );
      await tester.dragFrom(
        tester.getCenter(drag),
        tester.getCenter(find.text('Drop blocks here')) -
            tester.getCenter(drag),
      );
      await tester.pumpAndSettle();
      await readProgram();
      expect(first.children, isEmpty);
      expect(second.children, [move]);
      expect(move.parameters['distance'], 123);
      final nestedDrag = find.byWidgetPredicate(
        (widget) => widget is Draggable<Block> && identical(widget.data, move),
      );
      await tester.dragFrom(
        tester.getCenter(nestedDrag),
        origin + const Offset(220, 420) - tester.getCenter(nestedDrag),
      );
      await tester.pumpAndSettle();
      await readProgram();
      expect(second.children, isEmpty);
      expect(program.where((block) => identical(block, move)), hasLength(1));
      expect(move.parent, isNull);
      await toolboxDrag(BlockType.moveForward, origin + const Offset(520, 420));
      await readProgram();
      expect(
        program.where((block) => block.type == BlockType.moveForward),
        hasLength(2),
      );
      expect(program.last.parameters['distance'], 100);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('portrait editor leaves a full width workspace', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlockEditorWidget(
            currentLevel: 3,
            onSave: (_) {},
            onRun: (_) {},
            onClear: () {},
          ),
        ),
      ),
    );
    final grid = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is GridPainter,
    );
    expect(tester.getSize(grid).width, 360);
    expect(tester.takeException(), isNull);
  });
}
