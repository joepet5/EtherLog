import 'dart:io';

void main() {
  var file = File('lib/utils/page_transitions.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "static Future<T?> push<T>(BuildContext context, Widget page) async {",
    "static Future<T?> push<T>(BuildContext context, Widget page, {bool noAnimation = false}) async {\n    if (noAnimation) {\n      return Navigator.push<T>(\n        context,\n        PageRouteBuilder(\n          pageBuilder: (_, __, ___) => page,\n          transitionDuration: Duration.zero,\n          reverseTransitionDuration: Duration.zero,\n        ),\n      );\n    }"
  );
  
  file.writeAsStringSync(content);
}
