import 'dart:io';

void main() {
  var file = File('lib/screens/profile_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('final glass =')) {
    content = content.replaceFirst(
      "final haptics = await ProfileStorage.isHapticsEnabled();",
      "final haptics = await ProfileStorage.isHapticsEnabled();\n    final glass = await ProfileStorage.getGlassmorphism();"
    );
  }
  
  file.writeAsStringSync(content);
}
