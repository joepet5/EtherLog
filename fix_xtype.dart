import 'dart:io';

void main() {
  var file = File('lib/services/backup_service.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    "const typeGroup = XTypeGroup(\n      label: 'JSON',\n      extensions: ['json'],\n    );",
    "const typeGroup = XTypeGroup(\n      label: 'JSON',\n      extensions: ['json'],\n      uniformTypeIdentifiers: ['public.json', 'public.text'],\n      mimeTypes: ['application/json'],\n    );"
  );
  file.writeAsStringSync(content);
}
