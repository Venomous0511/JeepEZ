import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _maintenanceModeKey = 'maintenance_mode';

  // Get maintenance mode status
  static Future<bool> getMaintenanceMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_maintenanceModeKey) ?? false;
  }

  // Set maintenance mode status
  static Future<void> setMaintenanceMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_maintenanceModeKey, value);
  }

  // Stream to listen for maintenance mode changes
  static Stream<bool> watchMaintenanceMode() async* {
    while (true) {
      yield await getMaintenanceMode();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}