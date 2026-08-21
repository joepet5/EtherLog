import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "          if (_idleAnimationEnabled && _unlocked && !_needsConfidentiality) {\n            return IdleAnimationOverlay(child: content);\n          }\n          return content;\n        },\n        home: _needsConfidentiality",
    "          final bool enableIdle = _idleAnimationEnabled && _unlocked && !_needsConfidentiality;\n          return IdleAnimationOverlay(\n            enabled: enableIdle,\n            child: content,\n          );\n        },\n        home: _needsConfidentiality"
  );
  
  file.writeAsStringSync(content);
}
