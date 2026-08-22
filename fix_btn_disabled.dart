import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "onPressed: _agreedToConfidentiality ? widget.onAccepted : null,\n                  style: ElevatedButton.styleFrom(splashFactory: NoSplash.splashFactory),\n                  child: Text(t.getStarted, style: const TextStyle(fontSize: 16)),",
    "onPressed: () {\n                    if (_agreedToConfidentiality) widget.onAccepted();\n                  },\n                  style: ElevatedButton.styleFrom(\n                    splashFactory: NoSplash.splashFactory,\n                    backgroundColor: _agreedToConfidentiality ? primary : Colors.grey.shade400,\n                    foregroundColor: Colors.white,\n                  ),\n                  child: Text(t.getStarted, style: const TextStyle(fontSize: 16)),"
  );
  
  file.writeAsStringSync(content);
}
