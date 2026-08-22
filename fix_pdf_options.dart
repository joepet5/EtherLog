import 'dart:io';

void main() {
  var file = File('lib/screens/pdf_options_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "final authOk = await AuthService.verifyBiometrics('Authenticate to export patient logbook');\n    if (!authOk) return;\n    final authOk = await AuthService.verifyBiometrics('Authenticate to export patient logbook');\n    if (!authOk) return;\n    setState(() => _exporting = true);",
    "final authOk = await AuthService.verifyBiometrics('Authenticate to export patient logbook');\n    if (!authOk) return;\n    setState(() => _exporting = true);"
  );

  content = content.replaceFirst(
    "Future<void> _exportLogbook() async {\n    if (_prefs.useDateRange) {\n      if (_prefs.fromDate == null || _prefs.toDate == null) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(l10n.selectBothDates),\n            backgroundColor: AppTheme.danger,\n          ),\n        );\n        return;\n      }\n      if (_prefs.toDate!.isBefore(_prefs.fromDate!)) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(l10n.toDateBeforeFrom),\n            backgroundColor: AppTheme.danger,\n          ),\n        );\n        return;\n      }\n    }\n\n    setState(() => _exporting = true);",
    "Future<void> _exportLogbook() async {\n    if (_prefs.useDateRange) {\n      if (_prefs.fromDate == null || _prefs.toDate == null) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(l10n.selectBothDates),\n            backgroundColor: AppTheme.danger,\n          ),\n        );\n        return;\n      }\n      if (_prefs.toDate!.isBefore(_prefs.fromDate!)) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(l10n.toDateBeforeFrom),\n            backgroundColor: AppTheme.danger,\n          ),\n        );\n        return;\n      }\n    }\n\n    final authOk = await AuthService.verifyBiometrics('Authenticate to export patient logbook');\n    if (!authOk) return;\n    setState(() => _exporting = true);"
  );

  file.writeAsStringSync(content);
}
