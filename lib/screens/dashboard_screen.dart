import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/template_storage.dart';
import '../services/case_storage.dart';
import '../services/follow_up_service.dart';
import '../services/backup_service.dart';
import '../services/points_service.dart';
import '../services/profile_storage.dart';
import '../services/subscription_service.dart';
import '../services/fatigue_service.dart';
import '../utils/app_haptics.dart';
import '../utils/page_transitions.dart';
import '../models/pac_record.dart';
import '../services/pac_storage.dart';
import 'pac_screen.dart';
import '../widgets/reminder_banner.dart';
import 'new_case_screen.dart';
import 'case_detail_screen.dart';
import 'case_mix_screen.dart';
import 'data_backup_screen.dart';
import 'help_guide_screen.dart';
import 'follow_up_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';
import 'subscription_screen.dart';
import 'pdf_options_screen.dart';
import 'achievements_screen.dart';
import 'case_import_qr_screen.dart';
import '../l10n/app_localizations.dart';
import 'templates_screen.dart';
import 'sign_off_screen.dart';
import 'insights_screen.dart';
import '../widgets/onboarding_tips.dart';
import '../widgets/interactive_walkthrough.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dops_list_screen.dart';
import 'lock_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  List<CaseRecord> _allCases = [];
  List<PacRecord> _allPacRecords = [];
  List<CaseRecord> _followUpQueue = [];
  List<CaseRecord> _filteredCases = [];
  List<PacRecord> _filteredPacRecords = [];
  List<_TimelineItem> _timelineItems = [];
  int _displayLimit = 25;
  int _total = 0;
  int _elective = 0;
  int _emergency = 0;
  int _difficult = 0;
  int _points = 0;
  bool _loading = true;
  bool _showCelebration = false;
  bool _canAddCases = true;
  bool _showWalkthrough = false;
  bool _zenMode = false;
  bool _verificationEnabled = false;
  FatigueStats? _fatigueStats;
  bool _fatigueNudgeDismissed = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();
  String _selectedFilter = 'All';

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(() {
      if (_listScrollController.position.pixels >=
          _listScrollController.position.maxScrollExtent - 300) {
        if (_displayLimit < _timelineItems.length) {
          setState(() {
            _displayLimit += 25;
          });
        }
      }
    });
    _loadData().then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) maybeShowOnboardingTip(context);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickFromDate() async {
    await AppHaptics.selection();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(2000),
      lastDate: _toDate ?? now,
    );
    if (picked == null) return;
    setState(() {
      _fromDate = DateTime(picked.year, picked.month, picked.day);
      if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
        _toDate = DateTime(
          _fromDate!.year,
          _fromDate!.month,
          _fromDate!.day,
          23,
          59,
          59,
        );
      }
    });
    _applyFilters();
  }

  Future<void> _pickToDate() async {
    await AppHaptics.selection();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    });
    _applyFilters();
  }

  Future<void> _clearDateRange() async {
    await AppHaptics.selection();
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _applyFilters();
  }

  Future<void> _dismissFollowUp(CaseRecord c) async {
    await FollowUpService.dismiss(c);
    await AppHaptics.selection();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final cases = await CaseStorage.getAllCases();
    final total = await CaseStorage.totalCases();
    final elective = await CaseStorage.electiveCount();
    final emergency = await CaseStorage.emergencyCount();
    final difficult = await CaseStorage.difficultAirwayCount();
    final points = await PointsService.totalWithProfileBonus(cases);
    final canAdd = await SubscriptionService.canAddCases();
    final profile = await ProfileStorage.getProfile();

    await FollowUpService.expireOverdue(cases);
    final refreshed = await CaseStorage.getAllCases();
    final queue = FollowUpService.queueFrom(refreshed);

    final prefs = await SharedPreferences.getInstance();
    final walkthroughDone =
        prefs.getBool('interactive_walkthrough_completed') ?? false;
    final pacRecords = await PacStorage.getAllPacRecords();

    setState(() {
      _allCases = refreshed;
      _allPacRecords = pacRecords;
      _followUpQueue = queue;
      _total = total;
      _elective = elective;
      _emergency = emergency;
      _difficult = difficult;
      _points = points;
      _canAddCases = canAdd;
      _showWalkthrough = !walkthroughDone;
      _zenMode = profile.zenMode;
      _verificationEnabled = profile.clinicalVerificationEnabled;
      _fatigueStats = FatigueService.getFatigueStats(cases);
      _loading = false;
    });

    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    List<CaseRecord> result = List.from(_allCases);

    if (_selectedFilter == 'Elective') {
      result = result.where((c) => c.priority == 'Elective').toList();
    } else if (_selectedFilter == 'Emergency') {
      result = result.where((c) => c.priority == 'Emergency').toList();
    } else if (_selectedFilter == 'Difficult') {
      result = result.where((c) => c.difficultAirway).toList();
    } else if (_selectedFilter == 'Regional') {
      result = result.where((c) {
        final names = c.regionalBlockNames;
        if (names.isEmpty) return false;
        if (names.length == 1 && names.contains('None / Not performed')) {
          return false;
        }
        return true;
      }).toList();
    } else if (_selectedFilter == 'Starred') {
      result = result.where((c) => c.starred).toList();
    } else if (_selectedFilter == 'Date') {
      if (_fromDate != null) {
        result = result.where((c) {
          final d = DateTime(c.date.year, c.date.month, c.date.day);
          return !d.isBefore(_fromDate!);
        }).toList();
      }
      if (_toDate != null) {
        final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
        result = result.where((c) {
          final d = DateTime(c.date.year, c.date.month, c.date.day);
          return !d.isAfter(end);
        }).toList();
      }
    }

    if (query.isNotEmpty) {
      result = result.where((c) {
        final regionalMatch =
            c.regionalBlockNames.any((n) => n.toLowerCase().contains(query));
        final invasiveMatch = c.invasiveMonitoring.any(
          (e) => (e['name']?.toString() ?? '').toLowerCase().contains(query),
        );
        return c.procedure.toLowerCase().contains(query) ||
            c.diagnosis.toLowerCase().contains(query) ||
            c.specialty.toLowerCase().contains(query) ||
            c.caseNumber.toLowerCase().contains(query) ||
            (c.hospital?.toLowerCase().contains(query) ?? false) ||
            (c.methodOfIntubation?.toLowerCase().contains(query) ?? false) ||
            (c.typeOfIntubation?.toLowerCase().contains(query) ?? false) ||
            (c.airwayManagement?.toLowerCase().contains(query) ?? false) ||
            regionalMatch ||
            invasiveMatch;
      }).toList();
    }

    var pacResult = List<PacRecord>.from(_allPacRecords);
    if (_selectedFilter == 'Date') {
      if (_fromDate != null) {
        pacResult = pacResult.where((p) {
          final d = DateTime(p.date.year, p.date.month, p.date.day);
          return !d.isBefore(_fromDate!);
        }).toList();
      }
      if (_toDate != null) {
        final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
        pacResult = pacResult.where((p) {
          final d = DateTime(p.date.year, p.date.month, p.date.day);
          return !d.isAfter(end);
        }).toList();
      }
    } else if (_selectedFilter != 'All') {
      pacResult = [];
    }

    if (query.isNotEmpty) {
      pacResult = pacResult.where((p) {
        return 'pac'.contains(query) ||
            'pre-anaesthetic'.contains(query) ||
            p.patientCount.toString().contains(query) ||
            (p.hospital?.toLowerCase().contains(query) ?? false) ||
            (p.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    final items = <_TimelineItem>[
      ...result.map((c) => _CaseItem(c)),
      ...pacResult.map((p) => _PacItem(p)),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _filteredCases = result;
      _filteredPacRecords = pacResult;
      _timelineItems = items;
    });

    if (_listScrollController.hasClients) {
      _listScrollController.jumpTo(0);
    }
  }

  Future<void> _setFilter(String filter) async {
    await AppHaptics.selection();
    setState(() => _selectedFilter = filter);
    _applyFilters();
  }

  Future<void> _triggerCelebration() async {
    if (_zenMode) return;
    final enabled = await ProfileStorage.isCelebrationEnabled();
    if (!enabled || !mounted) return;
    setState(() => _showCelebration = true);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  Future<void> _duplicateCase(CaseRecord c) async {
    await AppHaptics.medium();
    final allowed = await SubscriptionService.canAddCases();
    if (!allowed) {
      if (!mounted) return;
      final renewed =
          await AppPageRoute.push<bool>(context, const SubscriptionScreen());
      if (renewed != true) return;
    }

    final newCase =
        c.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    await CaseStorage.saveCase(newCase);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Case Duplicated')));
    await _loadData();
  }

  void _shareCase(CaseRecord c) {
    AppHaptics.light();
    final summary =
        '${c.specialty} Case - ${c.procedure}\nASA ${c.asaGrade}, ${c.technique}';
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _toggleStar(CaseRecord c) async {
    await AppHaptics.light();
    final updated = c.copyWith(starred: !c.starred);
    await CaseStorage.saveCase(updated);
    if (mounted) await _loadData();
  }

  Future<void> _deleteCase(CaseRecord c) async {
    await AppHaptics.heavy();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Case?'),
        content: const Text('Are you sure you want to delete this case?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await CaseStorage.deleteCase(c.id);
    if (mounted) await _loadData();
  }

  Future<void> _editCase(CaseRecord c) async {
    await AppHaptics.light();
    final result = await AppPageRoute.push(
        context, NewCaseScreen(existingCase: c),
        noAnimation: true);
    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openNewCase() async {
    await AppHaptics.medium();
    final allowed = await SubscriptionService.canAddCases();
    if (!allowed) {
      await AppHaptics.heavy();
      if (!mounted) return;
      final renewed = await AppPageRoute.push<bool>(
        context,
        const SubscriptionScreen(),
      );
      if (renewed != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotAddCases),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
      final ok = await SubscriptionService.canAddCases();
      if (!ok) return;
    }

    final result = await AppPageRoute.push(
      context,
      const NewCaseScreen(),
    );
    if (result == true || result == 'celebrate') {
      await _loadData();
    }
    if (result == 'celebrate' && mounted) {
      await _triggerCelebration();
    }
  }

  Future<void> _exportJson() async {
    await AppHaptics.light();
    if (_allCases.isEmpty) {
      await AppHaptics.heavy();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noCasesYet)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fileName = await BackupService.exportToJson();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (fileName != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported: $fileName')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  Future<void> _importJson() async {
    await AppHaptics.light();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final count = await BackupService.importFromJson();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (count > 0) {
          await _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $count case(s)')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cases imported (or cancelled)')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            titleSpacing: 12,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    AppHaptics.medium();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => LockScreen(
                          onUnlocked: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medical_services_rounded,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    t.appName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Image.asset(
                  'assets/icon/pac_icon.png',
                  width: 22,
                  height: 22,
                  color: AppTheme.textPrimary,
                ),
                tooltip: 'Pre-Anaesthetic Checkup (PAC)',
                onPressed: () async {
                  await AppHaptics.light();
                  if (!mounted) return;
                  AppPageRoute.push(
                    context,
                    const PacScreen(),
                  ).then((_) => _loadData());
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: t.statistics,
                onPressed: () async {
                  await AppHaptics.light();
                  if (!mounted) return;
                  AppPageRoute.push(
                    context,
                    const StatisticsScreen(),
                  ).then((_) => _loadData());
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.insights_outlined),
                tooltip: 'Insights',
                onPressed: () async {
                  await AppHaptics.light();
                  if (!mounted) return;
                  AppPageRoute.push(
                    context,
                    const InsightsScreen(),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  await AppHaptics.selection();
                  if (value == 'case_mix') {
                    await Navigator.push(
                      context,
                      PageRouteBuilder(
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                          pageBuilder: (_, __, ___) => const CaseMixScreen()),
                    );
                  } else if (value == 'achievements') {
                    if (!mounted) return;
                    AppPageRoute.push(
                      context,
                      const AchievementsScreen(),
                    );
                  } else if (value == 'dops_list') {
                    if (!mounted) return;
                      Navigator.push(
                        context,
                        AppPageRoute(
                          page: const DopsListScreen(),
                          style: TransitionStyle.fade,
                        ),
                      );
                  } else if (value == 'templates') {
                    if (!mounted) return;
                    final chosen = await Navigator.push<CaseTemplate>(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                        pageBuilder: (_, __, ___) => const TemplatesScreen(),
                      ),
                    );
                    if (chosen != null && mounted) {
                      AppPageRoute.push(
                        context,
                        NewCaseScreen(initialTemplate: chosen),
                      );
                    }
                  } else if (value == 'help') {
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      PageRouteBuilder(
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                          pageBuilder: (_, __, ___) => const HelpGuideScreen()),
                    );
                  } else if (value == 'backup_restore') {
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                        pageBuilder: (_, __, ___) => const DataBackupScreen(),
                      ),
                    );
                    await _loadData();
                  } else if (value == 'import_qr') {
                    if (!mounted) return;
                    final imported = await AppPageRoute.push(
                      context,
                      const CaseImportQrScreen(),
                    );
                    if (imported == true) await _loadData();
                  } else if (value == 'profile') {
                    if (!mounted) return;
                    AppPageRoute.push(
                      context,
                      const ProfileScreen(),
                    ).then((_) => _loadData());
                  } else if (value == 'pdf_options') {
                    if (!mounted) return;
                    AppPageRoute.push(
                      context,
                      const PdfOptionsScreen(),
                    );
                  } else if (value == 'sign_off') {
                    if (!mounted) return;
                    await AppPageRoute.push(
                      context,
                      const SignOffScreen(),
                    );
                    await _loadData();
                  }
                },
                itemBuilder: (context) => [
                  if (!_zenMode)
                    PopupMenuItem(
                        value: 'achievements', child: Text(t.achievements)),
                  PopupMenuItem(
                      value: 'dops_list', child: const Text('My DOPS Assessments')),
                  if (_verificationEnabled)
                    PopupMenuItem(
                        value: 'sign_off',
                        child: Row(
                          children: [
                            Icon(Icons.verified_user_rounded,
                                size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            const Text('Sign-Off & Verification'),
                          ],
                        )),
                  PopupMenuItem(value: 'help', child: Text(t.helpMenu)),
                  PopupMenuItem(
                      value: 'case_mix', child: Text('Case mix builder')),
                  PopupMenuItem(
                      value: 'templates', child: Text(t.caseTemplatesMenu)),
                  PopupMenuItem(
                      value: 'pdf_options', child: Text(t.pdfOptions)),
                  PopupMenuItem(
                      value: 'backup_restore', child: Text(t.backupRestore)),
                  PopupMenuItem(
                      value: 'import_qr', child: Text(t.importCaseQr)),
                  PopupMenuItem(value: 'profile', child: Text(t.doctorProfile)),
                ],
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_followUpQueue.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            Icon(Icons.healing,
                                size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              t.pendingFollowUp,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_followUpQueue.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          itemCount: _followUpQueue.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final c = _followUpQueue[i];
                            return Dismissible(
                              key: ValueKey('fu_${c.id}'),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _dismissFollowUp(c),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child:
                                    Icon(Icons.close, color: AppTheme.danger),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                      pageBuilder: (_, __, ___) =>
                                          FollowUpScreen(caseRecord: c),
                                    ),
                                  );
                                  await _loadData();
                                },
                                child: Container(
                                  width: 200,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.35)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.procedure.isNotEmpty
                                            ? c.procedure
                                            : c.diagnosis,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${c.date.day}/${c.date.month}/${c.date.year} - ${c.asaGrade}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        t.tapToCompleteSwipeSkip,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (!_canAddCases)
                      Material(
                        color: AppTheme.danger.withValues(alpha: 0.15),
                        child: InkWell(
                          onTap: () async {
                            await AppHaptics.medium();
                            if (!mounted) return;
                            AppPageRoute.push(
                              context,
                              const SubscriptionScreen(),
                            ).then((_) => _loadData());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    color: AppTheme.danger, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.trialExpiredTapRenew,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: AppTheme.danger, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Incomplete draft + inactivity reminders
                    ReminderBanner(onChanged: () => _loadData()),
                    if (_showWalkthrough)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: InteractiveWalkthroughCard(
                          onCaseAdded: () => _loadData(),
                          onDismiss: () =>
                              setState(() => _showWalkthrough = false),
                        ),
                      ),
                    if (_fatigueStats?.showNudge == true &&
                        !_fatigueNudgeDismissed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: GestureDetector(
                          onTap: () async {
                            await AppHaptics.light();
                            setState(() => _fatigueNudgeDismissed = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppTheme.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/icon/fatigue_icon.png',
                                  width: 28,
                                  height: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You have logged ${FatigueService.formatDuration(_fatigueStats!.activeMinutes24h)} of active cases in the last 24h. Remember to hydrate and rest if possible.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        children: [
                          TextField(
                            /* follow-up queue above search */
                            controller: _searchController,
                            onChanged: (_) => _applyFilters(),
                            decoration: InputDecoration(
                              hintText: t.search,
                              prefixIcon: Icon(Icons.search,
                                  color: AppTheme.textSecondary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: 20),
                                      onPressed: () async {
                                        await AppHaptics.selection();
                                        _searchController.clear();
                                        _applyFilters();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: t.filterAll,
                                  selected: _selectedFilter == 'All',
                                  onTap: () => _setFilter('All'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: t.elective,
                                  selected: _selectedFilter == 'Elective',
                                  onTap: () => _setFilter('Elective'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: t.emergency,
                                  selected: _selectedFilter == 'Emergency',
                                  onTap: () => _setFilter('Emergency'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: t.difficultAirway,
                                  selected: _selectedFilter == 'Difficult',
                                  onTap: () => _setFilter('Difficult'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: t.regionalBlock,
                                  selected: _selectedFilter == 'Regional',
                                  onTap: () => _setFilter('Regional'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: t.dateRange,
                                  selected: _selectedFilter == 'Date',
                                  onTap: () => _setFilter('Date'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: t.starred,
                                  selected: _selectedFilter == 'Starred',
                                  onTap: () => _setFilter('Starred'),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedFilter == 'Date') ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickFromDate,
                                    icon: Icon(Icons.calendar_today, size: 16),
                                    label: Text(
                                      _fromDate == null
                                          ? t.fromDate
                                          : _fmtDate(_fromDate!),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _fromDate != null
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      side: BorderSide(
                                        color: _fromDate != null
                                            ? AppTheme.primary
                                            : AppTheme.surfaceLight,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickToDate,
                                    icon: Icon(Icons.event, size: 16),
                                    label: Text(
                                      _toDate == null
                                          ? t.toDate
                                          : _fmtDate(_toDate!),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _toDate != null
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      side: BorderSide(
                                        color: _toDate != null
                                            ? AppTheme.primary
                                            : AppTheme.surfaceLight,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_fromDate != null || _toDate != null) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: 'Clear dates',
                                    onPressed: _clearDateRange,
                                    icon: Icon(
                                      Icons.close,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: t.total,
                              value: '$_total',
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              title: t.elective,
                              value: '$_elective',
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              title: t.emergency,
                              value: '$_emergency',
                              color: AppTheme.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              title: t.difficultAirway,
                              value: '$_difficult',
                              color: AppTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _timelineItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.2),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      (_allCases.isEmpty && _allPacRecords.isEmpty)
                                          ? Icons.health_and_safety
                                          : Icons.search_off,
                                      size: 64,
                                      color: AppTheme.primary,
                                    ),
                                  )
                                      .animate(
                                          onPlay: (controller) =>
                                              controller.repeat(reverse: true))
                                      .scaleXY(
                                          begin: 0.95,
                                          end: 1.05,
                                          duration: 1500.ms,
                                          curve: Curves.easeInOut)
                                      .shimmer(
                                          duration: 2000.ms,
                                          color: Colors.white24),
                                  const SizedBox(height: 24),
                                  Text(
                                    (_allCases.isEmpty && _allPacRecords.isEmpty)
                                        ? t.noCasesYet
                                        : 'No matching entries',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  )
                                      .animate()
                                      .fade(duration: 600.ms)
                                      .slideY(begin: 0.2),
                                  const SizedBox(height: 8),
                                  Text(
                                    (_allCases.isEmpty && _allPacRecords.isEmpty)
                                        ? 'Tap + below to log your first case!'
                                        : 'Try adjusting your search or filters.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  )
                                      .animate()
                                      .fade(duration: 800.ms)
                                      .slideY(begin: 0.2),
                                ],
                              ),
                            )
                          : Scrollbar(
                              controller: _listScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              interactive: true,
                              thickness: 10,
                              radius: const Radius.circular(8),
                              child: RefreshIndicator(
                                onRefresh: _loadData,
                                child: ListView.builder(
                                  controller: _listScrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                  itemCount: math.min(
                                      _displayLimit, _timelineItems.length),
                                  itemBuilder: (context, index) {
                                    final item = _timelineItems[index];
                                    if (item is _PacItem) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _PacCard(
                                          pacRecord: item.pacRecord,
                                          onTap: () async {
                                            await AppHaptics.light();
                                            if (!mounted) return;
                                            AppPageRoute.push(
                                              context,
                                              const PacScreen(),
                                            ).then((_) => _loadData());
                                          },
                                          onDelete: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Delete PAC Entry'),
                                                content: const Text(
                                                    'Are you sure you want to delete this PAC entry?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, true),
                                                    child: const Text('Delete',
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await PacStorage.deletePacRecord(
                                                  item.pacRecord.id);
                                              await _loadData();
                                            }
                                          },
                                        ),
                                      );
                                    }
                                    final c = (item as _CaseItem).caseRecord;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: FocusedMenuHolder(
                                        menuWidth:
                                            MediaQuery.of(context).size.width *
                                                0.50,
                                        blurSize: 5.0,
                                        menuItemExtent: 45,
                                        menuBoxDecoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(15.0))),
                                        duration:
                                            const Duration(milliseconds: 100),
                                        animateMenuItems: true,
                                        blurBackgroundColor: Colors.black54,
                                        bottomOffsetHeight: 100,
                                        openWithTap: false,
                                        onPressed: () {},
                                        menuItems: <FocusedMenuItem>[
                                          FocusedMenuItem(
                                              title: const Text('Edit Case',
                                                  style: TextStyle(
                                                      color: Colors.black)),
                                              trailingIcon: const Icon(Icons.edit,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                _editCase(c);
                                              }),
                                          FocusedMenuItem(
                                              title: const Text('Duplicate',
                                                  style: TextStyle(
                                                      color: Colors.black)),
                                              trailingIcon: Icon(Icons.copy,
                                                  color: AppTheme.primary),
                                              onPressed: () {
                                                _duplicateCase(c);
                                              }),
                                          FocusedMenuItem(
                                              title: Text(c.starred ? 'Unstar Case' : 'Star Case',
                                                  style: const TextStyle(
                                                      color: Colors.black)),
                                              trailingIcon: Icon(
                                                  c.starred ? Icons.star_border_rounded : Icons.star_rounded,
                                                  color: Colors.amber),
                                              onPressed: () {
                                                _toggleStar(c);
                                              }),
                                          FocusedMenuItem(
                                              title: const Text('Copy Info',
                                                  style: TextStyle(
                                                      color: Colors.black)),
                                              trailingIcon: Icon(Icons.share,
                                                  color: AppTheme.primary),
                                              onPressed: () {
                                              _shareCase(c);
                                            }),
                                        FocusedMenuItem(
                                            title: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                            trailingIcon: const Icon(
                                                Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              _deleteCase(c);
                                            }),
                                      ],
                                      child: _CaseCard(
                                        caseRecord: c,
                                        points: PointsService.forCase(c),
                                        zenMode: _zenMode,
                                        verificationEnabled:
                                            _verificationEnabled,
                                        onTap: () async {
                                          await AppHaptics.light();
                                          if (!mounted) return;
                                          final result =
                                              await AppPageRoute.push(
                                                  context,
                                                  CaseDetailScreen(
                                                      caseRecord: c,
                                                      zenMode: _zenMode),
                                                  noAnimation: true);
                                          if (mounted) {
                                            await _loadData();
                                          }
                                          if (result == 'celebrate' &&
                                              mounted) {
                                            await _triggerCelebration();
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
              heroTag: 'addBtn',
              backgroundColor:
                  _canAddCases ? AppTheme.primary : AppTheme.textSecondary,
              onPressed: _openNewCase,
              child: Icon(
                _canAddCases ? Icons.add : Icons.lock_outline,
                color: Colors.white,
              )),
        ),
        if (_showCelebration) const _CelebrationOverlay(),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fade(duration: 400.ms)
        .scaleXY(begin: 0.8, curve: Curves.easeOutBack);
  }
}

class _CaseCard extends StatelessWidget {
  final CaseRecord caseRecord;
  final int points;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final bool zenMode;
  final bool verificationEnabled;

  const _CaseCard({
    required this.caseRecord,
    required this.points,
    this.zenMode = false,
    this.verificationEnabled = false,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (caseRecord.starred)
                  Padding(
                    padding: EdgeInsets.only(right: 6),
                    child:
                        Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  ),
                Expanded(
                  child: Text(
                    caseRecord.procedure,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (!zenMode)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+$points',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                if (verificationEnabled && caseRecord.verified)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 11, color: AppTheme.success),
                        const SizedBox(width: 3),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: caseRecord.priority == 'Emergency'
                        ? AppTheme.warning.withValues(alpha: 0.15)
                        : AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    caseRecord.priority,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: caseRecord.priority == 'Emergency'
                          ? AppTheme.warning
                          : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${caseRecord.specialty}  -  ${caseRecord.asaGrade}',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              '${caseRecord.date.day}/${caseRecord.date.month}/${caseRecord.date.year}  -  ${caseRecord.technique}',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (caseRecord.difficultAirway)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Difficult Airway',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Lottie.asset(
            'assets/animations/celebration.json',
            repeat: false,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

abstract class _TimelineItem {
  DateTime get date;
}

class _CaseItem implements _TimelineItem {
  final CaseRecord caseRecord;
  @override
  DateTime get date => caseRecord.date;
  _CaseItem(this.caseRecord);
}

class _PacItem implements _TimelineItem {
  final PacRecord pacRecord;
  @override
  DateTime get date => pacRecord.date;
  _PacItem(this.pacRecord);
}

class _PacCard extends StatelessWidget {
  final PacRecord pacRecord;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PacCard({
    required this.pacRecord,
    required this.onTap,
    required this.onDelete,
  });

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0D9488).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icon/pac_icon.png',
                      width: 22,
                      height: 22,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pacRecord.patientCount} ${pacRecord.patientCount == 1 ? "patient" : "patients"} seen in PAC',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmtDate(pacRecord.date)}${pacRecord.hospital != null && pacRecord.hospital!.isNotEmpty ? " • ${pacRecord.hospital}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (pacRecord.notes != null &&
                          pacRecord.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          pacRecord.notes!.trim(),
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PAC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D9488),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.textSecondary,
                  tooltip: 'Delete PAC entry',
                  padding: const EdgeInsets.only(left: 6),
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


