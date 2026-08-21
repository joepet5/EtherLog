import 'dart:io';

void main() {
  var file = File('lib/screens/insights_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst("child: Text(\n              '\\',", "child: Text(\n              '\$"+"_year',");
  file.writeAsStringSync(content);
}
