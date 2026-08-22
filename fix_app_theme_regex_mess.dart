import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll('},,', '}');
  content = content.replaceAll("case 'night_shift':;", "case 'night_shift':\n      // Warm parchment / sepia / amber (blue-light reducer)\n        background = const Color(0xFFF5E6D3);\n        surface = const Color(0xFFEFE0C8).withOpacity(0.65);\n          surfaceSolid = const Color(0xFFEFE0C8);\n        surfaceLight = const Color(0xFFDCC9A8).withOpacity(0.5);\n        primary = const Color(0xFFD35400);\n        textPrimary = const Color(0xFF3E2723);\n        textSecondary = const Color(0xFF6D4C41);\n        danger = const Color(0xFFB71C1C);\n        success = const Color(0xFF2E7D32);\n        warning = const Color(0xFFE65100);\n        break;");

  file.writeAsStringSync(content);
}
