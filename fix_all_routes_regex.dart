import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains('MaterialPageRoute')) {
      // Replace all variations of MaterialPageRoute with PageRouteBuilder
      content = content.replaceAll(
        RegExp(r'MaterialPageRoute\s*\(\s*builder:\s*\([^\)]*\)\s*=>\s*'),
        'PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => '
      );
      file.writeAsStringSync(content);
    }
  }
}
