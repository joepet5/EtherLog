import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "InkWell(\n                key: const ValueKey('confidentiality_agree_row'),\n                onTap: () {\n                  setState(() {\n                    _agreedToConfidentiality = !_agreedToConfidentiality;\n                  });\n                },\n                borderRadius: BorderRadius.circular(8),\n                child: Padding(",
    "GestureDetector(\n                key: const ValueKey('confidentiality_agree_row'),\n                onTap: () {\n                  setState(() {\n                    _agreedToConfidentiality = !_agreedToConfidentiality;\n                  });\n                },\n                behavior: HitTestBehavior.opaque,\n                child: Padding("
  );
  
  file.writeAsStringSync(content);
}
