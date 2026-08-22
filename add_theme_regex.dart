import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  
  // 1. Add to themes list
  content = content.replaceAll(
    RegExp(r"(\s*)\];\s*\n\s*/// Apply a full theme palette by key."),
    ",\n      {\n        'key': 'midnight_cyan',\n        'label': 'Midnight Cyan',\n        'swatch': Color(0xFF040B16),\n        'accent': Color(0xFF00E5FF),\n      }\n    ];\n\n  /// Apply a full theme palette by key."
  );

  // 2. Add case block to applyTheme
  content = content.replaceAll(
    RegExp(r"case 'night_shift':([\s\S]*?)break;"),
    '''case 'night_shift':\;
      case 'midnight_cyan':
        background = const Color(0xFF020617);
        surface = const Color(0xFF0F172A).withOpacity(0.65);
        surfaceSolid = const Color(0xFF0F172A);
        surfaceLight = const Color(0xFF1E293B).withOpacity(0.5);
        primary = const Color(0xFF00E5FF);
        textPrimary = const Color(0xFFF8FAFC);
        textSecondary = const Color(0xFF94A3B8);
        danger = const Color(0xFFFF1744);
        success = const Color(0xFF00E676);
        warning = const Color(0xFFFFEA00);
        break;'''
  );
  
  file.writeAsStringSync(content);
}
