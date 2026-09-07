import 'package:shared_preferences/shared_preferences.dart';

abstract interface class DemoStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// Device-local demo state only; never a financial/security source of truth.
class PreferencesDemoStore implements DemoStore {
  final _preferences = SharedPreferencesAsync();
  static const key = 'tagnar.merchant-demo.v1';
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

class MemoryDemoStore implements DemoStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
