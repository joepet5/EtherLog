import 'package:shared_preferences/shared_preferences.dart';
import '../models/doctor_profile.dart';

class ProfileStorage {
  static const _nameKey = 'doctor_name';
  static const _qualificationsKey = 'doctor_qualifications';
  static const _designationKey = 'doctor_designation';
  static const _hospitalKey = 'doctor_hospital';
  static const _registrationKey = 'doctor_registration';
  static const _accentKey = 'theme_accent';
  static const _idleAnimKey = 'idle_animation_enabled';
  static const _bonusKey = 'profile_bonus_points';
  static const _bunnyKey = 'bunny_enabled';
  static const _darkKey = 'dark_mode';
  static const _themeKey = 'app_theme_key';
  static const _hapticsKey = 'haptics_enabled';
  static const _glassmorphismKey = 'glassmorphism_enabled';
  static const _transitionKey = 'page_transition_style';
  static const _dobKey = 'doctor_dob';
  static const _zenModeKey = 'zen_mode_enabled';
  static const _verificationEnabledKey = 'clinical_verification_enabled';

  static Future<DoctorProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? dob;
    final dobRaw = prefs.getString(_dobKey);
    if (dobRaw != null && dobRaw.isNotEmpty) {
      dob = DateTime.tryParse(dobRaw);
    }
    return DoctorProfile(
      name: prefs.getString(_nameKey) ?? '',
      qualifications: prefs.getString(_qualificationsKey) ?? '',
      designation: prefs.getString(_designationKey) ?? '',
      hospital: prefs.getString(_hospitalKey) ?? '',
      registrationNumber: prefs.getString(_registrationKey),
      accentKey: prefs.getString(_accentKey) ?? 'default',
      zenMode: prefs.getBool(_zenModeKey) ?? false,
      dateOfBirth: dob,
      clinicalVerificationEnabled:
          prefs.getBool(_verificationEnabledKey) ?? false,
    );
  }

  static Future<void> saveProfile(DoctorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, profile.name);
    await prefs.setString(_qualificationsKey, profile.qualifications);
    await prefs.setString(_designationKey, profile.designation);
    await prefs.setString(_hospitalKey, profile.hospital);
    if (profile.registrationNumber != null) {
      await prefs.setString(_registrationKey, profile.registrationNumber!);
    }
    await prefs.setString(_accentKey, profile.accentKey);
    await prefs.setBool(_zenModeKey, profile.zenMode);
    await prefs.setBool(
        _verificationEnabledKey, profile.clinicalVerificationEnabled);
    if (profile.dateOfBirth != null) {
      await prefs.setString(_dobKey, profile.dateOfBirth!.toIso8601String());
    } else {
      await prefs.remove(_dobKey);
    }

    final hasCore =
        profile.name.trim().isNotEmpty && profile.hospital.trim().isNotEmpty;
    if (hasCore) {
      await awardProfileCompletionBonusIfNeeded();
    }
  }

  static Future<int> getProfileBonusPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bonusKey) ?? 0;
  }

  static Future<void> awardProfileCompletionBonusIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getInt(_bonusKey) ?? 0;
    if (already > 0) return;
    await prefs.setInt(_bonusKey, 10);
  }

  static Future<bool> isCelebrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bunnyKey) ?? true;
  }

  static Future<void> setCelebrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bunnyKey, value);
  }

  static Future<bool> isBunnyEnabled() => isCelebrationEnabled();
  static Future<void> setBunnyEnabled(bool value) =>
      setCelebrationEnabled(value);

  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkKey) ?? true;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, value);
    // Keep theme key in sync
    await prefs.setString(_themeKey, value ? 'dark' : 'light');
  }

  /// App appearance theme: dark | light | serenity | night_shift
  static Future<String> getThemeKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    if (stored != null && stored.isNotEmpty) {
      if (stored == 'executive') return 'dark';
      return stored;
    }
    // Migrate from legacy dark_mode bool
    final dark = prefs.getBool(_darkKey) ?? true;
    return dark ? 'dark' : 'light';
  }

  static Future<void> setThemeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveKey = key == 'executive' ? 'dark' : key;
    await prefs.setString(_themeKey, effectiveKey);
    // Keep legacy flag in sync for older call sites
    await prefs.setBool(_darkKey, effectiveKey == 'dark');
  }

  static Future<bool> isHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticsKey) ?? true;
  }

  static Future<void> setHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, value);
  }

  static Future<String> getTransitionStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_transitionKey) ?? 'none';
  }

  static Future<void> setTransitionStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transitionKey, style);
  }

  static const _languageKey = 'app_language';

  /// ISO language code: en, es, fr, de, pt, zh, ar, hi, ru, ja, ko, it, tr, id, ta
  static Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  static Future<void> setLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }

  static Future<bool> getGlassmorphism() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_glassmorphismKey) ?? true;
  }

  static Future<void> setGlassmorphism(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_glassmorphismKey, enabled);
  }

  static Future<bool> isClinicalVerificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_verificationEnabledKey) ?? false;
  }

  static Future<void> setClinicalVerificationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_verificationEnabledKey, value);
  }
}
