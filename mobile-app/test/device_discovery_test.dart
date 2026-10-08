import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:robocode/services/device_discovery.dart';

void main() {
  test(
    'permission failures are visible and do not start native scanning',
    () async {
      var starts = 0;
      final scanner = DeviceDiscovery<int>(
        prepare: () async => throw StateError('Permission denied'),
        start: () async {
          starts++;
        },
        stop: () async {},
        results: () => const Stream.empty(),
      );
      await expectLater(scanner.scan().toList(), throwsStateError);
      expect(starts, 0);
    },
  );

  test(
    'cancelling a pending permission request never starts a late scan',
    () async {
      final permission = Completer<void>();
      var starts = 0;
      final scanner = DeviceDiscovery<int>(
        prepare: () => permission.future,
        start: () async {
          starts++;
        },
        stop: () async {},
        results: () => const Stream.empty(),
      );
      final subscription = scanner.scan().listen((_) {});
      await subscription.cancel();
      permission.complete();
      await Future<void>.delayed(Duration.zero);
      expect(starts, 0);
    },
  );

  test(
    'cancelling during native startup waits then stops exactly once',
    () async {
      final started = Completer<void>();
      final native = StreamController<List<int>>.broadcast();
      var stops = 0;
      final scanner = DeviceDiscovery<int>(
        prepare: () async {},
        start: () => started.future,
        stop: () async {
          stops++;
        },
        results: () => native.stream,
      );
      final received = <List<int>>[];
      final subscription = scanner.scan().listen(received.add);
      await Future<void>.delayed(Duration.zero);
      final cancellation = subscription.cancel();
      native.add([9]);
      started.complete();
      await cancellation;
      expect(stops, 1);
      expect(received, isEmpty);
      expect(native.hasListener, isFalse);
      await native.close();
    },
  );

  test(
    'timeout closes discovery, releases the listener and permits a fresh scan',
    () async {
      final native = StreamController<List<int>>.broadcast();
      var stops = 0;
      final scanner = DeviceDiscovery<int>(
        prepare: () async {},
        start: () async {},
        stop: () async {
          stops++;
        },
        results: () => native.stream,
        duration: const Duration(milliseconds: 5),
      );
      final first = scanner.scan().toList();
      await Future<void>.delayed(Duration.zero);
      native.add([1, 2]);
      expect(await first, [
        [1, 2],
      ]);
      expect(native.hasListener, isFalse);
      expect(await scanner.scan().toList(), isEmpty);
      expect(stops, 2);
      await native.close();
    },
  );

  test('native scan error propagates and cleans up before retry', () async {
    final native = StreamController<List<int>>.broadcast();
    var stops = 0;
    final scanner = DeviceDiscovery<int>(
      prepare: () async {},
      start: () async {},
      stop: () async {
        stops++;
      },
      results: () => native.stream,
    );
    final errors = <Object>[];
    final done = Completer<void>();
    scanner.scan().listen((_) {}, onError: errors.add, onDone: done.complete);
    await Future<void>.delayed(Duration.zero);
    native.addError(StateError('Adapter off'));
    await done.future;
    expect(errors.single, isStateError);
    expect(stops, 1);
    expect(native.hasListener, isFalse);
    await native.close();
  });

  test('a second scan cannot replace or cancel an active owner', () async {
    final native = StreamController<List<int>>.broadcast();
    var stops = 0;
    final scanner = DeviceDiscovery<int>(
      prepare: () async {},
      start: () async {},
      stop: () async {
        stops++;
      },
      results: () => native.stream,
    );
    final first = scanner.scan().listen((_) {});
    await expectLater(scanner.scan().toList(), throwsStateError);
    expect(stops, 0);
    await first.cancel();
    expect(stops, 1);
    await native.close();
  });
}
