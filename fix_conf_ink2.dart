import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    RegExp(r"InkWell\(\s*key: const ValueKey\('confidentiality_agree_row'\),\s*onTap:\s*\(\)\s*\{\s*setState\(\(\)\s*\{\s*_agreedToConfidentiality = !_agreedToConfidentiality;\s*\}\);\s*\},\s*borderRadius:\s*BorderRadius\.circular\(8\),"),
    "GestureDetector(\n                key: const ValueKey('confidentiality_agree_row'),\n                onTap: () {\n                  setState(() {\n                    _agreedToConfidentiality = !_agreedToConfidentiality;\n                  });\n                },\n                behavior: HitTestBehavior.opaque,"
  );
  
  file.writeAsStringSync(content);
}
