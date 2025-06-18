import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _currentLevelKey = 'current_level';
  static const String _completedLevelsKey = 'completed_levels';

  static Future<void> saveCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentLevelKey, level);
  }

  static Future<int> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentLevelKey) ?? 1;
  }

  static Future<void> markLevelCompleted(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final completedLevels = prefs.getStringList(_completedLevelsKey) ?? [];
    if (!completedLevels.contains(level.toString())) {
      completedLevels.add(level.toString());
      await prefs.setStringList(_completedLevelsKey, completedLevels);
    }
  }

  static Future<List<int>> getCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final completedLevels = prefs.getStringList(_completedLevelsKey) ?? [];
    return completedLevels.map((e) => int.parse(e)).toList();
  }

  static Future<bool> isLevelCompleted(int level) async {
    final completedLevels = await getCompletedLevels();
    return completedLevels.contains(level);
  }

  static Future<bool> isLevelUnlocked(int level) async {
    if (level == 1) return true;
    return isLevelCompleted(level - 1);
  }
}
