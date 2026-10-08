import 'dart:async';

/// Owns one finite scan, including cancellation during permission/startup work.
class DeviceDiscovery<T> {
  DeviceDiscovery({
    required this.prepare,
    required this.start,
    required this.stop,
    required this.results,
    this.duration = const Duration(seconds: 10),
  });
  final Future<void> Function() prepare;
  final Future<void> Function() start;
  final Future<void> Function() stop;
  final Stream<List<T>> Function() results;
  final Duration duration;
  _Scan<T>? _active;

  Stream<List<T>> scan() {
    late final _Scan<T> session;
    final controller = StreamController<List<T>>(
      onListen: () {
        if (_active != null) {
          session.controller.addError(StateError('A scan is already running.'));
          unawaited(session.controller.close());
          return;
        }
        _active = session;
        unawaited(_begin(session));
      },
      onCancel: () => _finish(session),
    );
    session = _Scan(controller);
    return controller.stream;
  }

  Future<void> _begin(_Scan<T> session) async {
    try {
      await prepare();
      if (session.cancelled) return;
      session.subscription = results().listen(
        (items) {
          if (!session.cancelled) session.controller.add(items);
        },
        onError: (Object error, StackTrace stack) {
          if (!session.cancelled) session.controller.addError(error, stack);
          unawaited(_finish(session));
        },
        onDone: () => unawaited(_finish(session)),
      );
      session.starting = start();
      await session.starting;
      if (session.cancelled) return;
      session.timer = Timer(duration, () => unawaited(_finish(session)));
    } catch (error, stack) {
      if (!session.cancelled) session.controller.addError(error, stack);
      await _finish(session);
    }
  }

  Future<void> stopScanning() async {
    final session = _active;
    if (session != null) await _finish(session);
  }

  Future<void> _finish(_Scan<T> session) {
    if (session.finishing != null) return session.finishing!;
    session.cancelled = true;
    session.timer?.cancel();
    return session.finishing = () async {
      await session.subscription?.cancel();
      if (session.starting != null) {
        try {
          await session.starting;
        } catch (_) {
          /* Still attempt cleanup. */
        }
        try {
          await stop();
        } catch (error, stack) {
          if (session.controller.hasListener)
            session.controller.addError(error, stack);
        }
      }
      if (identical(_active, session)) _active = null;
      // Do not await close from onCancel: that would await its own callback.
      unawaited(session.controller.close());
    }();
  }
}

class _Scan<T> {
  _Scan(this.controller);
  final StreamController<List<T>> controller;
  StreamSubscription<List<T>>? subscription;
  Future<void>? starting;
  Future<void>? finishing;
  Timer? timer;
  bool cancelled = false;
}
