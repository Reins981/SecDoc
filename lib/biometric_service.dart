import 'package:shared_preferences/shared_preferences.dart';

class BiometricsService {
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  static Future<bool> getBiometricsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsEnabledKey) ?? false;
  }

  static Future<void> setBiometricsEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, enabled);
  }
}
