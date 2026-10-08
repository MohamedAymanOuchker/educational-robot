import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'practice_progress.dart';
import 'program_executor.dart';

class AppState extends ChangeNotifier {
  static const storageKey = 'practiceProgress.v1';
  late final Future<void> ready;
  Future<void> _writes = Future<void>.value();
  int _currentLevel = 1;
  int _legacyUnlockedThrough = 1;
  Set<int> _completedLevels = {};
  bool _isRobotConnected = false;
  String _connectedRobotName = '';
  bool _disposed = false;
  bool _loaded = false;
  String? _storageError;
  bool _readFailed = false;

  AppState() {
    ready = _load();
  }

  int get currentLevel => _currentLevel;
  Set<int> get completedLevels => Set.unmodifiable(_completedLevels);
  bool get isRobotConnected => _isRobotConnected;
  String get connectedRobotName => _connectedRobotName;
  bool get isLoaded => _loaded;
  String? get storageError => _storageError;
  double get progressPercentage => _completedLevels.length / 5.0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final data = jsonDecode(raw);
        if (data is! Map<String, dynamic> ||
            data['version'] != 1 ||
            data['currentLevel'] is! int ||
            !_validLevel(data['currentLevel']) ||
            data['legacyUnlockedThrough'] is! int ||
            !_validLevel(data['legacyUnlockedThrough']) ||
            data['completedLevels'] is! List ||
            !(data['completedLevels'] as List).every(
              (v) => v is int && _validLevel(v),
            )) {
          throw const FormatException(
            'Unsupported or damaged practice progress.',
          );
        }
        _completedLevels = (data['completedLevels'] as List)
            .cast<int>()
            .toSet();
        _legacyUnlockedThrough = data['legacyUnlockedThrough'];
        final selected = data['currentLevel'] as int;
        _currentLevel = isLevelUnlocked(selected) ? selected : 1;
      } else {
        // Old Save buttons only checked block presence. Retain access to lessons,
        // but do not describe those badges as successfully executed practice.
        final legacy = prefs.getStringList('completedLevels') ?? [];
        for (final value in legacy) {
          final level = int.tryParse(value);
          if (level != null && _validLevel(level)) {
            final unlocked = (level + 1).clamp(1, 5);
            if (unlocked > _legacyUnlockedThrough)
              _legacyUnlockedThrough = unlocked;
          }
        }
        final selected = prefs.getInt('currentLevel') ?? 1;
        if (_validLevel(selected)) {
          _currentLevel = selected;
          if (selected > _legacyUnlockedThrough)
            _legacyUnlockedThrough = selected;
        }
      }
    } catch (_) {
      _readFailed = true;
      _storageError =
          'Saved practice progress could not be read. Existing data has been kept.';
    }
    _loaded = true;
    _notify();
  }

  static bool _validLevel(int level) => level >= 1 && level <= 5;
  bool isLevelCompleted(int level) => _completedLevels.contains(level);
  bool isLevelUnlocked(int level) =>
      _validLevel(level) &&
      (level <= _legacyUnlockedThrough || _completedLevels.contains(level - 1));

  void setCurrentLevel(int level) {
    if (!_loaded || !isLevelUnlocked(level)) return;
    _currentLevel = level;
    _notify();
    unawaited(
      _enqueue(() => _persist(_completedLevels)).catchError((Object _) {}),
    );
  }

  /// Returns true only for a newly saved practice check. No auto-advance: the
  /// editor's lesson and the executed lesson remain the same until selected.
  Future<bool> recordPracticeRun(int level, ProgramResult result) =>
      _enqueue(() async {
        if (!isLevelUnlocked(level) ||
            !PracticeProgress.qualifies(level, result) ||
            _completedLevels.contains(level))
          return false;
        final completed = {..._completedLevels, level};
        await _persist(completed);
        _completedLevels = completed;
        _notify();
        return true;
      });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writes.then((_) async {
      await ready;
      try {
        if (_readFailed) throw StateError(_storageError!);
        final value = await operation();
        _storageError = null;
        _notify();
        return value;
      } catch (error) {
        _storageError ??= 'Practice progress could not be saved. Try again.';
        _notify();
        rethrow;
      }
    });
    _writes = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> _persist(Set<int> completed) async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = await prefs.setString(
      storageKey,
      jsonEncode({
        'version': 1,
        'currentLevel': _currentLevel,
        'legacyUnlockedThrough': _legacyUnlockedThrough,
        'completedLevels': completed.toList()..sort(),
      }),
    );
    if (!accepted) {
      await prefs.reload();
      throw StateError('Storage did not accept practice progress.');
    }
  }

  // Connection state is live only and never restored from preferences.
  void updateConnectionStatus(bool connected, {String robotName = ''}) {
    _isRobotConnected = connected;
    _connectedRobotName = connected ? robotName : '';
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
