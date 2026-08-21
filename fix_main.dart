import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('setGlassmorphism')) {
    content = content.replaceFirst(
      "void setIdleAnimationEnabled(bool value) {",
      "void setGlassmorphism(bool value) {\n    setState(() => _glassmorphismEnabled = value);\n  }\n\n  void setIdleAnimationEnabled(bool value) {"
    );
  }
  
  file.writeAsStringSync(content);
}
