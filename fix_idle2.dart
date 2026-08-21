import 'dart:io';

void main() {
  var file = File('lib/widgets/idle_animation_overlay.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "class IdleAnimationOverlay extends StatefulWidget {\n  final Widget child;\n  final Duration idleAfter;\n\n  const IdleAnimationOverlay({\n    super.key,\n    required this.child,\n    this.idleAfter = const Duration(seconds: 30),\n  });",
    "class IdleAnimationOverlay extends StatefulWidget {\n  final Widget child;\n  final Duration idleAfter;\n  final bool enabled;\n\n  const IdleAnimationOverlay({\n    super.key,\n    required this.child,\n    this.enabled = true,\n    this.idleAfter = const Duration(seconds: 30),\n  });"
  );
  
  file.writeAsStringSync(content);
}
