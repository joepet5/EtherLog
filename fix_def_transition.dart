import 'dart:io';

void main() {
  var file = File('lib/services/profile_storage.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    "return prefs.getString(_transitionKey) ?? 'fade';",
    "return prefs.getString(_transitionKey) ?? 'none';"
  );
  file.writeAsStringSync(content);
}
