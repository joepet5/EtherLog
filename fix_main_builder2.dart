import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    RegExp(r"if \(_idleAnimationEnabled && _unlocked && !_needsConfidentiality\) \{\s*return IdleAnimationOverlay\(child: content\);\s*\}\s*return content;"),
    "final bool enableIdle = _idleAnimationEnabled && _unlocked && !_needsConfidentiality;\n          return IdleAnimationOverlay(\n            enabled: enableIdle,\n            child: content,\n          );"
  );
  
  file.writeAsStringSync(content);
}
