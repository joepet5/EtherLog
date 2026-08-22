import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/case_record.dart';
import '../services/case_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const _lastAutoBackupKey = 'last_auto_backup_date';

  static Future<void> performAutoBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastAutoBackupKey);
    
    if (lastDateStr != null) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null && DateTime.now().difference(lastDate).inDays < 7) {
        return;
      }
    }
    
    final cases = await CaseStorage.getAllCases();
    if (cases.isEmpty) return;

    final jsonList = cases.map((c) => c.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = 'etherlog_auto_backup_.json';
    final filePath = '/';

    final file = File(filePath);
    await file.writeAsString(jsonString);
    
    await prefs.setString(_lastAutoBackupKey, DateTime.now().toIso8601String());
  }
  static Future<String?> exportToJson() async {
    final cases = await CaseStorage.getAllCases();
    if (cases.isEmpty) return null;

    final jsonList = cases.map((c) => c.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'etherlog_backup_$timestamp.json';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'ETHERLOG Backup – $fileName',
    );

    // Track achievement stats
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('json_backup_count') ?? 0;
    await prefs.setInt('json_backup_count', currentCount + 1);

    return fileName;
  }

  static Future<int> importFromJson() async {
    const typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      uniformTypeIdentifiers: ['public.json', 'public.text'],
      mimeTypes: ['application/json'],
    );

    final XFile? picked = await openFile(
      acceptedTypeGroups: [typeGroup],
    );

    if (picked == null) return 0;

    final content = await picked.readAsString();
    final decoded = jsonDecode(content);

    // Accept either a List or a single Map
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = [decoded];
    } else {
      return 0;
    }

    int imported = 0;
    for (final item in list) {
      try {
        if (item is Map<String, dynamic>) {
          if (item['complications'] is String) {
            final old = item['complications'] as String;
            item['complications'] = old.trim().isEmpty ? [] : [old];
          }
          if (item['invasiveMonitoring'] == null) {
            item['invasiveMonitoring'] = [];
          }
          if (item['complications'] is! List) item['complications'] = [];
          if (item['invasiveMonitoring'] is! List) {
            item['invasiveMonitoring'] = [];
          }

          final record = CaseRecord.fromJson(Map<String, dynamic>.from(item));
          await CaseStorage.saveCase(record);
          imported++;
        }
      } catch (_) {
        // Skip bad records
      }
    }

    return imported;
  }
}