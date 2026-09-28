import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pac_record.dart';

class PacStorage {
  static const _key = 'etherlog_pac_records';

  static Future<List<PacRecord>> getAllPacRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];

      final List<dynamic> list = jsonDecode(raw);
      final records = <PacRecord>[];
      for (final item in list) {
        try {
          if (item is Map<String, dynamic>) {
            records.add(PacRecord.fromJson(item));
          }
        } catch (_) {
          continue;
        }
      }
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePacRecord(PacRecord record) async {
    final list = await getAllPacRecords();
    final idx = list.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      list[idx] = record;
    } else {
      // Check if there's already an entry for this exact calendar day
      final sameDayIdx = list.indexWhere((r) =>
          r.date.year == record.date.year &&
          r.date.month == record.date.month &&
          r.date.day == record.date.day);
      if (sameDayIdx >= 0) {
        list[sameDayIdx] = record.copyWith(id: list[sameDayIdx].id);
      } else {
        list.add(record);
      }
    }
    await _persist(list);
  }

  static Future<void> deletePacRecord(String id) async {
    final list = await getAllPacRecords();
    list.removeWhere((r) => r.id == id);
    await _persist(list);
  }

  static Future<PacRecord?> getPacRecordForDate(DateTime date) async {
    final list = await getAllPacRecords();
    for (final r in list) {
      if (r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day) {
        return r;
      }
    }
    return null;
  }

  static Future<int> getTotalPacPatients({int? year}) async {
    final list = await getAllPacRecords();
    return list
        .where((r) => year == null || r.date.year == year)
        .fold<int>(0, (sum, r) => sum + r.patientCount);
  }

  static Future<void> _persist(List<PacRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
