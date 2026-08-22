import 'dart:io';

void main() {
  var file = File('lib/services/achievement_service.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    '''  static Future<List<Achievement>> getAllAchievements(List<CaseRecord> cases) async {
    int pdfExportCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      pdfExportCount = prefs.getInt('pdf_export_count') ?? 0;
    } catch (_) {}''',
    '''  static Future<List<Achievement>> getAllAchievements(List<CaseRecord> cases) async {
    int pdfExportCount = 0;
    int jsonBackupCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      pdfExportCount = prefs.getInt('pdf_export_count') ?? 0;
      jsonBackupCount = prefs.getInt('json_backup_count') ?? 0;
    } catch (_) {}'''
  );

  content = content.replaceFirst(
    "else if (lowerTitle == 'data scientist') current = totalCases >= 1 ? 1 : 0;",
    "else if (lowerTitle == 'data scientist') current = pdfExportCount.clamp(0, 1);"
  );

  content = content.replaceFirst(
    "else if (lowerTitle == 'safety first' || lowerTitle == 'backup fanatic') current = totalCases >= 10 ? 10 : totalCases;",
    "else if (lowerTitle == 'safety first' || lowerTitle == 'backup fanatic') current = jsonBackupCount;"
  );

  file.writeAsStringSync(content);
}
