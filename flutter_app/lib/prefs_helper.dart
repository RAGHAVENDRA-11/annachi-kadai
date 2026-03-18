import 'package:shared_preferences/shared_preferences.dart';

/// Membership prefs helper — reads/writes directly.
/// Multi-user safety is handled by restoring from DB on every login.
class PrefsHelper {

  static Future<void> init() async {} // no-op, kept for compatibility

  static Future<String> getString(String key, {String def = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? def;
  }

  static Future<int> getInt(String key, {int def = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? def;
  }

  static Future<double> getDouble(String key, {double def = 0.0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key) ?? def;
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  static Future<void> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  /// Call on logout to wipe membership/points from device
  static Future<void> clearCustomerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('membership_type');
    await prefs.remove('membership_card');
    await prefs.remove('membership_valid_until');
    await prefs.remove('membership_month');
    await prefs.remove('membership_monthly_spent');
    await prefs.remove('reward_points');
  }
}