import 'dart:io';

void main() {
  var file = File('lib/widgets/idle_animation_overlay.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    RegExp(r"_idleTimer = Timer\(widget.idleAfter, \(\) \{\s*if \(!mounted\) return;"),
    "if (!widget.enabled) return;\n    _idleTimer = Timer(widget.idleAfter, () {\n      if (!mounted || !widget.enabled) return;"
  );
  
  file.writeAsStringSync(content);
}
