import 'dart:io';

void main() {
  var file = File('lib/utils/page_transitions.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('AnimatedGradientBackground')) {
    content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../widgets/animated_gradient_background.dart';\nimport '../main.dart';");
    content = content.replaceFirst(
      "pageBuilder: (context, animation, secondaryAnimation) => page,",
      "pageBuilder: (context, animation, secondaryAnimation) => Stack(children: [ if (EtherlogAppState.glassmorphismEnabledNotifier.value) const Positioned.fill(child: AnimatedGradientBackground()), page ]),"
    );
  }
  file.writeAsStringSync(content);
}
