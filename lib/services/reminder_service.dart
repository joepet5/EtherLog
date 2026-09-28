import 'package:shared_preferences/shared_preferences.dart';
import 'case_storage.dart';
import 'template_storage.dart';

class ReminderInfo {
  final bool showInactivity;
  final int daysSinceLastCase;
  final int thresholdDays;
  final bool showIncompleteDraft;
  final DateTime? draftSavedAt;
  final DateTime? lastCaseDate;
  final bool suppressedByQuietHours;

  const ReminderInfo({
    required this.showInactivity,
    required this.daysSinceLastCase,
    required this.thresholdDays,
    required this.showIncompleteDraft,
    this.draftSavedAt,
    this.lastCaseDate,
    this.suppressedByQuietHours = false,
  });

  bool get hasAny => showInactivity || showIncompleteDraft;
}

class ReminderService {
  static const _thresholdKey = 'reminder_inactivity_days';
  static const _enabledKey = 'reminder_enabled';
  static const _quietEnabledKey = 'quiet_hours_enabled';
  static const _quietStartKey = 'quiet_hours_start'; // hour 0-23
  static const _quietEndKey = 'quiet_hours_end';

  static Future<int> getThresholdDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_thresholdKey) ?? 7;
  }

  static Future<void> setThresholdDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_thresholdKey, days);
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Quiet hours: default 22:00 – 07:00 (overnight).
  static Future<bool> isQuietHoursEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quietEnabledKey) ?? false;
  }

  static Future<void> setQuietHoursEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quietEnabledKey, value);
  }

  static Future<int> quietStartHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_quietStartKey) ?? 22;
  }

  static Future<int> quietEndHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_quietEndKey) ?? 7;
  }

  static Future<void> setQuietStartHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quietStartKey, hour.clamp(0, 23));
  }

  static Future<void> setQuietEndHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quietEndKey, hour.clamp(0, 23));
  }

  /// True if current local time falls inside quiet window (supports overnight range).
  static bool isInQuietHoursNow({
    required bool enabled,
    required int startHour,
    required int endHour,
    DateTime? now,
  }) {
    if (!enabled) return false;
    final n = now ?? DateTime.now();
    final h = n.hour;
    if (startHour == endHour) return true; // 24h quiet
    if (startHour < endHour) {
      // e.g. 09–17
      return h >= startHour && h < endHour;
    }
    // Overnight e.g. 22–7
    return h >= startHour || h < endHour;
  }

  static Future<DateTime?> lastCaseDate() async {
    final cases = await CaseStorage.getAllCases();
    if (cases.isEmpty) return null;
    cases.sort((a, b) => b.date.compareTo(a.date));
    return cases.first.date;
  }

  static Future<ReminderInfo> evaluate() async {
    final enabled = await isEnabled();
    final threshold = await getThresholdDays();
    final last = await lastCaseDate();
    final draft = await TemplateStorage.getDraft();

    final quietOn = await isQuietHoursEnabled();
    final qStart = await quietStartHour();
    final qEnd = await quietEndHour();
    final inQuiet = isInQuietHoursNow(
      enabled: quietOn,
      startHour: qStart,
      endHour: qEnd,
    );

    int daysSince = 0;
    bool inactive = false;
    if (enabled && threshold > 0 && !inQuiet) {
      if (last != null) {
        final now = DateTime.now();
        if (threshold == 1) {
          final hoursSince = now.difference(last).inHours;
          daysSince = (hoursSince / 24).floor().clamp(1, 9999);
          inactive = hoursSince >= 24;
        } else {
          final lastDay = DateTime(last.year, last.month, last.day);
          final todayDay = DateTime(now.year, now.month, now.day);
          daysSince = todayDay.difference(lastDay).inDays;
          inactive = daysSince >= threshold;
        }
      }
    }

    DateTime? draftAt;
    if (draft != null && draft['savedAt'] != null) {
      draftAt = DateTime.tryParse(draft['savedAt'].toString());
    }

    return ReminderInfo(
      showInactivity: inactive,
      daysSinceLastCase: daysSince,
      thresholdDays: threshold,
      // Drafts still show — user may want to finish; only inactivity is muted
      showIncompleteDraft: draft != null,
      draftSavedAt: draftAt,
      lastCaseDate: last,
      suppressedByQuietHours: inQuiet && enabled,
    );
  }
}