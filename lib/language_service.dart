import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'German';

  static Future<String> getLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'German';
  }

  static Future<void> setLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }
}
