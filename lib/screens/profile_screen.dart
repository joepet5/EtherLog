import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../models/doctor_profile.dart';
import '../services/usage_stats.dart';
import '../services/profile_storage.dart';
import '../services/reminder_service.dart';
import '../services/case_storage.dart';
import '../services/pdf_service.dart';
import '../utils/app_haptics.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  /// When set (first-run flow), called after a successful save instead of popping.
  final VoidCallback? onSetupComplete;

  const ProfileScreen({super.key, this.onSetupComplete});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  final _nameController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _designationController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _registrationController = TextEditingController();

  DateTime? _selectedDob; // <-- Added Date of Birth state variable

  String _accentKey = 'default';
  bool _idleAnimationEnabled = true;
  bool _glassmorphismEnabled = true;
  bool _bunnyEnabled = true;
  bool _hapticsEnabled = true;
  int _reminderDays = 7; // 0 = off
  bool _quietHours = false;
  String _themeKey = 'dark';
  bool _isDark = true;
  String _languageCode = 'en';
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;

  static const _secureStorage = FlutterSecureStorage();

  List<Map<String, dynamic>> _getAccents(AppLocalizations l10n) => [
    {'key': 'default', 'label': l10n.defaultBlue, 'color': const Color(0xFF2563EB)},
    {'key': 'surgical_emerald', 'label': l10n.surgicalEmerald, 'color': const Color(0xFF059669)},
    {'key': 'medical_teal', 'label': l10n.medicalTeal, 'color': const Color(0xFF0891B2)},
    {'key': 'royal_violet', 'label': l10n.royalViolet, 'color': const Color(0xFF7C3AED)},
    {'key': 'surgical_rose', 'label': l10n.surgicalRose, 'color': const Color(0xFFE11D48)},
    {'key': 'amber_gold', 'label': l10n.amberGold, 'color': const Color(0xFFD97706)},
  ];

  String _getThemeLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'light':
        return l10n.themeLight;
      case 'serenity':
        return l10n.themeSerenity;
      case 'night_shift':
        return l10n.themeNightShift;
      case 'midnight_cyan':
        return 'Midnight Cyan';
      case 'dark':
      default:
        return l10n.themeDark;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileStorage.getProfile();
    final celebration = await ProfileStorage.isCelebrationEnabled();
    final themeKey = await ProfileStorage.getThemeKey();
    final dark = themeKey == 'dark';
    final haptics = await ProfileStorage.isHapticsEnabled();
    final glass = await ProfileStorage.getGlassmorphism();
    final reminderEnabled = await ReminderService.isEnabled();
    final reminderDays = await ReminderService.getThresholdDays();
    final quiet = await ReminderService.isQuietHoursEnabled();
    final lang = await ProfileStorage.getLanguageCode();
    setState(() {
      _nameController.text = profile.name;
      _qualificationsController.text = profile.qualifications;
      _designationController.text = profile.designation;
      _hospitalController.text = profile.hospital;
      _registrationController.text = profile.registrationNumber ?? '';
      _selectedDob = profile.dateOfBirth; // <-- Load Date of Birth
      _accentKey = profile.accentKey;
      _idleAnimationEnabled = profile.idleAnimationEnabled;
      _glassmorphismEnabled = glass;
      _bunnyEnabled = celebration;
      _hapticsEnabled = haptics;
      _reminderDays = reminderEnabled ? reminderDays : 0;
      _quietHours = quiet;
      _themeKey = themeKey;
      _isDark = dark;
      _languageCode = lang;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qualificationsController.dispose();
    _designationController.dispose();
    _hospitalController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _onThemeChanged(String key) async {
    await AppHaptics.selection();
    setState(() {
      _themeKey = key;
      _isDark = key == 'dark';
    });
    await ProfileStorage.setThemeKey(key);
    final appState = context.findAncestorStateOfType<EtherlogAppState>();
    appState?.setThemeKey(key);
  }

  Future<void> _exportPdfNoHospitalNumbers() async {
    await AppHaptics.light();
    final cases = await CaseStorage.getAllCases();
    if (cases.isEmpty) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cases to export')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await UsageStats.incrementPdfExport();
      await PdfService.generateAllCasesPdf(
        cases,
        includeHospitalNumbers: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<bool> _verifyPin(String pin) async {
    const keys = ['pin', 'user_pin', 'app_pin', 'etherlog_pin', 'lock_pin'];
    for (final key in keys) {
      final saved = await _secureStorage.read(key: key);
      if (saved != null && saved.isNotEmpty && saved == pin) {
        return true;
      }
    }
    return false;
  }

  Future<void> _deleteAllCases() async {
    if (_deleting) return;
    await AppHaptics.medium();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllCases),
        content: Text(l10n.deleteAllCasesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: Text(l10n.continueText),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final pinController = TextEditingController();
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.enterPinToConfirm),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 12,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (_) {
              Navigator.pop(ctx, true);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: Text(l10n.deleteAllCases),
            ),
          ],
        );
      },
    );

    final pin = pinController.text.trim();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      pinController.dispose();
    });

    if (proceed != true || !mounted) return;

    if (pin.isEmpty) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterPinToConfirm)),
      );
      return;
    }

    final pinOk = await _verifyPin(pin);
    if (!pinOk) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.incorrectPinCasesNotDeleted),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _deleting = true);

    try {
      final count = await CaseStorage.deleteAllCases();
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? l10n.deletedNCases(count)
                : l10n.logbookCleared,
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _capWords(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
    }).join(' ');
  }

  Future<void> _save() async {
    await AppHaptics.medium();
    setState(() => _saving = true);

    final profile = DoctorProfile(
      name: _capWords(_nameController.text),
      qualifications: _capWords(_qualificationsController.text),
      designation: _capWords(_designationController.text),
      hospital: _capWords(_hospitalController.text),
      registrationNumber: _registrationController.text.trim().isEmpty
          ? null
          : _registrationController.text.trim(),
      dateOfBirth: _selectedDob, // <-- Save Date of Birth
      accentKey: _accentKey,
      idleAnimationEnabled: _idleAnimationEnabled,
    );

    await ProfileStorage.saveProfile(profile);
    await ProfileStorage.setCelebrationEnabled(_bunnyEnabled);
    await ProfileStorage.setThemeKey(_themeKey);
    await ProfileStorage.setHapticsEnabled(_hapticsEnabled);
    await ProfileStorage.setGlassmorphism(_glassmorphismEnabled);
    await AppHaptics.setEnabled(_hapticsEnabled);

    final appState = context.findAncestorStateOfType<EtherlogAppState>();
    appState?.setThemeKey(_themeKey);
    appState?.setAccentKey(_accentKey);
    appState?.setIdleAnimationEnabled(_idleAnimationEnabled);
    appState?.setGlassmorphism(_glassmorphismEnabled);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.profileSaved),
        backgroundColor: AppTheme.success,
      ),
    );
    if (widget.onSetupComplete != null) {
      widget.onSetupComplete!();
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textPrimary = cs.onSurface;
    final textSecondary = cs.onSurface.withOpacity(0.65);
    final surface = cs.surface;
    final border = cs.outlineVariant.withOpacity(0.5);

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(l10n.doctorProfile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.doctorProfile),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(l10n.profile.toUpperCase(), AppTheme.primary),
          _labeled(
            l10n.fullName,
            textSecondary,
            TextField(
              controller: _nameController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(hintText: l10n.doctorNameHint),
            ),
          ),
          _labeled(
            l10n.qualifications,
            textSecondary,
            TextField(
              controller: _qualificationsController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: l10n.qualificationsHint,
              ),
            ),
          ),
          _labeled(
            l10n.designation,
            textSecondary,
            TextField(
              controller: _designationController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: l10n.designationHint,
              ),
            ),
          ),
          _labeled(
            l10n.hospital,
            textSecondary,
            TextField(
              controller: _hospitalController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(hintText: l10n.hospitalHint),
            ),
          ),
          _labeled(
            l10n.registrationNumber,
            textSecondary,
            TextField(
              controller: _registrationController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(hintText: l10n.optional),
            ),
          ),
          // --- Date of Birth Field placed right below Registration number ---
          _labeled(
            l10n.dateOfBirth,
            textSecondary,
            InkWell(
              onTap: () async {
                await AppHaptics.light();
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDob ?? DateTime(1990, 1, 1),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDob = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: l10n.selectDateOfBirth,
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  _selectedDob != null
                      ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
                      : l10n.notSpecified,
                  style: TextStyle(
                    color: _selectedDob != null ? textPrimary : textSecondary,
                  ),
                ),
              ),
            ),
          ),
          // -----------------------------------------------------------------
          Text(
            l10n.profileBonusHint,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _exportPdfNoHospitalNumbers,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l10n.exportPdf),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(l10n.appearance.toUpperCase(), AppTheme.primary),
          Text(
            l10n.language,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppLocalizations.supportedLocales.map((loc) {
              final code = loc.languageCode;
              final selected = _languageCode == code;
              final label = AppLocalizations.languageNames[code] ?? code;
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : textPrimary,
                  ),
                ),
                selected: selected,
                selectedColor: AppTheme.primary,
                backgroundColor: surface,
                side: BorderSide(color: selected ? AppTheme.primary : border),
                onSelected: (_) async {
                  await AppHaptics.selection();
                  setState(() => _languageCode = code);
                  await ProfileStorage.setLanguageCode(code);
                  final appState =
                  context.findAncestorStateOfType<EtherlogAppState>();
                  appState?.setLocale(Locale(code));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTheme,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.chooseThemeSubtitle,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppTheme.themes.map((theme) {
                    final key = theme['key'] as String;
                    final label = _getThemeLabel(key, l10n);
                    final swatch = theme['swatch'] as Color;
                    final accent = theme['accent'] as Color;
                    final selected = _themeKey == key;
                    return GestureDetector(
                      onTap: () => _onThemeChanged(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? accent.withOpacity(0.15) : surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? accent : border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: swatch,
                                shape: BoxShape.circle,
                                border: Border.all(color: accent, width: 2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Text(
            l10n.accentColour,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _getAccents(l10n).map((a) {
              final selected = _accentKey == a['key'];
              final color = a['color'] as Color;
              return GestureDetector(
                onTap: () async {
                  await AppHaptics.selection();
                  setState(() => _accentKey = a['key'] as String);
                  final appState =
                  context.findAncestorStateOfType<EtherlogAppState>();
                  appState?.setAccentKey(_accentKey);
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? color : border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        a['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                    title: Text('Glassmorphism UI', style: TextStyle(color: textPrimary)),
                    subtitle: Text('Enable translucent blurred backgrounds', style: TextStyle(fontSize: 12, color: textSecondary)),
                    value: _glassmorphismEnabled,
                    activeColor: AppTheme.primary,
                    onChanged: (v) async {
                      await AppHaptics.selection();
                      setState(() => _glassmorphismEnabled = v);
                    },
                  ),
                  Divider(height: 1, color: border),
                  SwitchListTile(
                    title: Text(
                      l10n.idleAnimation,
                    style: TextStyle(color: textPrimary),
                  ),
                  subtitle: Text(
                    l10n.idleAnimationSubtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  value: _idleAnimationEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (v) async {
                    await AppHaptics.selection();
                    setState(() => _idleAnimationEnabled = v);
                  },
                ),
                Divider(height: 1, color: border),
                SwitchListTile(
                  title: Text(
                    l10n.celebrationAnimation,
                    style: TextStyle(color: textPrimary),
                  ),
                  subtitle: Text(
                    l10n.celebrationAnimationSubtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  value: _bunnyEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (v) async {
                    await AppHaptics.selection();
                    setState(() => _bunnyEnabled = v);
                  },
                ),
                Divider(height: 1, color: border),
                SwitchListTile(
                  title: Text(
                    l10n.haptics,
                    style: TextStyle(color: textPrimary),
                  ),
                  subtitle: Text(
                    l10n.hapticsSubtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  value: _hapticsEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (v) async {
                    if (v) {
                      await AppHaptics.setEnabled(true);
                      await AppHaptics.selection();
                    } else {
                      await AppHaptics.selection();
                      await AppHaptics.setEnabled(false);
                    }
                    setState(() => _hapticsEnabled = v);
                  },
                ),
              ],
            ),
          ),


          const SizedBox(height: 28),
          _sectionTitle(l10n.logbookReminders, AppTheme.primary),
          Text(
            l10n.remindMeIfNoCase,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0, 3, 7, 14, 30].map((d) {
              final label = d == 0 ? l10n.off : l10n.nDays(d);
              final selected = _reminderDays == d;
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : textPrimary,
                  ),
                ),
                selected: selected,
                selectedColor: AppTheme.primary,
                backgroundColor: surface,
                side: BorderSide(color: selected ? AppTheme.primary : border),
                onSelected: (_) async {
                  await AppHaptics.selection();
                  setState(() => _reminderDays = d);
                  if (d == 0) {
                    await ReminderService.setEnabled(false);
                  } else {
                    await ReminderService.setEnabled(true);
                    await ReminderService.setThresholdDays(d);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: SwitchListTile(
              title: Text(l10n.quietHours, style: TextStyle(color: textPrimary)),
              subtitle: Text(
                l10n.quietHoursSubtitle,
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              value: _quietHours,
              activeColor: AppTheme.primary,
              onChanged: (v) async {
                await AppHaptics.selection();
                await ReminderService.setQuietHoursEnabled(v);
                setState(() => _quietHours = v);
              },
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle(l10n.deleteAllCases.toUpperCase(), AppTheme.danger),


          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withOpacity(0.45)),
            ),
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: AppTheme.danger),
              title: Text(
                l10n.deleteAllCases,
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                l10n.deleteAllCasesWarning,
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              trailing: _deleting
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(Icons.chevron_right, color: AppTheme.danger),
              onTap: _deleting ? null : _deleteAllCases,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.saveProfile),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${l10n.appVersion} v2.8',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _labeled(String label, Color labelColor, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
