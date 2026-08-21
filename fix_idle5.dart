import 'dart:io';

void main() {
  var file = File('lib/widgets/idle_animation_overlay.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "_idleTimer = Timer(widget.idleAfter, _onIdle);",
    "if (!widget.enabled) return;\n    _idleTimer = Timer(widget.idleAfter, _onIdle);"
  );
  
  content = content.replaceAll(
    "void _onIdle() {\n    if (!mounted) return;",
    "void _onIdle() {\n    if (!mounted || !widget.enabled) return;"
  );
  
  file.writeAsStringSync(content);
}
