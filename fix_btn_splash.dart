import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "child: ElevatedButton(\n                  onPressed: _agreedToConfidentiality ? widget.onAccepted : null,\n                  child: Text(t.getStarted, style: const TextStyle(fontSize: 16)),",
    "child: ElevatedButton(\n                  onPressed: _agreedToConfidentiality ? widget.onAccepted : null,\n                  style: ElevatedButton.styleFrom(splashFactory: NoSplash.splashFactory),\n                  child: Text(t.getStarted, style: const TextStyle(fontSize: 16)),"
  );
  
  file.writeAsStringSync(content);
}
