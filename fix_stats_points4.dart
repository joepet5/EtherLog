import 'dart:io';

void main() {
  var file = File('lib/screens/statistics_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    RegExp(r"\],\s*\),\s*\),\s*const SizedBox\(height: 12\),\s*_summaryCard\("),
    "],\n            ),\n          ),\n          ),\n          const SizedBox(height: 12),\n          _summaryCard("
  );
  
  file.writeAsStringSync(content);
}
