import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("AppTheme.primary", "primary");
  file.writeAsStringSync(content);
}
