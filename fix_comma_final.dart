import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(RegExp(r"\}\s*\{"), "},\n      {");
  file.writeAsStringSync(content);
}
