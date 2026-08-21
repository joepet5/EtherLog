import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "activeColor: primary,",
    "activeColor: primary,\n                          splashRadius: 0,"
  );
  
  file.writeAsStringSync(content);
}
