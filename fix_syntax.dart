import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "child: Material(\n                          type: MaterialType.transparency,\n                          child: Checkbox(",
    "child: Checkbox("
  );
  
  // Need to fix the closing parenthesis which might be messed up.
  // Actually, let's just use regex to clean up the Checkbox area up to SizedBox(width: 12).
  content = content.replaceFirst(
    RegExp(r"child: Checkbox\([\s\S]*?const SizedBox\(width: 12\),"),
    "child: Checkbox(\n                          value: _agreedToConfidentiality,\n                          activeColor: primary,\n                          splashRadius: 0,\n                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,\n                          onChanged: (val) {\n                            setState(() {\n                              _agreedToConfidentiality = val ?? false;\n                            });\n                          },\n                        ),\n                      ),\n                      const SizedBox(width: 12),"
  );
  
  file.writeAsStringSync(content);
}
