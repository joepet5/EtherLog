import 'dart:io';

void main() {
  var file = File('lib/theme/app_theme.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('midnight_cyan')) {
    print('Wait, midnight_cyan is not in the file at all??');
  } else {
    print('midnight cyan is in the file.');
  }
}
