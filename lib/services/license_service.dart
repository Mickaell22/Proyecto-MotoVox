import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class LicenseService {
  static const _keyInstallDate = 'install_date';
  static const _keyUnlocked = 'license_unlocked';
  static const int trialDays = 10;

  static Future<void> registerInstallIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyInstallDate) == null) {
      prefs.setString(_keyInstallDate, DateTime.now().toIso8601String());
    }
  }

  static Future<bool> isExpired() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_keyUnlocked) == true) return false;

    final raw = prefs.getString(_keyInstallDate);
    if (raw == null) return false;

    final installDate = DateTime.parse(raw);
    final diff = DateTime.now().difference(installDate).inDays;
    return diff >= trialDays;
  }

  static Future<int> daysRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyUnlocked) == true) return -1;

    final raw = prefs.getString(_keyInstallDate);
    if (raw == null) return trialDays;

    final installDate = DateTime.parse(raw);
    final used = DateTime.now().difference(installDate).inDays;
    return (trialDays - used).clamp(0, trialDays);
  }

  static Future<bool> tryUnlock(String code) async {
    if (code != adminCode) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUnlocked, true);
    return true;
  }

  static Future<bool> isUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUnlocked) ?? false;
  }
}
