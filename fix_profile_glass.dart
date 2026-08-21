import 'dart:io';

void main() {
  var file = File('lib/screens/profile_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "    return Scaffold(\n      backgroundColor: theme.scaffoldBackgroundColor,",
    "    return Stack(\n      children: [\n        if (_glassmorphismEnabled) const Positioned.fill(child: AnimatedGradientBackground()),\n        Scaffold(\n          backgroundColor: Colors.transparent,"
  );
  
  content = content.replaceFirst(
    "        ],\n      ),\n    );\n  }\n\n  Widget _sectionTitle(",
    "        ],\n      ),\n    ),\n      ],\n    );\n  }\n\n  Widget _sectionTitle("
  );

  file.writeAsStringSync(content);
}
