import 'dart:io';

void main() {
  var file = File('lib/widgets/idle_animation_overlay.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    RegExp(r"final Duration idleAfter;\s*const IdleAnimationOverlay\(\{"),
    "final Duration idleAfter;\n  final bool enabled;\n\n  const IdleAnimationOverlay({"
  );
  
  content = content.replaceAll(
    RegExp(r"required this\.child,\s*this\.idleAfter = const Duration\(seconds: 30\),\s*\}\);"),
    "required this.child,\n    this.enabled = true,\n    this.idleAfter = const Duration(seconds: 30),\n  });"
  );
  
  file.writeAsStringSync(content);
}
