import 'dart:io';

void main() {
  var file = File('lib/screens/profile_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    RegExp(r"case 'night_shift':\s*return l10n.themeNightShift;"),
    "case 'night_shift':\n        return l10n.themeNightShift;\n      case 'midnight_cyan':\n        return 'Midnight Cyan';"
  );
  file.writeAsStringSync(content);
}
