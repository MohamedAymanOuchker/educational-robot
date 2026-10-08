import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:robocode/screens/code_screen.dart';
import 'package:robocode/services/app_state.dart';
import 'package:robocode/services/program_store.dart';
import 'package:robocode/widgets/block_editor/block_types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/failing_preferences.dart';
import 'support/fake_robot_client.dart';

Block move(int distance) => Block(
  type: BlockType.moveForward,
  parameters: {'distance': distance},
  position: const Offset(12, 20),
  color: Colors.blue,
);

Future<void> settleStorage(WidgetTester tester) async {
  // Preferences were initialized outside the widget test's fake clock. Drain
  // both zones across the read / write / UI continuations.
  for (var i = 0; i < 10; i++) {
    await tester.pump();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
  }
  await tester.pumpAndSettle();
}

Future<void> mount(
  WidgetTester tester,
  AppState state,
  FakeRobotClient robot,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        home: Scaffold(body: CodeScreen(robot: robot)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester, String name) async {
  await tester.tap(find.text('Open'));
  await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  expect(
    find.text('Open program'),
    findsOneWidget,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .join(' | '),
  );
  await tester.tap(find.textContaining('$name\nLevel'));
  await tester.pumpAndSettle();
}

Future<void> editDistance(WidgetTester tester, int current, int next) async {
  await tester.tap(find.text('$current cm').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), '$next');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> saveAs(WidgetTester tester, String name) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), name);
  await tester.tap(find.widgetWithText(FilledButton, 'Save program'));
  await settleStorage(tester);
}

void main() {
  late AppState state;
  late FakeRobotClient robot;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    state = AppState();
    await state.ready;
    robot = FakeRobotClient();
    await ProgramStore().save(name: 'Original', level: 1, blocks: [move(30)]);
  });
  tearDown(() async {
    state.dispose();
    await robot.dispose();
  });

  testWidgets(
    'save, recreate screen, reopen, and run keeps programs separate from practice',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await mount(tester, state, robot);
      await open(tester, 'Original');
      await editDistance(tester, 30, 25);
      await saveAs(tester, 'My route');
      expect(
        find.text('Program: My route · Save to keep changes'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(' | '),
      );
      expect(state.completedLevels, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await mount(tester, state, robot);
      await open(tester, 'My route');
      expect(find.text('25 cm'), findsOneWidget);
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await settleStorage(tester);
      expect(robot.calls, ['F25', 'STOP']);
      expect(
        find.text('Level 1 practice recorded. Level 2 is available on Home.'),
        findsOneWidget,
      );
      expect(state.completedLevels, {1});
      expect(state.currentLevel, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('25 cm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'open and clear protect unsaved edits; cancelling replacement keeps the disk copy',
    (tester) async {
      await mount(tester, state, robot);
      await open(tester, 'Original');
      await editDistance(tester, 30, 40);
      await open(tester, 'Original');
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('40 cm'), findsOneWidget);
      await saveAs(tester, 'original');
      expect(find.text('Replace saved program?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final programs = await tester.runAsync(() => ProgramStore().load());
      expect(programs!.single.blocks.single.parameters['distance'], 30);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('40 cm'), findsOneWidget);
      await open(tester, 'Original');
      await tester.tap(find.text('Open anyway'));
      await tester.pumpAndSettle();
      expect(find.text('30 cm'), findsOneWidget);
      expect(find.text('40 cm'), findsNothing);
    },
  );

  testWidgets('failed robot runs never unlock practice', (tester) async {
    robot.onCommand = (command) async => command != 'F30';
    await mount(tester, state, robot);
    await open(tester, 'Original');
    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await settleStorage(tester);
    expect(state.completedLevels, isEmpty);
    expect(state.isLevelUnlocked(2), isFalse);
    expect(find.byKey(const Key('practice-result')), findsNothing);
  });

  testWidgets('a rejected save keeps the workspace and does not show success', (
    tester,
  ) async {
    await mount(tester, state, robot);
    await open(tester, 'Original');
    SharedPreferencesStorePlatform.instance = FailingPreferences();
    await saveAs(tester, 'Rejected');
    expect(find.textContaining('Program could not be saved.'), findsOneWidget);
    expect(find.text('30 cm'), findsOneWidget);
    expect(state.completedLevels, isEmpty);
    expect(await tester.runAsync(() => ProgramStore().load()), isEmpty);
  });

  testWidgets(
    'practice write failure reports a successful run but no saved badge',
    (tester) async {
      await mount(tester, state, robot);
      await open(tester, 'Original');
      SharedPreferencesStorePlatform.instance = FailingPreferences();
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await settleStorage(tester);
      expect(state.completedLevels, isEmpty);
      expect(
        find.textContaining(
          'Program ran, but practice progress could not be saved.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('execution-status'))).data,
        contains('successfully'),
      );
    },
  );
}
