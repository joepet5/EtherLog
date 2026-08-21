import 'dart:io';

void main() {
  var file = File('lib/screens/insights_screen.dart');
  var content = file.readAsStringSync();
  
  var originalStart = content.indexOf("import 'package:flutter/material.dart';", 50);
  if (originalStart != -1) {
    var fixedContent = content.substring(originalStart);
    file.writeAsStringSync(fixedContent);
    print("Fixed file!");
  }
}
