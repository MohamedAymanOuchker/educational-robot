import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/services/app_state.dart';
import 'package:robocode/services/practice_progress.dart';
import 'package:robocode/services/program_executor.dart';
import 'package:robocode/widgets/block_editor/block_types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/failing_preferences.dart';
import 'support/fake_robot_client.dart';

Block block(
  BlockType type, {
  Map<String, dynamic>? parameters,
  List<Block>? children,
}) => Block(
  type: type,
  parameters: parameters,
  children: children,
  position: Offset.zero,
  color: Colors.blue,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeRobotClient robot;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    robot = FakeRobotClient();
  });
  tearDown(() => robot.dispose());

  test(
    'fresh progress starts at zero, unlocks only after successful practice and reloads',
    () async {
      final state = AppState();
      addTearDown(state.dispose);
      await state.ready;
      expect(state.progressPercentage, 0);
      expect(state.completedLevels, isEmpty);
      expect(state.isLevelUnlocked(0), isFalse);
      final result = await ProgramExecutor(
        robot,
      ).run([block(BlockType.moveForward)]);
      expect(await state.recordPracticeRun(1, result), isTrue);
      expect(await state.recordPracticeRun(1, result), isFalse);
      expect(state.currentLevel, 1);
      expect(state.isLevelUnlocked(2), isTrue);
      expect(state.isLevelUnlocked(3), isFalse);
      final restored = AppState();
      addTearDown(restored.dispose);
      await restored.ready;
      expect(restored.completedLevels, {1});
      expect(restored.progressPercentage, 0.2);
    },
  );

  test(
    'old Save badges preserve lesson access without claiming verified practice or connection',
    () async {
      SharedPreferences.setMockInitialValues({
        'currentLevel': 3,
        'completedLevels': ['0', '1', '2', 'bad', '99'],
        'robotConnected': true,
      });
      final state = AppState();
      addTearDown(state.dispose);
      // A live connection arriving during loading must not be replaced by disk data.
      await state.ready;
      expect(state.isRobotConnected, isFalse);
      expect(state.progressPercentage, 0);
      expect(state.currentLevel, 3);
      expect(state.isLevelUnlocked(3), isTrue);
      expect(state.isLevelUnlocked(4), isFalse);
      state.updateConnectionStatus(true, robotName: 'Robot');
      final result = await ProgramExecutor(
        robot,
      ).run([block(BlockType.moveForward)]);
      await state.recordPracticeRun(1, result);
      final restored = AppState();
      addTearDown(restored.dispose);
      await restored.ready;
      expect(restored.isRobotConnected, isFalse);
      expect(restored.isLevelUnlocked(3), isTrue);
      expect(restored.completedLevels, {1});
    },
  );

  test(
    'skipped branches, empty conditions and zero parameters cannot earn checks',
    () async {
      robot.distance = 100;
      final executor = ProgramExecutor(
        robot,
        autoDuration: const Duration(milliseconds: 1),
      );
      final skipped = await executor.run([
        block(BlockType.ifDistance, children: [block(BlockType.autoNavigate)]),
      ]);
      for (var level = 1; level <= 5; level++) {
        expect(PracticeProgress.qualifies(level, skipped), isFalse);
      }
      final zero = await executor.run([
        block(BlockType.moveForward, parameters: {'distance': 0}),
        block(BlockType.wait, parameters: {'time': 0}),
        block(BlockType.ifDistance),
      ]);
      expect(PracticeProgress.qualifies(1, zero), isFalse);
      expect(PracticeProgress.qualifies(2, zero), isFalse);
      expect(PracticeProgress.qualifies(3, zero), isFalse);
    },
  );

  test(
    'all five criteria reflect executed actions and total progress is exactly 100 percent',
    () async {
      final state = AppState();
      addTearDown(state.dispose);
      final result =
          await ProgramExecutor(
            robot,
            autoDuration: const Duration(milliseconds: 1),
          ).run([
            block(BlockType.moveForward),
            block(BlockType.wait, parameters: {'time': 1}),
            block(BlockType.ifDistance, children: [block(BlockType.stop)]),
            block(BlockType.autoNavigate),
          ]);
      for (var level = 1; level <= 5; level++) {
        expect(PracticeProgress.qualifies(level, result), isTrue);
        expect(await state.recordPracticeRun(level, result), isTrue);
      }
      expect(state.completedLevels, {1, 2, 3, 4, 5});
      expect(state.progressPercentage, 1);
      expect(state.isLevelUnlocked(6), isFalse);
      expect(() => result.executedTypes.clear(), throwsUnsupportedError);
    },
  );

  test(
    'failed final STOP, disconnected and cancelled runs never earn a check',
    () async {
      robot.onCommand = (command) async => command != 'STOP';
      final failed = await ProgramExecutor(
        robot,
      ).run([block(BlockType.moveForward)]);
      expect(failed.status, ProgramStatus.failed);
      expect(PracticeProgress.qualifies(1, failed), isFalse);
      robot.connected = false;
      final disconnected = await ProgramExecutor(
        robot,
      ).run([block(BlockType.moveForward)]);
      expect(PracticeProgress.qualifies(1, disconnected), isFalse);
      robot.connected = true;
      robot.onCommand = (_) async => true;
      final executor = ProgramExecutor(robot);
      final run = executor.run([
        block(BlockType.moveForward),
        block(BlockType.wait, parameters: {'time': 60000}),
      ]);
      await Future<void>.delayed(Duration.zero);
      await executor.cancel();
      expect(PracticeProgress.qualifies(1, await run), isFalse);
    },
  );

  for (final throws in [false, true]) {
    test(
      'storage failure (throws=$throws) cannot unlock a lesson or poison reload',
      () async {
        final platform = FailingPreferences()..throwOnWrite = throws;
        SharedPreferencesStorePlatform.instance = platform;
        final state = AppState();
        addTearDown(state.dispose);
        final result = await ProgramExecutor(
          robot,
        ).run([block(BlockType.moveForward)]);
        await expectLater(state.recordPracticeRun(1, result), throwsStateError);
        expect(state.progressPercentage, 0);
        expect(state.isLevelUnlocked(2), isFalse);
        expect(state.storageError, isNotNull);
        final restored = AppState();
        addTearDown(restored.dispose);
        await restored.ready;
        expect(restored.progressPercentage, 0);
        platform.fail = false;
        expect(await state.recordPracticeRun(1, result), isTrue);
        expect(state.storageError, isNull);
      },
    );
  }

  test('unsupported progress data is reported and never overwritten', () async {
    final raw = jsonEncode({'version': 99});
    SharedPreferences.setMockInitialValues({AppState.storageKey: raw});
    final state = AppState();
    addTearDown(state.dispose);
    await state.ready;
    final result = await ProgramExecutor(
      robot,
    ).run([block(BlockType.moveForward)]);
    await expectLater(state.recordPracticeRun(1, result), throwsStateError);
    expect(state.storageError, isNotNull);
    expect(
      (await SharedPreferences.getInstance()).getString(AppState.storageKey),
      raw,
    );
  });
}
