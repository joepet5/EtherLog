import 'dart:io';

void main() {
  var file = File('lib/screens/dashboard_screen.dart');
  var content = file.readAsStringSync();

  var lines = content.split('\n');
  int startIndex = -1;
  int endIndex = -1;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('itemBuilder: (context, index) {')) {
      startIndex = i;
    }
    if (startIndex != -1 && i > startIndex && lines[i].contains(');') && lines[i-1].contains('}')) {
      if (lines[i].trim() == ');' && lines[i-1].trim() == '},') {
        endIndex = i;
        break;
      }
    }
  }
  
  print('Start: \, End: \');
}
