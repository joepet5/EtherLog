import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(RegExp(r"\s*key:\s*const ValueKey\('[^']+'\),"), "");
  
  file.writeAsStringSync(content);
}
