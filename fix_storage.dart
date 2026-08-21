import 'dart:io';

void main() {
  var file = File('lib/services/profile_storage.dart');
  var content = file.readAsStringSync();
  
  // Undo the bad injection
  content = content.replaceFirst(
    "  static Future<bool> getGlassmorphism() async {\n    final prefs = await SharedPreferences.getInstance();\n    return prefs.getBool(_glassmorphismKey) ?? true;\n  }\n\n  static Future<void> setGlassmorphism(bool value) async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setBool(_glassmorphismKey, value);\n  }\n}",
    "}"
  );
  
  // Inject at the very end (before the last closing brace)
  var lastBraceIndex = content.lastIndexOf('}');
  if (lastBraceIndex != -1) {
    var before = content.substring(0, lastBraceIndex);
    var after = content.substring(lastBraceIndex);
    content = before + "  static Future<bool> getGlassmorphism() async {\n    final prefs = await SharedPreferences.getInstance();\n    return prefs.getBool(_glassmorphismKey) ?? true;\n  }\n\n  static Future<void> setGlassmorphism(bool value) async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setBool(_glassmorphismKey, value);\n  }\n" + after;
  }
  
  file.writeAsStringSync(content);
}
