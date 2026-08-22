import 'dart:io';

void main() {
  var file = File('lib/services/backup_service.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    '''    const typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
    );''',
    '''    const typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      uniformTypeIdentifiers: ['public.json', 'public.text'],
      macUTIs: ['public.json', 'public.text'],
      mimeTypes: ['application/json'],
    );'''
  );
  file.writeAsStringSync(content);
}
