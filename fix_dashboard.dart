import 'dart:io';

void main() {
  var file = File('lib/screens/dashboard_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    RegExp(r"final result = await AppPageRoute\.push\([\s\n]+context,[\s\n]+CaseDetailScreen\(caseRecord: c\),[\s\n]+\);"),
    "final result = await AppPageRoute.push(context, CaseDetailScreen(caseRecord: c), noAnimation: true);"
  );
  
  file.writeAsStringSync(content);
}
