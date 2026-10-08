import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class FailingPreferences extends InMemorySharedPreferencesStore {
  FailingPreferences() : super.empty();
  bool fail = true;
  bool throwOnWrite = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (fail) {
      if (throwOnWrite) throw StateError('Disk write failed');
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}
