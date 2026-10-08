import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/screens/run_screen.dart';
import 'package:robocode/widgets/block_editor/block_types.dart';

import 'support/fake_robot_client.dart';

Block block(BlockType type, {Map<String, dynamic>? parameters}) => Block(
  type: type,
  position: Offset.zero,
  color: Colors.blue,
  parameters: parameters ?? {},
);

void main() {
  late FakeRobotClient robot;
  setUp(() => robot = FakeRobotClient());
  tearDown(() => robot.dispose());

  testWidgets('a failed write remains a failure in the UI', (tester) async {
    robot.onCommand = (command) async => command != 'F100';
    await tester.pumpWidget(
      MaterialApp(
        home: RunScreen(
          blocks: [block(BlockType.moveForward), block(BlockType.turnRight)],
          robot: robot,
        ),
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final status = tester
        .widget<Text>(find.byKey(const Key('execution-status')))
        .data!;
    expect(status, contains('failed'));
    expect(status, isNot(contains('successfully')));
    expect(robot.calls, ['F100', 'STOP']);
  });

  testWidgets('leaving a running route confirms STOP before leaving', (
    tester,
  ) async {
    final stop = Completer<bool>();
    robot.onCommand = (command) =>
        command == 'STOP' ? stop.future : Future.value(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RunScreen(
                    blocks: [
                      block(BlockType.wait, parameters: {'time': 60000}),
                      block(BlockType.moveForward),
                    ],
                    robot: robot,
                  ),
                ),
              ),
              child: const Text('Open program'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open program'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    expect(robot.calls, ['STOP']);
    expect(find.byType(RunScreen), findsOneWidget);
    stop.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Open program'), findsOneWidget);
    expect(robot.calls, ['STOP']);
    expect(robot.statuses.hasListener, isFalse);
    expect(robot.responses.hasListener, isFalse);
  });

  testWidgets('backgrounding cancels waits and cannot resume movement', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RunScreen(
          blocks: [
            block(BlockType.wait, parameters: {'time': 60000}),
            block(BlockType.moveForward),
          ],
          robot: robot,
        ),
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 61));
    expect(robot.calls, ['STOP']);
    expect(
      tester.widget<Text>(find.byKey(const Key('execution-status'))).data,
      contains('stopped'),
    );
  });

  testWidgets(
    'forced route disposal cancels execution and owns subscriptions',
    (tester) async {
      robot.onCommand = (command) =>
          command == 'F100' ? Completer<bool>().future : Future.value(true);
      await tester.pumpWidget(
        MaterialApp(
          home: RunScreen(
            blocks: [block(BlockType.moveForward), block(BlockType.turnRight)],
            robot: robot,
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      robot.responses.add('Late command response');
      robot.disconnect();
      await tester.pump();
      expect(robot.calls, ['F100', 'STOP']);
      expect(robot.statuses.hasListener, isFalse);
      expect(robot.responses.hasListener, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
