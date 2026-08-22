import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(".withOpacity(0.4)", ".withOpacity(0.65)");
  content = content.replaceAll(".withOpacity(0.3)", ".withOpacity(0.5)");

  file.writeAsStringSync(content);
}
