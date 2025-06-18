import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static const String _currentLevelKey = 'currentLevel';
  static const String _completedLevelsKey = 'completedLevels';
  static const String _robotConnectionKey = 'robotConnected';

  int _currentLevel = 1;
  Set<int> _completedLevels = {
    0
  }; // Level 0 is completed by default to unlock level 1
  bool _isRobotConnected = false;
  String _connectedRobotName = '';

  AppState() {
    _loadState();
  }

  int get currentLevel => _currentLevel;
  Set<int> get completedLevels => Set.from(_completedLevels);
  bool get isRobotConnected => _isRobotConnected;
  String get connectedRobotName => _connectedRobotName;

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLevel = prefs.getInt(_currentLevelKey) ?? 1;

      // Load completed levels
      List<String>? completedStrings = prefs.getStringList(_completedLevelsKey);
      if (completedStrings != null) {
        _completedLevels = Set.from(completedStrings.map(int.parse));
      } else {
        _completedLevels = {
          0
        }; // Default: only level 0 completed (unlocks level 1)
      }

      // Load robot connection status (for UI state only)
      _isRobotConnected = prefs.getBool(_robotConnectionKey) ?? false;

      print(
          'AppState loaded - Current level: $_currentLevel, Completed levels: $_completedLevels, Robot connected: $_isRobotConnected');
      notifyListeners();
    } catch (e) {
      print('Error loading app state: $e');
      // Use defaults if loading fails
      _currentLevel = 1;
      _completedLevels = {0};
      _isRobotConnected = false;
      notifyListeners();
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentLevelKey, _currentLevel);
      await prefs.setStringList(
        _completedLevelsKey,
        _completedLevels.map((e) => e.toString()).toList(),
      );
      await prefs.setBool(_robotConnectionKey, _isRobotConnected);

      print(
          'AppState saved - Current level: $_currentLevel, Completed levels: $_completedLevels, Robot connected: $_isRobotConnected');
    } catch (e) {
      print('Error saving app state: $e');
    }
  }

  void setCurrentLevel(int level) {
    if (level >= 1 && level <= 5 && isLevelUnlocked(level)) {
      print('Setting current level to $level');
      _currentLevel = level;
      notifyListeners();
      _saveState();
    } else {
      print('Cannot set level $level - either out of range (1-5) or locked');
      print('Level $level unlocked: ${isLevelUnlocked(level)}');
    }
  }

  Future<void> completeLevel(int level) async {
    if (level >= 1 && level <= 5) {
      print('Completing level $level');
      bool wasAlreadyCompleted = _completedLevels.contains(level);
      _completedLevels.add(level);

      if (!wasAlreadyCompleted) {
        print(
            'Level $level newly completed! Next level ${level + 1} is now unlocked: ${isLevelUnlocked(level + 1)}');

        // Auto-advance to next level if available
        if (level < 5 && isLevelUnlocked(level + 1)) {
          _currentLevel = level + 1;
        }
      } else {
        print('Level $level was already completed');
      }

      notifyListeners();
      await _saveState();
    } else {
      print('Cannot complete level $level - out of range (1-5)');
    }
  }

  bool isLevelCompleted(int level) {
    bool completed = _completedLevels.contains(level);
    print('Level $level completed: $completed');
    return completed;
  }

  bool isLevelUnlocked(int level) {
    if (level == 1) {
      print('Level 1 is always unlocked');
      return true;
    }

    if (level < 1 || level > 5) {
      print('Level $level is out of range');
      return false;
    }

    bool previousCompleted = isLevelCompleted(level - 1);
    print(
        'Level $level unlocked: ${previousCompleted} (previous level ${level - 1} completed: ${previousCompleted})');
    return previousCompleted;
  }

  // Robot connection management
  void updateConnectionStatus(bool connected, {String robotName = ''}) {
    _isRobotConnected = connected;
    _connectedRobotName = robotName;
    print('Robot connection status updated: $connected, name: $robotName');
    notifyListeners();
    _saveState();
  }

  // Get progress percentage
  double get progressPercentage {
    return _completedLevels.where((level) => level >= 1 && level <= 5).length /
        5.0;
  }

  // Get next available level
  int get nextAvailableLevel {
    for (int level = 1; level <= 5; level++) {
      if (!isLevelCompleted(level) && isLevelUnlocked(level)) {
        return level;
      }
    }
    return 5; // All levels completed, return max level
  }

  // Get level completion status for UI
  Map<String, dynamic> getLevelInfo(int level) {
    return {
      'completed': isLevelCompleted(level),
      'unlocked': isLevelUnlocked(level),
      'current': level == _currentLevel,
      'available': !isLevelCompleted(level) && isLevelUnlocked(level),
    };
  }

  // Get overall completion stats
  Map<String, dynamic> get completionStats {
    int completedCount =
        _completedLevels.where((level) => level >= 1 && level <= 5).length;
    return {
      'completed': completedCount,
      'total': 5,
      'percentage': (completedCount / 5 * 100).round(),
      'nextLevel': nextAvailableLevel,
    };
  }

  // Debug methods for testing
  Future<void> resetProgress() async {
    print('Resetting all progress');
    _currentLevel = 1;
    _completedLevels = {0};
    _isRobotConnected = false;
    _connectedRobotName = '';
    notifyListeners();
    await _saveState();
  }

  Future<void> completeAllLevels() async {
    print('Completing all levels for testing');
    for (int i = 1; i <= 5; i++) {
      _completedLevels.add(i);
    }
    _currentLevel = 5;
    notifyListeners();
    await _saveState();
  }

  Future<void> unlockLevel(int level) async {
    if (level >= 2 && level <= 5) {
      print('Unlocking level $level by completing previous levels');
      for (int i = 1; i < level; i++) {
        _completedLevels.add(i);
      }
      notifyListeners();
      await _saveState();
    }
  }

  // Helper method to check if robot is required for current level
  bool get requiresRobotConnection {
    return _currentLevel >= 3; // Levels 3+ require sensor data
  }

  // Check if user can proceed with current setup
  bool get canExecutePrograms {
    if (_currentLevel <= 2) {
      return true; // First two levels can work without real robot
    }
    return _isRobotConnected; // Advanced levels need robot connection
  }
}
