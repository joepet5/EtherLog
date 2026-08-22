import 'dart:io';

void main() {
  var file = File('lib/screens/profile_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    '''  String _getThemeLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'light':
        return l10n.themeLight;
      case 'serenity':
        return l10n.themeSerenity;
      case 'night_shift':
        return l10n.themeNightShift;
      case 'dark':
      default:
        return l10n.themeDark;
    }
  }''',
    '''  String _getThemeLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'light':
        return l10n.themeLight;
      case 'serenity':
        return l10n.themeSerenity;
      case 'night_shift':
        return l10n.themeNightShift;
      case 'midnight_cyan':
        return 'Midnight Cyan';
      case 'dark':
      default:
        return l10n.themeDark;
    }
  }'''
  );
  file.writeAsStringSync(content);
}
