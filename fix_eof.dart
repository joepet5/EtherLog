import 'dart:io';

void main() {
  var file = File('lib/screens/insights_screen.dart');
  var content = file.readAsStringSync();
  
  var index = content.indexOf("year',\n              style: TextStyle(");
  if (index != -1) {
    content = content.substring(0, index);
    file.writeAsStringSync(content);
    print("Fixed corrupted file EOF!");
  } else {
    print("Could not find the corrupted block.");
  }
}
