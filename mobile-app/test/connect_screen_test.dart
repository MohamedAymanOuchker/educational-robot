import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/screens/connect_screen.dart';
import 'package:robocode/services/robot_client.dart';
import 'package:robocode/services/robot_connection.dart';

class FakeConnection implements RobotConnection {
  final statuses = StreamController<ConnectionStatus>.broadcast();
  late final results = StreamController<List<ScanResult>>.broadcast(
    onCancel: () {
      stops++;
    },
  );
  int scans = 0;
  int stops = 0;
  bool success = true;
  @override
  ConnectionStatus status = ConnectionStatus.disconnected;
  @override
  BluetoothDevice? connectedBluetoothDevice;
  @override
  Stream<ConnectionStatus> get connectionStatus => statuses.stream;
  @override
  Stream<List<ScanResult>> scanForDevices() {
    scans++;
    return results.stream;
  }

  @override
  Future<void> stopScan() async {
    stops++;
  }

  @override
  Future<bool> connectBluetooth(BluetoothDevice device) async {
    status = success ? ConnectionStatus.connected : ConnectionStatus.error;
    connectedBluetoothDevice = success ? device : null;
    statuses.add(status);
    return success;
  }

  @override
  Future<void> disconnect() async {
    status = ConnectionStatus.disconnected;
    connectedBluetoothDevice = null;
    statuses.add(status);
  }

  Future<void> dispose() async {
    await results.close();
    await statuses.close();
  }
}

ScanResult robotResult() => ScanResult(
  device: BluetoothDevice.fromId('AA:BB:CC:DD:EE:FF'),
  advertisementData: AdvertisementData(
    advName: 'E-Bug ESP32',
    txPowerLevel: null,
    appearance: null,
    connectable: true,
    manufacturerData: {},
    serviceData: {},
    serviceUuids: [],
  ),
  rssi: -55,
  timeStamp: DateTime(2026),
);

Future<void> settleEvents(WidgetTester tester) async {
  // Drain stream futures initialized outside the widget test's fake clock.
  for (var i = 0; i < 5; i++) {
    await tester.pump();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
  }
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late FakeConnection connection;
  setUp(() => connection = FakeConnection());
  tearDown(() => connection.dispose());
  Future<void> show(WidgetTester tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConnectScreen(connection: connection)),
      ),
    );
  }

  testWidgets(
    'only BLE controls remain and errors are visible rather than empty scans',
    (tester) async {
      await show(tester);
      expect(find.text('WiFi'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Scan for robots'));
      await settleEvents(tester);
      connection.results.addError(StateError('Permission denied'));
      await settleEvents(tester);
      expect(find.textContaining('Permission denied'), findsOneWidget);
      expect(find.textContaining('No matching robots found'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(connection.statuses.hasListener, isFalse);
      expect(connection.results.hasListener, isFalse);
    },
  );

  testWidgets(
    'scan cancel and disposal remove listeners and tolerate late events',
    (tester) async {
      await show(tester);
      await tester.tap(find.text('Scan for robots'));
      await settleEvents(tester);
      await tester.tap(find.text('Stop scan'));
      await settleEvents(tester);
      expect(connection.results.hasListener, isFalse);
      await tester.tap(find.text('Scan for robots'));
      await settleEvents(tester);
      expect(connection.scans, 2);
      await tester.pumpWidget(const SizedBox());
      connection.results.add([robotResult()]);
      connection.statuses.add(ConnectionStatus.error);
      await settleEvents(tester);
      expect(connection.results.hasListener, isFalse);
      expect(connection.stops, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a listed robot can connect and disconnect at phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await show(tester);
    await tester.tap(find.text('Scan for robots'));
    await settleEvents(tester);
    connection.results.add([robotResult()]);
    await settleEvents(tester);
    await tester.tap(find.text('Connect'));
    await settleEvents(tester);
    expect(find.text('Robot connected'), findsOneWidget);
    expect(connection.results.hasListener, isFalse);
    await tester.tap(find.text('Disconnect'));
    await settleEvents(tester);
    expect(find.text('Robot disconnected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
