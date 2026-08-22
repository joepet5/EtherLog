import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    '''      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDarkLike ? const Color(0xFFFFFFFF).withValues(alpha: 0.2) : const Color(0xFF000000).withValues(alpha: 0.2), width: 1.5),
        ),
      ),''',
    '''      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDarkLike ? const Color(0xFFFFFFFF).withValues(alpha: 0.35) : const Color(0xFF000000).withValues(alpha: 0.35), width: 2.0),
        ),
      ),'''
  );

  content = content.replaceFirst(
    '''      inputDecorationTheme: InputDecorationTheme(
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
      ),''',
    '''      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkLike ? const Color(0xFFFFFFFF).withValues(alpha: 0.35) : const Color(0xFF000000).withValues(alpha: 0.35), width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkLike ? const Color(0xFFFFFFFF).withValues(alpha: 0.35) : const Color(0xFF000000).withValues(alpha: 0.35), width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2.5),
        ),
      ),'''
  );
  
  if (!content.contains('NoTransitionsBuilder')) {
    content += '''\n\nclass NoTransitionsBuilder extends PageTransitionsBuilder {
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
}\n''';

    content = content.replaceFirst(
      'return base.copyWith(',
      '''return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
          TargetPlatform.macOS: NoTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionsBuilder(),
          TargetPlatform.linux: NoTransitionsBuilder(),
        },
      ),'''
    );
  }

  file.writeAsStringSync(content);
}
