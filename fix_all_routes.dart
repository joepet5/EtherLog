import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains('MaterialPageRoute')) {
      content = content.replaceAll(
        'MaterialPageRoute(builder: (_) => ',
        'PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => '
      );
      content = content.replaceAll(
        'MaterialPageRoute(builder: (context) => ',
        'PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => '
      );
      content = content.replaceAll(
        'MaterialPageRoute(\n        builder: (context) => ',
        'PageRouteBuilder(\n        transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => '
      );
      content = content.replaceAll(
        'MaterialPageRoute(\n                              builder: (context) =>',
        'PageRouteBuilder(\n                              transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) =>'
      );
      file.writeAsStringSync(content);
    }
  }
}
