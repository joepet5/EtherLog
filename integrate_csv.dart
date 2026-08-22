import 'dart:io';

void main() {
  var file = File('lib/screens/pdf_options_screen.dart');
  var content = file.readAsStringSync();

  // Add import
  content = content.replaceFirst("import '../services/pdf_service.dart';", "import '../services/pdf_service.dart';\nimport '../services/csv_service.dart';");

  // Add export csv logic
  content = content.replaceFirst(
    '''  Future<void> _exportLogbook() async {''',
    '''  Future<void> _exportCsv() async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV error: \')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportLogbook() async {'''
  );

  // Add Button
  content = content.replaceFirst(
    '''          const SizedBox(height: 8),''',
    '''          const SizedBox(height: 8),
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
          const SizedBox(height: 8),'''
  );

  file.writeAsStringSync(content);
}
