import 'dart:io';

void main() {
  // 1. case_detail_screen.dart
  var f1 = File('lib/screens/case_detail_screen.dart');
  var c1 = f1.readAsStringSync();
  c1 = c1.replaceFirst("import '../services/case_storage.dart';", "import '../services/case_storage.dart';\nimport '../services/auth_service.dart';");
  c1 = c1.replaceFirst(
    "await CaseStorage.deleteCase(caseRecord.id);",
    "final authOk = await AuthService.verifyBiometrics('Authenticate to delete patient case');\n      if (!authOk) return;\n      await CaseStorage.deleteCase(caseRecord.id);"
  );
  f1.writeAsStringSync(c1);

  // 2. pdf_options_screen.dart
  var f2 = File('lib/screens/pdf_options_screen.dart');
  var c2 = f2.readAsStringSync();
  c2 = c2.replaceFirst("import '../services/csv_service.dart';", "import '../services/csv_service.dart';\nimport '../services/auth_service.dart';");
  c2 = c2.replaceFirst(
    "setState(() => _exporting = true);",
    "final authOk = await AuthService.verifyBiometrics('Authenticate to export patient logbook');\n    if (!authOk) return;\n    setState(() => _exporting = true);"
  );
  // Need to replace the second setState too for _exportLogbook
  c2 = c2.replaceFirst(
    "setState(() => _exporting = true);",
    "final authOk = await AuthService.verifyBiometrics('Authenticate to export patient logbook');\n    if (!authOk) return;\n    setState(() => _exporting = true);"
  );
  f2.writeAsStringSync(c2);

  // 3. profile_screen.dart
  var f3 = File('lib/screens/profile_screen.dart');
  var c3 = f3.readAsStringSync();
  c3 = c3.replaceFirst("import '../services/pdf_service.dart';", "import '../services/pdf_service.dart';\nimport '../services/auth_service.dart';");
  c3 = c3.replaceFirst(
    "await AppHaptics.light();\n    final cases = await CaseStorage.getAllCases();",
    "await AppHaptics.light();\n    final authOk = await AuthService.verifyBiometrics('Authenticate to export patient data');\n    if (!authOk) return;\n    final cases = await CaseStorage.getAllCases();"
  );
  f3.writeAsStringSync(c3);

  // 4. data_backup_screen.dart
  var f4 = File('lib/screens/data_backup_screen.dart');
  var c4 = f4.readAsStringSync();
  c4 = c4.replaceFirst("import '../services/backup_service.dart';", "import '../services/backup_service.dart';\nimport '../services/auth_service.dart';");
  c4 = c4.replaceFirst(
    "setState(() => _busy = true);",
    "final authOk = await AuthService.verifyBiometrics('Authenticate to export JSON backup');\n    if (!authOk) return;\n    setState(() => _busy = true);"
  );
  f4.writeAsStringSync(c4);
}
