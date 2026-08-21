import 'dart:io';

void main() {
  var file = File('lib/services/backup_service.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('performAutoBackupIfNeeded')) {
    content = content.replaceFirst(
      "import '../services/case_storage.dart';",
      "import '../services/case_storage.dart';\nimport 'package:shared_preferences/shared_preferences.dart';"
    );
    
    content = content.replaceFirst(
      "class BackupService {",
      "class BackupService {\n  static const _lastAutoBackupKey = 'last_auto_backup_date';\n\n  static Future<void> performAutoBackupIfNeeded() async {\n    final prefs = await SharedPreferences.getInstance();\n    final lastDateStr = prefs.getString(_lastAutoBackupKey);\n    \n    if (lastDateStr != null) {\n      final lastDate = DateTime.tryParse(lastDateStr);\n      if (lastDate != null && DateTime.now().difference(lastDate).inDays < 7) {\n        return;\n      }\n    }\n    \n    final cases = await CaseStorage.getAllCases();\n    if (cases.isEmpty) return;\n\n    final jsonList = cases.map((c) => c.toJson()).toList();\n    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);\n\n    final directory = await getApplicationDocumentsDirectory();\n    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;\n    final fileName = 'etherlog_auto_backup_\.json';\n    final filePath = '\/\';\n\n    final file = File(filePath);\n    await file.writeAsString(jsonString);\n    \n    await prefs.setString(_lastAutoBackupKey, DateTime.now().toIso8601String());\n  }"
    );
  }
  
  file.writeAsStringSync(content);
}
