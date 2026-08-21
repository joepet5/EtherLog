import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst("import 'services/profile_storage.dart';", "import 'services/profile_storage.dart';\nimport 'services/backup_service.dart';");
  
  content = content.replaceFirst(
    "NotificationService.syncInactivityReminder();",
    "NotificationService.syncInactivityReminder();\n    BackupService.performAutoBackupIfNeeded();"
  );
  
  file.writeAsStringSync(content);
}
