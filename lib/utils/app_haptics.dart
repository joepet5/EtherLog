import 'package:flutter/services.dart';
import '../services/profile_storage.dart';

class AppHaptics {
  static bool enabled = true;

  static Future<void> init() async {
    try {
      enabled = await ProfileStorage.isHapticsEnabled();
    } catch (_) {
      enabled = true;
    }
  }

  static Future<void> setEnabled(bool value) async {
    enabled = value;
    try {
      await ProfileStorage.setHapticsEnabled(value);
    } catch (_) {}
  }

  static Future<void> light() async {
    if (!enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  static Future<void> selection() async {
    if (!enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  static Future<void> medium() async {
    if (!enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  static Future<void> heavy() async {
    if (!enabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}