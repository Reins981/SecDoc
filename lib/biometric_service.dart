import 'package:shared_preferences/shared_preferences.dart';

/// Class handling biometric keys
class BiometricsService {
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  /// Get the biometrics enabled key for the user from the phone securely
  static Future<bool> getBiometricsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsEnabledKey) ?? false;
  }

  /// Set the biometrics enabled key for the user
  static Future<void> setBiometricsEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, enabled);
  }
}
