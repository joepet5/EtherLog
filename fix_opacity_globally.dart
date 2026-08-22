import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  int count = 0;

  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains('.withOpacity(')) {
      content = content.replaceAll('.withOpacity(', '.withValues(alpha: ');
      file.writeAsStringSync(content);
      count++;
    }
  }
  print('Updated withOpacity in \ files.');
}
