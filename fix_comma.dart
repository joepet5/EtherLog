import 'dart:io';

void main() {
  var file = File('lib/screens/insights_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst("],\n                ),,", "],\n                ),");
  file.writeAsStringSync(content);
}
