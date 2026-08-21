import 'dart:io';

void main() {
  var file = File('lib/utils/page_transitions.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst("import '../widgets/animated_gradient_background.dart';\nimport '../main.dart';", "");
  content = content.replaceFirst(
    "pageBuilder: (context, animation, secondaryAnimation) => Stack(children: [ if (EtherlogAppState.glassmorphismEnabledNotifier.value) const Positioned.fill(child: AnimatedGradientBackground()), page ]),",
    "pageBuilder: (context, animation, secondaryAnimation) => page,"
  );
  file.writeAsStringSync(content);
}
