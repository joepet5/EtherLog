import 'dart:io';

void main() {
  var file = File('lib/screens/insights_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    RegExp(r"\]\),\s*\),\s*\)\s*,\s*\]\s*,\s*\)", multiLine: true), 
    "],\n                ),"
  );
  
  content = content.replaceAll(
    "]),\n                    ),\n                  ),\n              ],\n            ),",
    "],\n                ),"
  );
  file.writeAsStringSync(content);
}
