import 'dart:io';

void main() {
  var file = File('lib/screens/case_detail_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "final authOk = await AuthService.verifyBiometrics('Authenticate to delete patient case');\n      if (!authOk) return;\n      await CaseStorage.deleteCase(caseRecord.id);",
    "await CaseStorage.deleteCase(caseRecord.id);"
  );

  file.writeAsStringSync(content);
}
