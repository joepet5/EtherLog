import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/case_record.dart';
import '../services/case_storage.dart';
import '../services/pdf_service.dart';
import '../services/usage_stats.dart';
import '../utils/app_haptics.dart';
import '../screens/statistics_screen.dart';

class InteractiveWalkthroughCard extends StatefulWidget {
  final VoidCallback onCaseAdded;
  final VoidCallback onDismiss;

  const InteractiveWalkthroughCard({
    super.key,
    required this.onCaseAdded,
    required this.onDismiss,
  });

  @override
  State<InteractiveWalkthroughCard> createState() => _InteractiveWalkthroughCardState();
}

class _InteractiveWalkthroughCardState extends State<InteractiveWalkthroughCard> {
  bool _step1Done = false;
  bool _step2Done = false;
  bool _step3Done = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _step1Done = prefs.getBool('walkthrough_step_1') ?? false;
      _step2Done = prefs.getBool('walkthrough_step_2') ?? false;
      _step3Done = prefs.getBool('walkthrough_step_3') ?? false;
    });
  }

  Future<void> _logDemoCase() async {
    AppHaptics.medium();
    final demoCase = CaseRecord(
      caseNumber: 'DEMO-01',
      date: DateTime.now(),
      patientAge: 34,
      ageUnit: 'years',
      patientGender: 'Female',
      specialty: 'General Surgery',
      diagnosis: 'Acute cholecystitis',
      procedure: 'Laparoscopic cholecystectomy',
      priority: 'Elective',
      asaGrade: 'ASA II',
      technique: 'General Anaesthesia (TIVA)',
      role: 'Consultant',
      airwayManagement: 'Endotracheal Tube (ETT)',
      regionalBlocks: [
        {
          'name': 'TAP block',
          'technique': 'USG guided',
          'role': 'Performed',
          'localAnaesthetic': 'Bupivacaine 0.25% 20ml',
        }
      ],
      catheterPlaced: false,
      invasiveMonitoring: [
        {
          'name': 'Arterial line',
          'site': 'Radial',
          'technique': 'Palpation',
          'role': 'Used independently',
        }
      ],
      complications: ['None/uneventful'],
      anaesthesiaDuration: '1h 30m',
      surgeryDuration: '1h 00m',
      flagForFollowUp: true,
      outcome: 'Uneventful PACU discharge',
    );

    await CaseStorage.saveCase(demoCase);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('walkthrough_step_1', true);

    setState(() {
      _step1Done = true;
    });

    widget.onCaseAdded();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).walkthroughStep1} - ${AppLocalizations.of(context).completed}',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _openStats() async {
    AppHaptics.light();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('walkthrough_step_2', true);
    setState(() {
      _step2Done = true;
    });

    if (mounted) {
      await Navigator.push(
        context,
        PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => const StatisticsScreen()),
      );
    }
  }

  Future<void> _exportPdf() async {
    AppHaptics.light();
    final cases = await CaseStorage.getAllCases();
    if (cases.isNotEmpty) {
      await UsageStats.incrementPdfExport();
      await PdfService.generateCasePdf(cases.first);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('walkthrough_step_3', true);
    setState(() {
      _step3Done = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).walkthroughStep3} - ${AppLocalizations.of(context).completed}',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('interactive_walkthrough_completed', true);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allDone = _step1Done && _step2Done && _step3Done;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.rocket_launch, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.walkthroughTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.walkthroughSubtitle,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                tooltip: l10n.dismiss,
                onPressed: _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Step 1
          _buildStepRow(
            stepNumber: 1,
            title: l10n.walkthroughStep1,
            desc: l10n.walkthroughStep1Desc,
            isDone: _step1Done,
            buttonText: _step1Done ? l10n.completed : 'Log Demo Case',
            onTap: _step1Done ? null : _logDemoCase,
          ),
          const Divider(height: 18),

          // Step 2
          _buildStepRow(
            stepNumber: 2,
            title: l10n.walkthroughStep2,
            desc: l10n.walkthroughStep2Desc,
            isDone: _step2Done,
            buttonText: _step2Done ? l10n.completed : 'Open Stats',
            onTap: _step2Done ? null : _openStats,
          ),
          const Divider(height: 18),

          // Step 3
          _buildStepRow(
            stepNumber: 3,
            title: l10n.walkthroughStep3,
            desc: l10n.walkthroughStep3Desc,
            isDone: _step3Done,
            buttonText: _step3Done ? l10n.completed : 'Export PDF',
            onTap: _step3Done ? null : _exportPdf,
          ),

          if (allDone) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _dismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
                child: Text('${l10n.completed} - ${l10n.dismiss}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required int stepNumber,
    required String title,
    required String desc,
    required bool isDone,
    required String buttonText,
    required VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isDone ? AppTheme.success : AppTheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDone ? AppTheme.textSecondary : AppTheme.textPrimary,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                desc,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(
              color: isDone ? AppTheme.success : AppTheme.primary,
            ),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDone ? AppTheme.success : AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
