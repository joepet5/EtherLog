import 'package:shared_preferences/shared_preferences.dart';

class AliasStorage {
  static const _aliasKey = 'leaderboard_alias';
  static const _iconKey = 'leaderboard_icon';
  static const _optInKey = 'leaderboard_opt_in';

  static Future<String?> getAlias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_aliasKey);
  }

  static Future<String?> getIcon() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_iconKey);
  }

  static Future<void> setAlias(String alias,
      {String? icon, bool optIn = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aliasKey, alias);
    if (icon != null) {
      await prefs.setString(_iconKey, icon);
    }
    await prefs.setBool(_optInKey, optIn);
  }

  static Future<void> setOptIn(bool optedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optInKey, optedIn);
  }

  static Future<bool> hasOptedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_optInKey) ?? false;
  }
}
