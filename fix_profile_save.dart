import 'dart:io';

void main() {
  var file = File('lib/screens/profile_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst("await ProfileStorage.setHapticsEnabled(_hapticsEnabled);", "await ProfileStorage.setHapticsEnabled(_hapticsEnabled);\n    await ProfileStorage.setGlassmorphism(_glassmorphismEnabled);");
  file.writeAsStringSync(content);
}
