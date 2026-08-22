import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    RegExp(r"child: ElevatedButton\([\s\S]*?child: Text\(t\.getStarted, style: const TextStyle\(fontSize: 16\)\),\s*\),"),
    "child: ElevatedButton(\n                  onPressed: () {\n                    if (_agreedToConfidentiality) widget.onAccepted();\n                  },\n                  style: ElevatedButton.styleFrom(\n                    splashFactory: NoSplash.splashFactory,\n                    backgroundColor: _agreedToConfidentiality ? AppTheme.primary : Colors.grey.shade400,\n                    foregroundColor: Colors.white,\n                  ),\n                  child: Text(t.getStarted, style: const TextStyle(fontSize: 16)),\n                ),"
  );
  
  file.writeAsStringSync(content);
}
