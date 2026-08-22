import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  
  // 1. Add to themes list
  content = content.replaceFirst(
    '''    {
      'key': 'night_shift',
      'label': 'Night Shift',
      'swatch': Color(0xFFF5E6D3),
      'accent': Color(0xFFD35400),
    },''',
    '''    {
      'key': 'night_shift',
      'label': 'Night Shift',
      'swatch': Color(0xFFF5E6D3),
      'accent': Color(0xFFD35400),
    },
    {
      'key': 'midnight_cyan',
      'label': 'Midnight Cyan',
      'swatch': Color(0xFF040B16),
      'accent': Color(0xFF00E5FF),
    },'''
  );

  // 2. Add case block to applyTheme
  content = content.replaceFirst(
    '''      case 'night_shift':
      // Warm parchment / sepia / amber (blue-light reducer)
        background = const Color(0xFFF5E6D3);
        surface = const Color(0xFFEFE0C8).withOpacity(0.65);
          surfaceSolid = const Color(0xFFEFE0C8);
        surfaceLight = const Color(0xFFDCC9A8).withOpacity(0.5);
        primary = const Color(0xFFD35400);
        textPrimary = const Color(0xFF3E2723);
        textSecondary = const Color(0xFF6D4C41);
        danger = const Color(0xFFB71C1C);
        success = const Color(0xFF2E7D32);
        warning = const Color(0xFFE65100);
        break;''',
    '''      case 'night_shift':
      // Warm parchment / sepia / amber (blue-light reducer)
        background = const Color(0xFFF5E6D3);
        surface = const Color(0xFFEFE0C8).withOpacity(0.65);
          surfaceSolid = const Color(0xFFEFE0C8);
        surfaceLight = const Color(0xFFDCC9A8).withOpacity(0.5);
        primary = const Color(0xFFD35400);
        textPrimary = const Color(0xFF3E2723);
        textSecondary = const Color(0xFF6D4C41);
        danger = const Color(0xFFB71C1C);
        success = const Color(0xFF2E7D32);
        warning = const Color(0xFFE65100);
        break;
      case 'midnight_cyan':
        background = const Color(0xFF020617);       // Extremely dark navy/black
        surface = const Color(0xFF0F172A).withOpacity(0.65);
          surfaceSolid = const Color(0xFF0F172A);
        surfaceLight = const Color(0xFF1E293B).withOpacity(0.5);
        primary = const Color(0xFF00E5FF);          // Bright Neon Cyan
        textPrimary = const Color(0xFFF8FAFC);
        textSecondary = const Color(0xFF94A3B8);
        danger = const Color(0xFFFF1744);           // Neon Red
        success = const Color(0xFF00E676);          // Neon Green
        warning = const Color(0xFFFFEA00);          // Neon Yellow
        break;'''
  );

  // 3. Update isDarkLike
  content = content.replaceFirst(
    "static bool get isDarkLike => _themeKey == 'dark';",
    "static bool get isDarkLike => ['dark', 'midnight_cyan'].contains(_themeKey);"
  );
  
  file.writeAsStringSync(content);
}
