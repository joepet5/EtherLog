import 'dart:io';

void main() {
  var file = File('lib/widgets/idle_animation_overlay.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "  final Widget child;\n  final Duration idleAfter;\n\n  const IdleAnimationOverlay({\n    super.key,\n    required this.child,\n    this.idleAfter = const Duration(seconds: 30),\n  });",
    "  final Widget child;\n  final Duration idleAfter;\n  final bool enabled;\n\n  const IdleAnimationOverlay({\n    super.key,\n    required this.child,\n    this.enabled = true,\n    this.idleAfter = const Duration(seconds: 30),\n  });"
  );
  
  content = content.replaceFirst(
    "  void _resetIdleTimer() {\n    _idleTimer?.cancel();\n    if (_showOverlay) {\n      setState(() {\n        _showOverlay = false;\n      });\n      _controller.stop();\n    }\n    _idleTimer = Timer(widget.idleAfter, () {\n      if (!mounted) return;",
    "  void _resetIdleTimer() {\n    _idleTimer?.cancel();\n    if (_showOverlay) {\n      setState(() {\n        _showOverlay = false;\n      });\n      _controller.stop();\n    }\n    if (!widget.enabled) return;\n    _idleTimer = Timer(widget.idleAfter, () {\n      if (!mounted || !widget.enabled) return;"
  );
  
  content = content.replaceFirst(
    "  void initState() {\n    super.initState();",
    "  void initState() {\n    super.initState();"
  );
  
  content = content.replaceFirst(
    "  void dispose() {",
    "  @override\n  void didUpdateWidget(IdleAnimationOverlay oldWidget) {\n    super.didUpdateWidget(oldWidget);\n    if (widget.enabled != oldWidget.enabled) {\n      _resetIdleTimer();\n    }\n  }\n\n  @override\n  void dispose() {"
  );
  
  file.writeAsStringSync(content);
}
