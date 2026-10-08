import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/screens/sensors_screen.dart';
import 'support/fake_robot_client.dart';

Future<void> settleEvents(WidgetTester tester) async {
  // Drain stream futures initialized outside the widget test's fake clock.
  for (var i = 0; i < 5; i++) {
    await tester.pump();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
  }
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late FakeRobotClient robot;
  late DateTime now;
  setUp(() {
    robot = FakeRobotClient();
    now = DateTime(2026);
  });
  tearDown(() => robot.dispose());
  Future<void> show(WidgetTester tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorsScreen(robot: robot, now: () => now),
        ),
      ),
    );
  }

  String? reading(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data;
  final sample = <String, dynamic>{
    'distance': 20.0,
    'distance_valid': true,
    'distance_age_ms': 100,
    'battery': 75.0,
    'temperature': 28.0,
    'heading': 45.0,
  };

  testWidgets(
    'there are no fabricated starting values or pretend monitoring controls',
    (tester) async {
      await show(tester);
      expect(reading(tester, 'distance-reading'), 'Unavailable');
      expect(reading(tester, 'battery-reading'), 'Unavailable');
      expect(find.text('Start'), findsNothing);
      expect(find.text('Stop'), findsNothing);
      expect(find.text('Waiting for telemetry'), findsOneWidget);
      expect(robot.calls, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'invalid and aged distance cannot display an old valid distance',
    (tester) async {
      await show(tester);
      robot.sensors.add(sample);
      await settleEvents(tester);
      expect(reading(tester, 'distance-reading'), '20.0 cm');
      now = now.add(const Duration(milliseconds: 401));
      await tester.pump(const Duration(milliseconds: 250));
      expect(reading(tester, 'distance-reading'), 'Unavailable');
      expect(reading(tester, 'battery-reading'), '75.0 %');
      robot.sensors.add({...sample, 'distance': null, 'distance_valid': false});
      await settleEvents(tester);
      expect(reading(tester, 'distance-reading'), 'Unavailable');
      now = now.add(const Duration(milliseconds: 501));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Readings are stale'), findsOneWidget);
      expect(reading(tester, 'battery-reading'), 'Unavailable');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'missing or invalid fields and disconnect clear displayed values',
    (tester) async {
      await show(tester);
      robot.sensors.add(sample);
      await settleEvents(tester);
      robot.sensors.add({
        'distance': 10,
        'distance_valid': true,
        'distance_age_ms': 0,
        'battery': 150,
      });
      await settleEvents(tester);
      expect(reading(tester, 'distance-reading'), '10.0 cm');
      expect(reading(tester, 'battery-reading'), 'Unavailable');
      robot.disconnect();
      await settleEvents(tester);
      expect(reading(tester, 'distance-reading'), 'Unavailable');
      expect(find.text('Robot disconnected'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      robot.sensors.add(sample);
      await tester.pump(const Duration(seconds: 2));
      expect(robot.sensors.hasListener, isFalse);
      expect(robot.statuses.hasListener, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
