import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'services/profile_storage.dart';
import 'services/backup_service.dart';
import 'services/subscription_service.dart';
import 'utils/app_haptics.dart';
import 'services/notification_service.dart';
import 'screens/lock_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/idle_animation_overlay.dart';
import 'l10n/app_localizations.dart';
import 'widgets/animated_gradient_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const EtherlogApp());
}

class EtherlogApp extends StatefulWidget {
  const EtherlogApp({super.key});

  @override
  State<EtherlogApp> createState() => EtherlogAppState();
}

class EtherlogAppState extends State<EtherlogApp> {
  String _themeKey = 'dark';
  bool _isDark = true;
  String _accentKey = 'default';
  bool _idleAnimationEnabled = true;
  bool _glassmorphismEnabled = true;
  bool _unlocked = false;
  bool _needsProfileSetup = false;
  bool _loading = true;
  bool _needsConfidentiality = true;
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await AppHaptics.init();
    await NotificationService.init();
    // Fire-and-forget inactivity push if rules match
    NotificationService.syncInactivityReminder();
    BackupService.performAutoBackupIfNeeded();
    await SubscriptionService.ensureTrialStarted();

    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('agreed_confidentiality') ?? false;

    final themeKey = await ProfileStorage.getThemeKey();
    final dark = themeKey == 'dark' || themeKey == 'executive';
    final profile = await ProfileStorage.getProfile();
    final langCode = await ProfileStorage.getLanguageCode();
    final glass = await ProfileStorage.getGlassmorphism();

    setState(() {
      _themeKey = themeKey;
      _isDark = dark;
      _accentKey = profile.accentKey;
      _idleAnimationEnabled = profile.idleAnimationEnabled;
      _needsConfidentiality = !agreed;
      _locale = Locale(langCode);
      _loading = false;
    });

    AppTheme.applyTheme(_themeKey);
    AppTheme.applyAccent(_accentKey);
  }

  Future<void> _completeConfidentiality() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('agreed_confidentiality', true);
    setState(() {
      _needsConfidentiality = false;
    });
  }

  void setDarkMode(bool value) {
    final key = value ? 'dark' : 'light';
    setThemeKey(key);
  }

  void setThemeKey(String key) {
    setState(() {
      _themeKey = key;
      _isDark = key == 'dark' || key == 'executive';
    });
    AppTheme.applyTheme(key);
    AppTheme.applyAccent(_accentKey);
    ProfileStorage.setThemeKey(key);
  }

  void setAccentKey(String key) {
    setState(() => _accentKey = key);
    AppTheme.applyAccent(key);
  }

  void setGlassmorphism(bool value) {
    setState(() => _glassmorphismEnabled = value);
  }

  void setIdleAnimationEnabled(bool value) {
    setState(() => _idleAnimationEnabled = value);
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
    ProfileStorage.setLanguageCode(locale.languageCode);
  }

  void unlockApp() {
    setState(() => _unlocked = true);
  }

  void lockApp() {
    setState(() => _unlocked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      
      title: 'ETHERLOG',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.currentTheme,
      darkTheme: AppTheme.currentTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        AppTheme.applyTheme(_themeKey);
        AppTheme.applyAccent(_accentKey);

        Widget content = child ?? const SizedBox.shrink();
        content = Stack(
          children: [
            if (_glassmorphismEnabled) const Positioned.fill(child: AnimatedGradientBackground()) else Positioned.fill(child: Container(color: AppTheme.background)),
            content,
          ],
        );

        final bool enableIdle = _idleAnimationEnabled && _unlocked && !_needsConfidentiality;
          return IdleAnimationOverlay(
            enabled: enableIdle,
            child: content,
          );
      },
      home: _needsConfidentiality
          ? ConfidentialityScreen(onAccepted: _completeConfidentiality)
          : (!_unlocked
          ? LockScreen(
        onUnlocked: unlockApp,
        onFirstSetupComplete: () {
          setState(() {
            _unlocked = true;
            _needsProfileSetup = true;
          });
        },
      )
          : (_needsProfileSetup
          ? ProfileScreen(
        onSetupComplete: () {
          setState(() => _needsProfileSetup = false);
        },
      )
          : const DashboardScreen())),
    );
  }
}

/// Dedicated First-Run Confidentiality Screen (Guarantees it appears on first launch)
class ConfidentialityScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const ConfidentialityScreen({super.key, required this.onAccepted});

  @override
  State<ConfidentialityScreen> createState() => _ConfidentialityScreenState();
}

class _ConfidentialityScreenState extends State<ConfidentialityScreen> {
  bool _agreedToConfidentiality = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                t.welcomeTitle,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Effortlessly log your anaesthesia cases, monitor your career milestones, and unlock professional achievements.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const Text(
                'Patient Privacy & Compliance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                t.confidentialityBody,
                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
              const Spacer(),
              // Avoid CheckboxListTile — its internal ink GlobalKey can clash on some devices.
              GestureDetector(
                onTap: () {
                  setState(() {
                    _agreedToConfidentiality = !_agreedToConfidentiality;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToConfidentiality,
                          activeColor: primary,
                          splashRadius: 0,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            setState(() {
                              _agreedToConfidentiality = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.iAgree,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_agreedToConfidentiality) widget.onAccepted();
                  },
                  style: ElevatedButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                    backgroundColor: _agreedToConfidentiality ? primary : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(t.getStarted, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}