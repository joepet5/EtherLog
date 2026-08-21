import 'package:shared_preferences/shared_preferences.dart';

/// Tracks first-run coach tips so each tip is shown at most once.
class OnboardingService {
  static const _prefix = 'onboarding_tip_';
  static const _completedAllKey = 'onboarding_all_done';
  static const _welcomeShownKey = 'onboarding_welcome_shown';

  static const tipIds = <String>[
    'welcome',
    'templates',
    'pdf_options',
    'achievements',
    'insights',
    'reminders',
  ];

  static const tipCopy = <String, Map<String, String>>{
    'welcome': {
      'title': 'Welcome to Etherlog',
      'body':
      'Log cases quickly and effortlessly, track points and achievements, and export PDFs for your anaesthesia portfolio. Everything stays on this device.',
    },
    'templates': {
      'title': 'Case templates',
      'body':
      'On New Case, open the ⋮ menu to save a template or copy your last case pattern — specialty, technique, airway, and blocks without patient identifiers.',
    },
    'pdf_options': {
      'title': 'PDF export options',
      'body':
      'Under ⋮ → PDF export options you can hide hospital numbers, choose sections, and limit the logbook to a date range.',
    },
    'achievements': {
      'title': 'Achievements',
      'body':
      'Unlock badges as you log cases,document difficult airways, precisely perform regional techniques, and ensure patient safety. Open ⋮ → Achievements to see progress.',
    },
    'insights': {
      'title': 'Insights & trends',
      'body':
      'Open Insights from the menu to see monthly trends, top specialties, blocks, and the ASA mix — your year in review.',
    },
    'reminders': {
      'title': 'Reminders & drafts',
      'body':
      'Leave a case half-finished? Dont worry, Etherlog keeps a draft. You can also set inactivity reminders in Doctor Profile.',
    },
  };

  static Future<bool> isTipDone(String id) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_prefix$id') ?? false;
  }

  static Future<void> markTipDone(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_prefix$id', true);
  }

  static Future<bool> isWelcomeShown() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_welcomeShownKey) ?? false;
  }

  static Future<void> markWelcomeShown() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_welcomeShownKey, true);
  }

  static Future<bool> allDone() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_completedAllKey) == true) return true;
    for (final id in tipIds) {
      if (!(p.getBool('$_prefix$id') ?? false)) return false;
    }
    await p.setBool(_completedAllKey, true);
    return true;
  }

  static Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    for (final id in tipIds) {
      await p.remove('$_prefix$id');
    }
    await p.remove(_completedAllKey);
    await p.remove(_welcomeShownKey);
  }

  /// Next tip that has not been dismissed, or null if finished.
  static Future<String?> nextTipId() async {
    if (await allDone()) return null;
    for (final id in tipIds) {
      if (!await isTipDone(id)) return id;
    }
    return null;
  }
}