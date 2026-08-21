import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/case_record.dart';

class CaseStorage {
  static const _key = 'etherlog_cases';

  static Future<List<CaseRecord>> getAllCases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];

      final List<dynamic> list = jsonDecode(raw);
      final cases = <CaseRecord>[];

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
            if (item['complications'] is! List) {
              item['complications'] = [];
            }
            if (item['invasiveMonitoring'] is! List) {
              item['invasiveMonitoring'] = [];
            }
            if (item['regionalBlocks'] is! List) {
              item['regionalBlocks'] = [];
            }
          }
          cases.add(CaseRecord.fromJson(Map<String, dynamic>.from(item as Map)));
        } catch (_) {
          continue;
        }
      }

      cases.sort((a, b) => b.date.compareTo(a.date));
      return cases;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCase(CaseRecord caseRecord) async {
    final cases = await getAllCases();
    cases.removeWhere((c) => c.id == caseRecord.id);
    cases.add(caseRecord);
    await _persist(cases);
  }

  static Future<void> deleteCase(String id) async {
    final cases = await getAllCases();
    cases.removeWhere((c) => c.id == id);
    await _persist(cases);
  }

  static Future<int> deleteAllCases() async {
    final cases = await getAllCases();
    final count = cases.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    return count;
  }

  static Future<void> _persist(List<CaseRecord> cases) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(cases.map((c) => c.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<int> totalCases() async {
    final cases = await getAllCases();
    return cases.length;
  }

  static Future<int> electiveCount() async {
    final cases = await getAllCases();
    return cases.where((c) => c.priority == 'Elective').length;
  }

  static Future<int> emergencyCount() async {
    final cases = await getAllCases();
    return cases.where((c) => c.priority == 'Emergency').length;
  }

  static Future<int> difficultAirwayCount() async {
    final cases = await getAllCases();
    return cases.where((c) => c.difficultAirway).length;
  }

  static Future<int> starredCount() async {
    final cases = await getAllCases();
    return cases.where((c) => c.starred).length;
  }
}