import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "side: BorderSide(color: surfaceLight.withOpacity(0.6)),",
    "side: BorderSide(color: isDarkLike ? const Color(0xFFFFFFFF).withValues(alpha: 0.2) : const Color(0xFF000000).withValues(alpha: 0.2), width: 1.5),"
  );

  file.writeAsStringSync(content);
}
