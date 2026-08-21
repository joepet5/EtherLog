import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/usage_stats.dart';
import '../services/case_storage.dart';
import '../services/pdf_service.dart';
import '../services/points_service.dart';
import '../utils/app_haptics.dart';
import 'new_case_screen.dart';
import 'complication_detail_screen.dart';
import 'case_share_qr_screen.dart';
import 'case_points_detail_screen.dart';
import '../widgets/animated_gradient_background.dart';

class CaseDetailScreen extends StatelessWidget {
  final CaseRecord caseRecord;

  const CaseDetailScreen({super.key, required this.caseRecord});

  String _fmtRegional(BuildContext context, Map<String, dynamic> e) {
    final l10n = AppLocalizations.of(context);
    final rawName = e['name']?.toString() ?? '';
    final name = l10n.term(rawName);
    if (rawName == 'None / Not performed') return name;
    final parts = <String>[
      name,
      l10n.term(e['role']?.toString() ?? ''),
    ];
    if (e['usgGuided'] == true) parts.add('USG');
    if (e['nerveStimulator'] == true) parts.add('NS');
    return parts.join(' · ');
  }

  String _fmtInvasive(BuildContext context, Map<String, dynamic> e) {
    final l10n = AppLocalizations.of(context);
    final parts = <String>[
      l10n.term(e['name']?.toString() ?? ''),
      l10n.term(e['role']?.toString() ?? ''),
    ];
    if (e['usgGuided'] == true) parts.add('USG');
    return parts.join(' · ');
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(AppLocalizations.of(ctx).deleteCase, style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          AppLocalizations.of(ctx).deleteCaseWarning,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx).delete, style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await CaseStorage.deleteCase(caseRecord.id);
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  void _shareQr(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseShareQrScreen(caseRecord: caseRecord),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = PointsService.forCase(caseRecord);
    final realRegional = caseRecord.regionalBlocks
        .where((e) => e['name'] != 'None / Not performed')
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(AppLocalizations.of(context).caseDetails),
        actions: [
          Center(
            child: InkWell(
              onTap: () {
                AppHaptics.light();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CasePointsDetailScreen(caseRecord: caseRecord),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '+$points',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).shareCaseQr,
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => _shareQr(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              await UsageStats.incrementPdfExport();
              await PdfService.generateCasePdf(caseRecord);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewCaseScreen(existingCase: caseRecord),
                ),
              );
              if (result == true || result == 'celebrate') {
                if (context.mounted) Navigator.pop(context, result);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.danger),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: () {
              AppHaptics.light();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CasePointsDetailScreen(caseRecord: caseRecord),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: AppTheme.primary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).pointsEarnedThisCase,
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.tapToViewCalculationBreakdown,
                          style: TextStyle(fontSize: 11, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+$points',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                ],
              ),
            ),
          ),

          if (caseRecord.caseSheetImagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(caseRecord.caseSheetImagePath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],

          _section(l10n.caseInformationHeader),
          _row(
            l10n.dateLabel,
            '${caseRecord.date.day}/${caseRecord.date.month}/${caseRecord.date.year}',
          ),
          _row(
            l10n.anaesthesiaLabel,
            '${caseRecord.anaesthesiaStartTime ?? '—'} – ${caseRecord.anaesthesiaEndTime ?? '—'}',
          ),
          _row(l10n.anaesthesiaDurationLabel, caseRecord.anaesthesiaDuration ?? '—'),
          _row(
            l10n.surgeryLabel,
            '${caseRecord.surgeryStartTime ?? '—'} – ${caseRecord.surgeryEndTime ?? '—'}',
          ),
          _row(l10n.surgicalDurationLabel, caseRecord.surgeryDuration ?? '—'),
          _row(
            l10n.caseHospitalNo,
            caseRecord.caseNumber.isEmpty ? '—' : caseRecord.caseNumber,
          ),
          _row(l10n.hospitalLabel, caseRecord.hospital ?? '—'),
          _row(l10n.priorityLabel, l10n.term(caseRecord.priority)),
          _row(l10n.asaGradeLabel, l10n.term(caseRecord.asaGrade)),

          _section(l10n.patientHeader),
          _row(
            l10n.ageGenderLabel,
            '${caseRecord.patientAge ?? '—'} ${l10n.term(caseRecord.ageUnit)} / ${l10n.term(caseRecord.patientGender ?? '—')}',
          ),
          _row(
            l10n.weightLabel,
            caseRecord.patientWeight != null
                ? '${caseRecord.patientWeight} kg'
                : '—',
          ),
          _row(
            l10n.heightLabel,
            caseRecord.patientHeight != null
                ? '${caseRecord.patientHeight} cm'
                : '—',
          ),
          _row(
            l10n.bmiLabel,
            caseRecord.bmi != null ? caseRecord.bmi!.toStringAsFixed(1) : '—',
          ),

          _section(l10n.procedureAndAnaesthesiaHeader),
          _row(
            l10n.diagnosisLabel,
            caseRecord.diagnosis.isEmpty ? '—' : caseRecord.diagnosis,
          ),
          _row(l10n.procedureLabel, caseRecord.procedure),
          _row(l10n.specialtyLabel, l10n.term(caseRecord.specialty)),
          _row(l10n.techniqueLabel, l10n.term(caseRecord.technique)),
          _row(l10n.roleLabel, l10n.term(caseRecord.role)),
          if (caseRecord.role != 'Consultant')
            _row(l10n.supervisorLabel, caseRecord.supervisor ?? '—'),

          if (realRegional.isNotEmpty) ...[
            _section(l10n.regionalAnaesthesiaHeader),
            _row(l10n.blocksLabel, realRegional.map((e) => _fmtRegional(context, e)).join('\n')),
            if (caseRecord.catheterPlaced) _row(l10n.catheterLabel, l10n.placedLabel),
          ],

          _section(l10n.airwayHeader),
          _row(l10n.airwayManagementLabel, l10n.term(caseRecord.airwayManagement ?? '—')),
          if (caseRecord.typeOfIntubation != null)
            _row(l10n.typeOfIntubationLabel, l10n.term(caseRecord.typeOfIntubation!)),
          if (caseRecord.methodOfIntubation != null)
            _row(l10n.methodOfIntubationLabel, l10n.term(caseRecord.methodOfIntubation!)),
          if (caseRecord.methodOfIntubationRole != null)
            _row(l10n.intubationRoleLabel, l10n.term(caseRecord.methodOfIntubationRole!)),
          if (caseRecord.ettType != null) _row(l10n.ettTypeLabel, l10n.term(caseRecord.ettType!)),
          if (caseRecord.ettSize != null)
            _row(l10n.ettSizeLabel, caseRecord.ettSize!.toString()),
          if (caseRecord.lmaType != null) _row(l10n.lmaTypeLabel, l10n.term(caseRecord.lmaType!)),
          if (caseRecord.lmaRole != null) _row(l10n.lmaRoleLabel, l10n.term(caseRecord.lmaRole!)),
          if (caseRecord.lmaSize != null)
            _row(l10n.lmaSizeLabel, caseRecord.lmaSize!.toString()),
          _row(l10n.cormackLehaneLabel, l10n.term(caseRecord.cormackLehane ?? '—')),
          _row(l10n.difficultAirwayLabel, caseRecord.difficultAirway ? l10n.yesLabel : l10n.noLabel),
          if (caseRecord.difficultAirway &&
              caseRecord.difficultAirwayAttempts != null)
            _row(l10n.attemptsLabel, '${caseRecord.difficultAirwayAttempts}'),

          if (caseRecord.invasiveMonitoring.isNotEmpty) ...[
            _section(l10n.invasiveLinesHeader),
            _row(
              l10n.equipmentLabel,
              caseRecord.invasiveMonitoring.map((e) => _fmtInvasive(context, e)).join('\n'),
            ),
          ],

          if (caseRecord.complications.isNotEmpty) ...[
            _section(l10n.complicationsHeader),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: caseRecord.complications.map((comp) {
                final isNone = comp.toLowerCase().contains('none') ||
                    comp.toLowerCase().contains('uneventful');
                return ActionChip(
                  avatar: Icon(
                    isNone
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: isNone ? AppTheme.success : Colors.amber,
                  ),
                  label: Text(l10n.term(comp)),
                  backgroundColor: AppTheme.surface,
                  side: BorderSide(
                    color: isNone
                        ? AppTheme.success.withOpacity(0.4)
                        : Colors.amber.withOpacity(0.4),
                  ),
                  onPressed: isNone
                      ? null
                      : () async {
                    await AppHaptics.light();
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplicationDetailScreen(
                          complicationName: comp,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],

          if (caseRecord.outcome != null && caseRecord.outcome!.isNotEmpty) ...[
            _section(l10n.outcomeHeader),
            _row(l10n.outcome, l10n.term(caseRecord.outcome!)),
          ],


          if (caseRecord.followUpStatus == 'completed') ...[
            _section(l10n.postOpFollowUpHeader),
            if (caseRecord.restPainScore != null)
              _row(l10n.painAtRestLabel, '${caseRecord.restPainScore}/10'),
            if (caseRecord.movementPainScore != null)
              _row(l10n.painOnMovementLabel, '${caseRecord.movementPainScore}/10'),
            if (caseRecord.ponv != null && caseRecord.ponv!.isNotEmpty)
              _row(l10n.ponvLabel, l10n.term(caseRecord.ponv!)),
            if (caseRecord.blockAssessmentTags.isNotEmpty)
              _row(l10n.blockAssessmentLabel, caseRecord.blockAssessmentTags.map((t) => l10n.term(t)).join(', ')),
            if (caseRecord.followUpComplications.isNotEmpty)
              _row(l10n.day1IssuesLabel, caseRecord.followUpComplications.map((t) => l10n.term(t)).join(', ')),
            if (caseRecord.followUpNotes != null && caseRecord.followUpNotes!.isNotEmpty)
              _row(l10n.followUpNotesLabel, caseRecord.followUpNotes!),
            if (caseRecord.followUpCompletedAt != null)
              _row(
                l10n.completedLabel,
                '${caseRecord.followUpCompletedAt!.day}/${caseRecord.followUpCompletedAt!.month}/${caseRecord.followUpCompletedAt!.year}',
              ),
          ],
          _LessonsLearnedCard(initialCase: caseRecord),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonsLearnedCard extends StatefulWidget {
  final CaseRecord initialCase;
  const _LessonsLearnedCard({required this.initialCase});

  @override
  State<_LessonsLearnedCard> createState() => _LessonsLearnedCardState();
}

class _LessonsLearnedCardState extends State<_LessonsLearnedCard> {
  late CaseRecord _caseRecord;
  late TextEditingController _ctrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _caseRecord = widget.initialCase;
    _ctrl = TextEditingController(text: _caseRecord.notes ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = _caseRecord.copyWith(notes: _ctrl.text.trim());
    await CaseStorage.saveCase(updated);
    setState(() {
      _caseRecord = updated;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = _caseRecord.notes != null && _caseRecord.notes!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lessons Learned / Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(_isEditing ? Icons.check : (hasNotes ? Icons.edit : Icons.add), size: 20, color: AppTheme.primary),
                onPressed: () {
                  if (_isEditing) {
                    _save();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ],
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: null,
              minLines: 3,
              style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Next time, use a smaller blade for this patient anatomy...',
                hintStyle: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.surfaceLight),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ] else if (hasNotes) ...[
            const SizedBox(height: 12),
            Text(
              _caseRecord.notes!,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
