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
import 'follow_up_screen.dart';
import 'sign_off_screen.dart';
import 'detailed_assessment_screen.dart';
import '../utils/page_transitions.dart';
import '../services/follow_up_service.dart';
import '../services/profile_storage.dart';
import 'dops_request_qr_screen.dart';
import 'dops_detail_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final CaseRecord caseRecord;
  final bool zenMode;

  const CaseDetailScreen(
      {super.key, required this.caseRecord, this.zenMode = false});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late CaseRecord caseRecord;
  bool _verificationEnabled = false;

  Map<String, dynamic>? get _actualDetailedAssessment {
    if (caseRecord.detailedAssessment != null && !caseRecord.detailedAssessment!.containsKey('assessorName')) {
      return caseRecord.detailedAssessment;
    }
    return null;
  }

  Map<String, dynamic>? get _actualDopsAssessment {
    if (caseRecord.dopsAssessment != null) return caseRecord.dopsAssessment;
    if (caseRecord.detailedAssessment != null && caseRecord.detailedAssessment!.containsKey('assessorName')) {
      return caseRecord.detailedAssessment;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    caseRecord = widget.caseRecord;
    _syncWithStorage();
  }

  Future<void> _syncWithStorage() async {
    final profile = await ProfileStorage.getProfile();
    final isVerEnabled = profile.clinicalVerificationEnabled;
    final stored = await CaseStorage.getCase(widget.caseRecord.id);
    if (stored != null && mounted) {
      if (isVerEnabled &&
          stored.role.toLowerCase().contains('consultant') &&
          !stored.verified) {
        final updated = stored.copyWith(
          verified: true,
          verifiedBy: stored.verifiedBy ?? 'Self (Consultant)',
          verifiedAt: stored.verifiedAt ?? stored.date,
        );
        await CaseStorage.saveCase(updated);
        setState(() {
          caseRecord = updated;
          _verificationEnabled = isVerEnabled;
        });
      } else {
        setState(() {
          caseRecord = stored;
          _verificationEnabled = isVerEnabled;
        });
      }
    } else if (isVerEnabled &&
        caseRecord.role.toLowerCase().contains('consultant') &&
        !caseRecord.verified) {
      final updated = caseRecord.copyWith(
        verified: true,
        verifiedBy: caseRecord.verifiedBy ?? 'Self (Consultant)',
        verifiedAt: caseRecord.verifiedAt ?? DateTime.now(),
      );
      await CaseStorage.saveCase(updated);
      if (mounted) {
        setState(() {
          caseRecord = updated;
          _verificationEnabled = isVerEnabled;
        });
      }
    } else if (mounted) {
      setState(() => _verificationEnabled = isVerEnabled);
    }
  }

  Future<void> _verifyThisCase() async {
    AppHaptics.medium();
    final profile = await ProfileStorage.getProfile();
    final verifier = profile.name.trim().isNotEmpty
        ? profile.name.trim()
        : (caseRecord.supervisor?.trim().isNotEmpty == true
            ? caseRecord.supervisor!.trim()
            : 'Self (${caseRecord.role})');
    final updated = caseRecord.copyWith(
      verified: true,
      verifiedBy: verifier,
      verifiedAt: DateTime.now(),
    );
    await CaseStorage.saveCase(updated);
    if (mounted) {
      setState(() => caseRecord = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Case saved as Clinically Verified Record'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDopsCard(Map<String, dynamic> dopsJson) {
    final assessor = dopsJson['assessorName'] ?? 'Assessor';
    final competence = dopsJson['overallCompetence'] ?? 'Not Rated';
    final procedure = dopsJson['procedure'] ?? caseRecord.procedure;
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
          Navigator.push(
            context,
            AppPageRoute(
              page: DopsDetailScreen(
                caseRecord: caseRecord,
                dops: dopsJson,
              ),
              style: TransitionStyle.fade,
            ),
          );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOPS Assessment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'By $assessor for $procedure',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Overall Competence:', style: TextStyle(color: AppTheme.textSecondary)),
                Text(
                  competence,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (dopsJson['strengths'] != null && dopsJson['strengths'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Strengths:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
            Text(dopsJson['strengths'], style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
          if (dopsJson['areasForImprovement'] != null && dopsJson['areasForImprovement'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Areas for Improvement:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
            Text(dopsJson['areasForImprovement'], style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    ));
  }

  void _showVerifyOptions() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSolid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_rounded,
                        color: AppTheme.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Clinical Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.success),
                ),
                title: Text(
                  'Quick Clinical Verification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Mark this record as clinically verified and save to logbook',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _verifyThisCase();
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.draw_rounded, color: AppTheme.primary),
                ),
                title: Text(
                  'Request Supervisor Sign-Off',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Open digital sign-off pad for supervisor signature',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                    await Navigator.push(
                      context,
                      AppPageRoute(
                        page: SignOffScreen(
                          preselectedCases: [caseRecord],
                        ),
                        style: TransitionStyle.fade,
                      ),
                    );
                  final updated = await CaseStorage.getCase(caseRecord.id);
                  if (updated != null && mounted) {
                    setState(() => caseRecord = updated);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerificationAuditSheet() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSolid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_rounded,
                        color: AppTheme.success, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinically Verified Record',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Verified and permanently saved to case log',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (caseRecord.verifiedBy != null)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline, color: AppTheme.primary),
                  title: Text('Verified by',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  subtitle: Text(caseRecord.verifiedBy!,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                ),
              if (caseRecord.verifiedAt != null)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today_outlined,
                      color: AppTheme.primary),
                  title: Text('Verification Date',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  subtitle: Text(
                    '${caseRecord.verifiedAt!.day}/${caseRecord.verifiedAt!.month}/${caseRecord.verifiedAt!.year}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: Icon(Icons.remove_circle_outline,
                    color: AppTheme.danger, size: 18),
                label: Text('Remove Verification',
                    style: TextStyle(color: AppTheme.danger)),
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: AppTheme.danger.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final updated = caseRecord.copyWith(clearVerification: true);
                  await CaseStorage.saveCase(updated);
                  if (mounted) {
                    setState(() => caseRecord = updated);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification removed'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFollowUp() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => FollowUpScreen(caseRecord: caseRecord),
      ),
    );
    if (result == true) {
      final updated = await CaseStorage.getCase(caseRecord.id);
      if (updated != null && mounted) {
        setState(() => caseRecord = updated);
      }
    }
  }

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
    if (e['catheterPlaced'] == true || e['hasCatheter'] == true) {
      parts.add(l10n.catheterLabel);
    }
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
        backgroundColor: AppTheme.surfaceSolid,
        title: Text(AppLocalizations.of(ctx).deleteCase,
            style: TextStyle(color: AppTheme.textPrimary)),
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
            child: Text(AppLocalizations.of(ctx).delete,
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await CaseStorage.deleteCase(caseRecord.id);
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  List<String> _getDopsEligibleProcedures() {
    final List<String> procedures = [];
    
    // 1. Main Procedure
    if (!caseRecord.role.toLowerCase().contains('consultant')) {
      final proc = caseRecord.procedure.isNotEmpty ? caseRecord.procedure : caseRecord.diagnosis;
      if (proc.isNotEmpty) {
        procedures.add(proc);
      }
    }

    // 2. Intubation
    if (caseRecord.methodOfIntubation != null && caseRecord.methodOfIntubation != 'None / Not performed' && caseRecord.methodOfIntubation != 'None') {
      final role = caseRecord.methodOfIntubationRole ?? '';
      if (!role.toLowerCase().contains('consultant') && role.isNotEmpty) {
        procedures.add('Intubation (${caseRecord.methodOfIntubation})');
      }
    }

    // 3. LMA
    if (caseRecord.lmaType != null && caseRecord.lmaType != 'None / Not performed' && caseRecord.lmaType != 'None') {
      final role = caseRecord.lmaRole ?? '';
      if (!role.toLowerCase().contains('consultant') && role.isNotEmpty) {
        procedures.add('LMA Insertion (${caseRecord.lmaType})');
      }
    }

    // 4. Regional Blocks
    for (final block in caseRecord.regionalBlocks) {
      final role = (block['role'] ?? '').toString();
      if (!role.toLowerCase().contains('consultant') && role.isNotEmpty) {
        final name = (block['name'] ?? block['block'] ?? '').toString();
        if (name.isNotEmpty && !name.toLowerCase().contains('none / not performed')) {
          procedures.add('Regional Block: $name');
        }
      }
    }

    // 5. Invasive Monitoring
    for (final line in caseRecord.invasiveMonitoring) {
      final role = (line['role'] ?? '').toString();
      if (!role.toLowerCase().contains('consultant') && role.isNotEmpty) {
        final name = (line['type'] ?? line['name'] ?? '').toString();
        if (name.isNotEmpty && !name.toLowerCase().contains('none / not performed')) {
          procedures.add('Invasive Line: $name');
        }
      }
    }

    // 6. PCA
    if (caseRecord.pca) {
      procedures.add('Patient Controlled Analgesia (PCA)');
    }

    if (procedures.isEmpty) {
      final fallback = caseRecord.procedure.isNotEmpty ? caseRecord.procedure : caseRecord.diagnosis;
      procedures.add(fallback.isNotEmpty ? fallback : 'Procedure');
    }

    return procedures.toSet().toList();
  }

  Future<void> _showDopsSelectionSheet() async {
    final procedures = _getDopsEligibleProcedures();
    
    if (procedures.length == 1) {
      AppHaptics.light();
        await Navigator.push(
          context,
          AppPageRoute(
            page: DopsRequestQrScreen(
              caseRecord: caseRecord,
              requestedProcedure: procedures.first,
            ),
            style: TransitionStyle.fade,
          ),
        );
      _syncWithStorage();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSolid,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select DOPS Procedure',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Which procedure would you like your consultant to assess?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: procedures.length,
                  itemBuilder: (ctx, i) {
                    final proc = procedures[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(proc, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                      trailing: Icon(Icons.chevron_right, color: AppTheme.primary, size: 20),
                      onTap: () async {
                        Navigator.pop(ctx);
                        AppHaptics.light();
                          await Navigator.push(
                            context,
                            AppPageRoute(
                              page: DopsRequestQrScreen(
                                caseRecord: caseRecord,
                                requestedProcedure: proc,
                              ),
                              style: TransitionStyle.fade,
                            ),
                          );
                        _syncWithStorage();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareQr(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => CaseShareQrScreen(caseRecord: caseRecord),
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).caseDetails),
        actions: [
          Center(
            child: InkWell(
              onTap: () {
                AppHaptics.light();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    pageBuilder: (_, __, ___) =>
                        CasePointsDetailScreen(caseRecord: caseRecord),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded,
                        size: 16, color: AppTheme.primary),
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
                PageRouteBuilder(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder: (_, __, ___) =>
                      NewCaseScreen(existingCase: caseRecord),
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
      body: RefreshIndicator(
        onRefresh: () async {
          final profile = await ProfileStorage.getProfile();
          final isVerEnabled = profile.clinicalVerificationEnabled;
          final updated = await CaseStorage.getCase(caseRecord.id);
          if (updated != null && mounted) {
            if (isVerEnabled &&
                updated.role.toLowerCase().contains('consultant') &&
                !updated.verified) {
              final fixed = updated.copyWith(
                verified: true,
                verifiedBy: updated.verifiedBy ?? 'Self (Consultant)',
                verifiedAt: updated.verifiedAt ?? updated.date,
              );
              await CaseStorage.saveCase(fixed);
              setState(() {
                caseRecord = fixed;
                _verificationEnabled = isVerEnabled;
              });
            } else {
              setState(() {
                caseRecord = updated;
                _verificationEnabled = isVerEnabled;
              });
            }
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: () {
                AppHaptics.light();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    pageBuilder: (_, __, ___) =>
                        CasePointsDetailScreen(caseRecord: caseRecord),
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
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded,
                        color: AppTheme.primary, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).pointsEarnedThisCase,
                            style: TextStyle(
                                fontSize: 14, color: AppTheme.textSecondary),
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
                    Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: _showDopsSelectionSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        color: AppTheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request DOPS Assessment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            'Generate QR to request peer-to-peer assessment',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppTheme.primary, size: 20),
                  ],
                ),
              ),
            ),
            if (_actualDopsAssessment != null)
              _buildDopsCard(_actualDopsAssessment!),
            if (_actualDetailedAssessment != null)
              InkWell(
                onTap: () async {
                  AppHaptics.light();
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      AppPageRoute(
                        page: DetailedAssessmentScreen(
                          initialData: caseRecord.detailedAssessment,
                          existingCase: caseRecord,
                          isReadOnly: false,
                        ),
                        style: TransitionStyle.fade,
                      ),
                    );
                  if (result != null && mounted) {
                    final updated =
                        caseRecord.copyWith(detailedAssessment: result);
                    await CaseStorage.saveCase(updated);
                    setState(() => caseRecord = updated);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_outlined,
                          color: AppTheme.primary, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.term('Detailed Assessment & Plan'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.term(
                                  'Tap to view or edit pre-op evaluation and plan'),
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: AppTheme.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
            if (_verificationEnabled && caseRecord.verified)
              InkWell(
                onTap: _showVerificationAuditSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppTheme.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clinically Verified Record',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                            Text(
                              caseRecord.verifiedBy != null
                                  ? 'Verified by Dr. ${caseRecord.verifiedBy}${caseRecord.verifiedAt != null ? ' on ${caseRecord.verifiedAt!.day}/${caseRecord.verifiedAt!.month}/${caseRecord.verifiedAt!.year}' : ''}'
                                  : 'Verified with supervisor digital signature',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.success.withValues(alpha: 0.7),
                          size: 18),
                    ],
                  ),
                ),
              )
            else if (_verificationEnabled &&
                !caseRecord.role.toLowerCase().contains('consultant'))
              InkWell(
                onTap: _showVerifyOptions,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.surfaceLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.draw_rounded,
                          color: AppTheme.textSecondary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unverified Clinical Case',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Tap to request consultant sign-off for this case',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (caseRecord.caseSheetImagePath != null) ...[
              GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(
                      page: _FullScreenPhotoViewer(
                        imagePath: caseRecord.caseSheetImagePath!,
                      ),
                      style: TransitionStyle.fade,
                    ),
                  ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(caseRecord.caseSheetImagePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
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
            _row(l10n.anaesthesiaDurationLabel,
                caseRecord.anaesthesiaDuration ?? '—'),
            if (caseRecord.specialty != 'Vascular access' &&
                (caseRecord.surgeryStartTime != null ||
                    caseRecord.surgeryEndTime != null ||
                    caseRecord.surgeryDuration != null)) ...[
              _row(
                l10n.surgeryLabel,
                '${caseRecord.surgeryStartTime ?? '—'} – ${caseRecord.surgeryEndTime ?? '—'}',
              ),
              _row(l10n.surgicalDurationLabel,
                  caseRecord.surgeryDuration ?? '—'),
            ],
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
              '${caseRecord.formattedAge.isNotEmpty ? caseRecord.formattedAge : '—'} ${l10n.term(caseRecord.ageUnit)} / ${l10n.term(caseRecord.patientGender ?? '—')}',
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
            if (realRegional.isNotEmpty ||
                caseRecord.catheterPlaced ||
                caseRecord.pca) ...[
              _section(l10n.regionalAnaesthesiaHeader),
              if (realRegional.isNotEmpty)
                _row(
                    l10n.blocksLabel,
                    realRegional
                        .map((e) => _fmtRegional(context, e))
                        .join('\n')),
              if (caseRecord.catheterPlaced)
                Builder(
                  builder: (context) {
                    final cathBlocks = realRegional
                        .where((e) =>
                            e['catheterPlaced'] == true ||
                            e['hasCatheter'] == true)
                        .map((e) => l10n.term(e['name']?.toString() ?? ''))
                        .toList();
                    final text = cathBlocks.isNotEmpty
                        ? cathBlocks.join(', ')
                        : l10n.placedLabel;
                    return _row(l10n.catheterLabel, text);
                  },
                ),
              if (caseRecord.pca)
                _row('PCA', l10n.term('Patient controlled analgesia (PCA)')),
            ],
            _section(l10n.airwayHeader),
            _row(l10n.airwayManagementLabel,
                l10n.term(caseRecord.airwayManagement ?? '—')),
            if (caseRecord.typeOfIntubation != null)
              _row(l10n.typeOfIntubationLabel,
                  l10n.term(caseRecord.typeOfIntubation!)),
            if (caseRecord.methodOfIntubation != null)
              _row(l10n.methodOfIntubationLabel,
                  l10n.term(caseRecord.methodOfIntubation!)),
            if (caseRecord.methodOfIntubationRole != null)
              _row(l10n.intubationRoleLabel,
                  l10n.term(caseRecord.methodOfIntubationRole!)),
            if (caseRecord.ettType != null)
              _row(l10n.ettTypeLabel, l10n.term(caseRecord.ettType!)),
            if (caseRecord.ettSize != null)
              _row(l10n.ettSizeLabel, caseRecord.ettSize!.toString()),
            if (caseRecord.lmaType != null)
              _row(l10n.lmaTypeLabel, l10n.term(caseRecord.lmaType!)),
            if (caseRecord.lmaRole != null)
              _row(l10n.lmaRoleLabel, l10n.term(caseRecord.lmaRole!)),
            if (caseRecord.lmaSize != null)
              _row(l10n.lmaSizeLabel, caseRecord.lmaSize!.toString()),
            _row(l10n.cormackLehaneLabel,
                l10n.term(caseRecord.cormackLehane ?? '—')),
            _row(l10n.difficultAirwayLabel,
                caseRecord.difficultAirway ? l10n.yesLabel : l10n.noLabel),
            if (caseRecord.difficultAirway &&
                caseRecord.difficultAirwayAttempts != null)
              _row(l10n.attemptsLabel, '${caseRecord.difficultAirwayAttempts}'),
            if (caseRecord.invasiveMonitoring.isNotEmpty) ...[
              _section(l10n.invasiveLinesHeader),
              _row(
                l10n.equipmentLabel,
                caseRecord.invasiveMonitoring
                    .map((e) => _fmtInvasive(context, e))
                    .join('\n'),
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
                    backgroundColor: AppTheme.surfaceSolid,
                    side: BorderSide(
                      color: isNone
                          ? AppTheme.success.withValues(alpha: 0.4)
                          : Colors.amber.withValues(alpha: 0.4),
                    ),
                    onPressed: isNone
                        ? null
                        : () async {
                            await AppHaptics.light();
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                                pageBuilder: (_, __, ___) =>
                                    ComplicationDetailScreen(
                                  complicationName: comp,
                                ),
                              ),
                            );
                          },
                  );
                }).toList(),
              ),
            ],
            if (caseRecord.outcome != null &&
                caseRecord.outcome!.isNotEmpty) ...[
              _section(l10n.outcomeHeader),
              _row(l10n.outcome, l10n.term(caseRecord.outcome!)),
            ],
            if (caseRecord.followUpStatus == 'completed') ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.postOpFollowUpHeader,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppTheme.primary,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _openFollowUp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Edit Follow-Up',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (caseRecord.restPainScore != null)
                _row(l10n.painAtRestLabel, '${caseRecord.restPainScore}/10'),
              if (caseRecord.movementPainScore != null)
                _row(l10n.painOnMovementLabel,
                    '${caseRecord.movementPainScore}/10'),
              if (caseRecord.ponv != null && caseRecord.ponv!.isNotEmpty)
                _row(l10n.ponvLabel, l10n.term(caseRecord.ponv!)),
              if (caseRecord.blockAssessmentTags.isNotEmpty)
                _row(
                    l10n.blockAssessmentLabel,
                    caseRecord.blockAssessmentTags
                        .map((t) => l10n.term(t))
                        .join(', ')),
              if (caseRecord.followUpComplications.isNotEmpty)
                _row(
                    l10n.day1IssuesLabel,
                    caseRecord.followUpComplications
                        .map((t) => l10n.term(t))
                        .join(', ')),
              if (caseRecord.followUpNotes != null &&
                  caseRecord.followUpNotes!.isNotEmpty)
                _row(l10n.followUpNotesLabel, caseRecord.followUpNotes!),
              if (caseRecord.followUpCompletedAt != null)
                _row(
                  l10n.completedLabel,
                  '${caseRecord.followUpCompletedAt!.day}/${caseRecord.followUpCompletedAt!.month}/${caseRecord.followUpCompletedAt!.year}',
                ),
            ] else if (FollowUpService.isEligible(caseRecord)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.postOpFollowUpHeader,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppTheme.primary,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _openFollowUp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Record Follow-Up',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _LessonsLearnedCard(initialCase: caseRecord),
            const SizedBox(height: 32),
          ],
        ),
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
                  Icon(Icons.lightbulb_outline,
                      color: AppTheme.primary, size: 20),
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
                icon: Icon(
                    _isEditing
                        ? Icons.check
                        : (hasNotes ? Icons.edit : Icons.add),
                    size: 20,
                    color: AppTheme.primary),
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
                hintText:
                    'e.g. Next time, use a smaller blade for this patient anatomy...',
                hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5)),
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
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen pinch-to-zoom photo viewer for case sheet images.
class _FullScreenPhotoViewer extends StatelessWidget {
  final String imagePath;
  const _FullScreenPhotoViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 6.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}


