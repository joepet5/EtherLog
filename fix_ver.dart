import 'dart:io';

void main() {
  var file = File('pubspec.yaml');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    RegExp(r'version: 2\.8\.0\+1'),
    'version: 2.9.0+1'
  );
  content = content.replaceFirst(
    RegExp(r'version: 2\.8\.[0-9]+\+[0-9]+'),
    'version: 2.9.0+1'
  );
  file.writeAsStringSync(content);
}
