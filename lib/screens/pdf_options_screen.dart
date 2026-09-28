import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/usage_stats.dart';
import '../services/pdf_preferences.dart';
import '../services/pdf_service.dart';
import '../services/csv_service.dart';
import '../services/auth_service.dart';
import '../services/case_storage.dart';
import '../utils/app_haptics.dart';

class PdfOptionsScreen extends StatefulWidget {
  const PdfOptionsScreen({super.key});

  @override
  State<PdfOptionsScreen> createState() => _PdfOptionsScreenState();
}

class _PdfOptionsScreenState extends State<PdfOptionsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  PdfPreferences _prefs = const PdfPreferences();
  bool _loading = true;
  bool _saving = false;
  bool _exporting = false;

  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await PdfPreferences.load();
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_prefs.useDateRange) {
      if (_prefs.fromDate == null || _prefs.toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.selectBothDates),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
      if (_prefs.toDate!.isBefore(_prefs.fromDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.toDateBeforeFrom),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    await _prefs.save();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.pdfOptionsSaved),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.pop(context, true);
  }


  Future<void> _exportCsv() async {
    if (_prefs.useDateRange) {
      if (_prefs.fromDate == null || _prefs.toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectBothDates), backgroundColor: AppTheme.danger));
        return;
      }
      if (_prefs.toDate!.isBefore(_prefs.fromDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toDateBeforeFrom), backgroundColor: AppTheme.danger));
        return;
      }
    }

    final authOk = await AuthService.verifyBiometrics('Authenticate to export patient logbook');
    if (!authOk) return;
    setState(() => _exporting = true);
    try {
      await AppHaptics.light();
      await _prefs.save();
      final cases = await CaseStorage.getAllCases();
      if (cases.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noCasesToExport)));
        return;
      }
      final path = await CsvService.exportToCsv(cases, prefs: _prefs);
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV Exported Successfully!'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV error: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportLogbook() async {
    if (_prefs.useDateRange) {
      if (_prefs.fromDate == null || _prefs.toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.selectBothDates),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
      if (_prefs.toDate!.isBefore(_prefs.fromDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.toDateBeforeFrom),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
    }

    setState(() => _exporting = true);
    try {
      await AppHaptics.light();
      await _prefs.save();
      final cases = await CaseStorage.getAllCases();
      if (cases.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noCasesToExport)),
        );
        return;
      }
      await UsageStats.incrementPdfExport();
      await PdfService.generateAllCasesPdf(cases, prefs: _prefs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.logbookPdfExported),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _set(PdfPreferences next) => setState(() => _prefs = next);

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final initial = _prefs.fromDate ?? now.subtract(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    _set(_prefs.copyWith(fromDate: DateTime(picked.year, picked.month, picked.day)));
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final initial = _prefs.toDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    _set(_prefs.copyWith(toDate: DateTime(picked.year, picked.month, picked.day)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.pdfExportOptions),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.pdfOptionsDescription,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // ——— Date range (full logbook only) ———
          Text(
            l10n.dateRange.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_saving || _exporting) ? null : _exportCsv,
              icon: _exporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.table_chart_outlined),
              label: Text(_exporting ? 'Exporting...' : 'Export Logbook CSV (Excel)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _tile(
            title: l10n.exportByDateRange,
            subtitle: l10n.dateRangeExportSubtitle,
            value: _prefs.useDateRange,
            onChanged: (v) => _set(_prefs.copyWith(useDateRange: v)),
          ),
          if (_prefs.useDateRange) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _dateButton(
                    label: l10n.fromDate,
                    value: _prefs.fromDate,
                    onTap: _pickFromDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateButton(
                    label: l10n.toDate,
                    value: _prefs.toDate,
                    onTap: _pickToDate,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          Text(
            l10n.columnsToInclude.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          _tile(
            title: l10n.includeHospitalNumbers,
            subtitle: l10n.hospitalNumbersSubtitle,
            value: _prefs.includeHospitalNumbers,
            onChanged: (v) =>
                _set(_prefs.copyWith(includeHospitalNumbers: v)),
          ),
          _tile(
            title: l10n.patientDetails,
            subtitle: l10n.patientDetailsSubtitle,
            value: _prefs.includePatientDetails,
            onChanged: (v) =>
                _set(_prefs.copyWith(includePatientDetails: v)),
          ),
          _tile(
            title: l10n.anaesthesiaAndSurgeryTimes,
            subtitle: l10n.anaesthesiaTimesSubtitle,
            value: _prefs.includeTimes,
            onChanged: (v) =>
                _set(_prefs.copyWith(includeTimes: v)),
          ),
          _tile(
            title: l10n.regionalAnaesthesia,
            subtitle: l10n.regionalSubtitle,
            value: _prefs.includeRegional,
            onChanged: (v) => _set(_prefs.copyWith(includeRegional: v)),
          ),
          _tile(
            title: l10n.airwayManagement,
            subtitle: l10n.airwaySubtitle,
            value: _prefs.includeAirway,
            onChanged: (v) => _set(_prefs.copyWith(includeAirway: v)),
          ),
          _tile(
            title: l10n.invasiveLines,
            subtitle: l10n.invasiveSubtitle,
            value: _prefs.includeInvasive,
            onChanged: (v) => _set(_prefs.copyWith(includeInvasive: v)),
          ),
          _tile(
            title: l10n.complications,
            subtitle: l10n.complicationsSubtitle,
            value: _prefs.includeComplications,
            onChanged: (v) =>
                _set(_prefs.copyWith(includeComplications: v)),
          ),
          _tile(
            title: l10n.postOpFollowUp,
            subtitle: l10n.postOpFollowUpSubtitle,
            value: _prefs.includeFollowUp,
            onChanged: (v) =>
                _set(_prefs.copyWith(includeFollowUp: v)),
          ),
          _tile(
            title: l10n.includeSpecialtySummary,
            subtitle: l10n.summaryTablesSubtitle,
            value: _prefs.includeSummaryTables,
            onChanged: (v) =>
                _set(_prefs.copyWith(includeSummaryTables: v)),
          ),
          _tile(
            title: l10n.includeSupervisorSignature,
            subtitle: l10n.signatureSubtitle,
            value: _prefs.includeSignatureBlock,
            onChanged: (v) =>
                _set(_prefs.copyWith(includeSignatureBlock: v)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_saving || _exporting) ? null : _save,
            child: Text(l10n.savePdfOptions),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_saving || _exporting) ? null : _exportLogbook,
              icon: _exporting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_exporting ? l10n.exporting : l10n.exportLogbookPdf),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pdfExportFullExplanation,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              value != null ? _dateFmt.format(value) : l10n.selectDate,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: value != null ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        value: value,
        activeThumbColor: AppTheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}
