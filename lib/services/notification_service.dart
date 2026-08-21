import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reminder_service.dart';
import 'profile_storage.dart';
import '../l10n/app_localizations.dart';

/// Local (device) notifications for logbook inactivity reminders.
/// Uses the current flutter_local_notifications named-parameter API.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _channelId = 'etherlog_reminders';
  static const int _notifId = 1001;
  static const _lastSentKey = 'reminder_notif_last_day';

  static Future<void> init() async {
    if (_ready) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {}
    try {
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Logbook reminders',
          description: 'Reminds you when no cases have been logged recently',
          importance: Importance.defaultImportance,
        ),
      );
    } catch (_) {}

    _ready = true;
  }

  /// Evaluate reminder rules and show a system notification if needed.
  static Future<void> syncInactivityReminder() async {
    try {
      await init();
      final info = await ReminderService.evaluate();
      if (!info.showInactivity) {
        await _plugin.cancel(id: _notifId);
        return;
      }

      // At most one notification per calendar day
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final dayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (prefs.getString(_lastSentKey) == dayKey) return;

      final langCode = await ProfileStorage.getLanguageCode();
      final l10n = AppLocalizations(Locale(langCode));

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Logbook reminders',
          channelDescription:
          'Reminds you when no cases have been logged recently',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _plugin.show(
        id: _notifId,
        title: l10n.etherlogReminder,
        body: l10n.inactivityReminderBody(info.daysSinceLastCase),
        notificationDetails: details,
      );

      await prefs.setString(_lastSentKey, dayKey);
    } catch (_) {
      // Notifications are best-effort; never crash the app
    }
  }
}