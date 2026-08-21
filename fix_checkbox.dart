import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "child: Checkbox(",
    "child: Material(\n                          type: MaterialType.transparency,\n                          child: Checkbox("
  );
  
  // Need to close the Material widget
  content = content.replaceFirst(
    "                          onChanged: (val) {\n                            setState(() {\n                              _agreedToConfidentiality = val ?? false;\n                            });\n                          },\n                        ),",
    "                          onChanged: (val) {\n                            setState(() {\n                              _agreedToConfidentiality = val ?? false;\n                            });\n                          },\n                        ),\n                        ),"
  );
  
  file.writeAsStringSync(content);
}
