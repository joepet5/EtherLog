import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "canvasColor: isDarkLike ? const Color(0xFF000000).withOpacity(0.4) : (brightness == Brightness.dark ? const Color(0xFF000000).withOpacity(0.4) : surface),",
    "canvasColor: surfaceSolid,"
  );
  
  // Let's also add DatePickerThemeData, TimePickerThemeData
  content = content.replaceFirst(
    "dialogTheme: DialogThemeData(",
    "datePickerTheme: DatePickerThemeData(backgroundColor: surfaceSolid),\n      timePickerTheme: TimePickerThemeData(backgroundColor: surfaceSolid),\n      dialogTheme: DialogThemeData("
  );
  
  file.writeAsStringSync(content);
}
