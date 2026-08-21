import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionPlan {
  trial,
  month1,
  year1,
  year3,
  lifetime,
  expired,
}

class SubscriptionStatus {
  final SubscriptionPlan plan;
  final DateTime? trialStart;
  final DateTime? expiry; // null = lifetime
  final bool canAddCases;

  const SubscriptionStatus({
    required this.plan,
    required this.trialStart,
    required this.expiry,
    required this.canAddCases,
  });

  String get planLabel {
    switch (plan) {
      case SubscriptionPlan.trial:
        return 'Free trial';
      case SubscriptionPlan.month1:
        return '1 month plan';
      case SubscriptionPlan.year1:
        return '1 year plan';
      case SubscriptionPlan.year3:
        return '3 year plan';
      case SubscriptionPlan.lifetime:
        return 'Lifetime';
      case SubscriptionPlan.expired:
        return 'Expired';
    }
  }

  String get remainingLabel {
    if (plan == SubscriptionPlan.lifetime) return 'Lifetime access';
    if (expiry == null) return '—';
    final now = DateTime.now();
    if (expiry!.isBefore(now)) return 'Expired';
    final days = expiry!.difference(now).inDays;
    if (days <= 0) return 'Expires today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }
}

class SubscriptionService {
  static const _trialStartKey = 'sub_trial_start';
  static const _planKey = 'sub_plan';
  static const _expiryKey = 'sub_expiry';

  static const priceMonth1 = 40;
  static const priceYear1 = 300;
  static const priceYear3 = 600;
  static const priceLifetime = 1000;

  static Future<void> ensureTrialStarted() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_trialStartKey) == null) {
      await prefs.setString(_trialStartKey, DateTime.now().toIso8601String());
      if (prefs.getString(_planKey) == null) {
        await prefs.setString(_planKey, 'trial');
        final expiry = DateTime.now().add(const Duration(days: 30));
        await prefs.setString(_expiryKey, expiry.toIso8601String());
      }
    }
  }

  static Future<SubscriptionStatus> getStatus() async {
    await ensureTrialStarted();
    final prefs = await SharedPreferences.getInstance();
    final planStr = prefs.getString(_planKey) ?? 'trial';
    final trialStart = DateTime.tryParse(prefs.getString(_trialStartKey) ?? '');
    final expiry = DateTime.tryParse(prefs.getString(_expiryKey) ?? '');

    if (planStr == 'lifetime') {
      return SubscriptionStatus(
        plan: SubscriptionPlan.lifetime,
        trialStart: trialStart,
        expiry: null,
        canAddCases: true,
      );
    }

    final now = DateTime.now();
    final active = expiry != null && expiry.isAfter(now);

    if (!active) {
      return SubscriptionStatus(
        plan: SubscriptionPlan.expired,
        trialStart: trialStart,
        expiry: expiry,
        canAddCases: false,
      );
    }

    SubscriptionPlan plan;
    switch (planStr) {
      case 'month1':
        plan = SubscriptionPlan.month1;
        break;
      case 'year1':
        plan = SubscriptionPlan.year1;
        break;
      case 'year3':
        plan = SubscriptionPlan.year3;
        break;
      case 'trial':
      default:
        plan = SubscriptionPlan.trial;
    }

    return SubscriptionStatus(
      plan: plan,
      trialStart: trialStart,
      expiry: expiry,
      canAddCases: true,
    );
  }

  static Future<bool> canAddCases() async {
    final s = await getStatus();
    return s.canAddCases;
  }

  /// Local activation for testing. Replace with Google Play Billing later.
  static Future<void> activatePlan(SubscriptionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    switch (plan) {
      case SubscriptionPlan.month1:
        await prefs.setString(_planKey, 'month1');
        await prefs.setString(
          _expiryKey,
          now.add(const Duration(days: 30)).toIso8601String(),
        );
        break;
      case SubscriptionPlan.year1:
        await prefs.setString(_planKey, 'year1');
        await prefs.setString(
          _expiryKey,
          now.add(const Duration(days: 365)).toIso8601String(),
        );
        break;
      case SubscriptionPlan.year3:
        await prefs.setString(_planKey, 'year3');
        await prefs.setString(
          _expiryKey,
          now.add(const Duration(days: 365 * 3)).toIso8601String(),
        );
        break;
      case SubscriptionPlan.lifetime:
        await prefs.setString(_planKey, 'lifetime');
        await prefs.remove(_expiryKey);
        break;
      default:
        break;
    }
  }
}