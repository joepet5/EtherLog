import 'package:flutter/material.dart';

/// Global theme palette used across Etherlog.
/// Call [applyTheme] / [applyAccent] before building UI that reads these colours.
class AppTheme {
  static String _themeKey = 'dark';
  static String _accentKey = 'default';

  // Mutable palette (read by screens)
  static Color background = const Color(0xFF0F172A);
  static Color surface = const Color(0xFF1E293B).withOpacity(0.65);
  static Color surfaceSolid = const Color(0xFF1E293B);
  static Color surfaceLight = const Color(0xFF334155).withOpacity(0.5);
  static Color primary = const Color(0xFF2563EB);
  static Color textPrimary = const Color(0xFFF1F5F9);
  static Color textSecondary = const Color(0xFF94A3B8);
  static Color danger = const Color(0xFFEF4444);
  static Color success = const Color(0xFF22C55E);
  static Color warning = const Color(0xFFF59E0B);

  static String get themeKey => _themeKey;
  static String get accentKey => _accentKey;

  static bool get isDarkLike => ['dark', 'midnight_cyan'].contains(_themeKey);

  /// Accent colour options (used mainly on Light / Dark).
  static final Map<String, Color> accentColours = {
    'default': const Color(0xFF2563EB),
    'surgical_emerald': const Color(0xFF059669),
    'medical_teal': const Color(0xFF0891B2),
    'royal_violet': const Color(0xFF7C3AED),
    'surgical_rose': const Color(0xFFE11D48),
    'amber_gold': const Color(0xFFD97706),
  };

  static const themes = [
    {
      'key': 'dark',
      'label': 'Dark',
      'swatch': Color(0xFF0F172A),
      'accent': Color(0xFF2563EB),
    },
    {
      'key': 'light',
      'label': 'Light',
      'swatch': Color(0xFFF8FAFC),
      'accent': Color(0xFF2563EB),
    },
    {
      'key': 'serenity',
      'label': 'Serenity',
      'swatch': Color(0xFFFAFAFA),
      'accent': Color(0xFF8DA399),
    },
    {
      'key': 'night_shift',
      'label': 'Night Shift',
      'swatch': Color(0xFFF5E6D3),
      'accent': Color(0xFFD35400),
    }
      {
        'key': 'midnight_cyan',
        'label': 'Midnight Cyan',
        'swatch': Color(0xFF040B16),
        'accent': Color(0xFF00E5FF),
      }
    ];

  /// Apply a full theme palette by key.
  static void applyTheme(String key) {
    _themeKey = key;
    switch (key) {
      case 'light':
        background = const Color(0xFFFAFAFA);
        surface = const Color(0xFFFFFFFF).withOpacity(0.65);
          surfaceSolid = const Color(0xFFFFFFFF);
        surfaceLight = const Color(0xFFE2E8F0).withOpacity(0.5);
        primary = const Color(0xFF2563EB);
        textPrimary = const Color(0xFF0F172A);
        textSecondary = const Color(0xFF64748B);
        danger = const Color(0xFFDC2626);
        success = const Color(0xFF16A34A);
        warning = const Color(0xFFD97706);
        break;
      case 'serenity':
      // Soft alabaster + mint surfaces + dusty sage
        background = const Color(0xFFF8FAFC);
        surface = const Color(0xFFEDF7F6).withOpacity(0.65);
          surfaceSolid = const Color(0xFFEDF7F6);
        surfaceLight = const Color(0xFFD8E8E6).withOpacity(0.5);
        primary = const Color(0xFF8DA399);
        textPrimary = const Color(0xFF4A4A4A);
        textSecondary = const Color(0xFF6B7280);
        danger = const Color(0xFFC45C5C);
        success = const Color(0xFF6B9B7A);
        warning = const Color(0xFFC4A35A);
        break;
      case 'night_shift':
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
        break;
      case 'dark':
      default:
        _themeKey = 'dark';
        background = const Color(0xFF0F172A);
        surface = const Color(0xFF1E293B).withOpacity(0.65);
          surfaceSolid = const Color(0xFF1E293B);
        surfaceLight = const Color(0xFF334155).withOpacity(0.5);
        primary = const Color(0xFF2563EB);
        textPrimary = const Color(0xFFF1F5F9);
        textSecondary = const Color(0xFF94A3B8);
        danger = const Color(0xFFEF4444);
        success = const Color(0xFF22C55E);
        warning = const Color(0xFFF59E0B);
        break;
    }

    // Re-apply accent for Light / Dark only (special themes keep their fixed primary)
    if (_themeKey == 'light' || _themeKey == 'dark') {
      applyAccent(_accentKey);
    }
  }

  /// Legacy helper used by older call sites.
  static void applyBrightness(bool isDark) {
    applyTheme(isDark ? 'dark' : 'light');
  }

  static void applyAccent(String key) {
    _accentKey = key;
    // Only override primary on Light / Dark so Serenity / Executive / Night Shift stay true to design
    if (_themeKey == 'light' || _themeKey == 'dark') {
      primary = accentColours[key] ?? accentColours['default']!;
    }
  }

  static ThemeData get lightTheme => _buildThemeData(Brightness.light);
  static ThemeData get darkTheme => _buildThemeData(Brightness.dark);

  /// Preferred: single theme built from current palette.
  static ThemeData get currentTheme => _buildThemeData(
    isDarkLike ? Brightness.dark : Brightness.light,
  );

  static ThemeData _buildThemeData(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
          TargetPlatform.macOS: NoTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionsBuilder(),
          TargetPlatform.linux: NoTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: primary,
      canvasColor: surfaceSolid,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: isDarkLike ? const Color(0xFF0B132B) : Colors.white,
        secondary: primary,
        onSecondary: Colors.white,
        error: danger,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainer: surfaceSolid,
        surfaceContainerHigh: surfaceSolid,
        surfaceContainerHighest: surfaceSolid,
        surfaceContainerLow: surfaceSolid,
        surfaceContainerLowest: surfaceSolid,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceSolid,
        textStyle: TextStyle(color: textPrimary),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            surfaceSolid,
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            surfaceSolid,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDarkLike ? const Color(0xFFFFFFFF).withValues(alpha: 0.2) : const Color(0xFF000000).withValues(alpha: 0.2), width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surfaceSolid),
        datePickerTheme: DatePickerThemeData(backgroundColor: surfaceSolid),
      timePickerTheme: TimePickerThemeData(backgroundColor: surfaceSolid),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceSolid,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? primary : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? primary.withOpacity(0.45)
              : surfaceLight,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDarkLike ? surfaceSolid : const Color(0xFF1E293B),
        contentTextStyle: TextStyle(color: textPrimary),
        actionTextColor: primary,
      ),
      dividerColor: surfaceLight,
      iconTheme: IconThemeData(color: textPrimary),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return child;
  }
}
