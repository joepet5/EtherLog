import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/case_record.dart';
import 'firebase_leaderboard_service.dart';

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

      var needsPersist = false;
      final normalized = cases.map((c) {
        if (c.role.toLowerCase().contains('consultant') && !c.verified) {
          needsPersist = true;
          return c.copyWith(
            verified: true,
            verifiedBy: c.verifiedBy ?? 'Self (Consultant)',
            verifiedAt: c.verifiedAt ?? c.date,
          );
        }
        return c;
      }).toList();

      if (needsPersist) {
        await _persist(normalized);
      }

      normalized.sort((a, b) => b.date.compareTo(a.date));
      return normalized;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCase(CaseRecord caseRecord) async {
    var recordToSave = caseRecord;
    if (recordToSave.role.toLowerCase().contains('consultant') &&
        !recordToSave.verified) {
      recordToSave = recordToSave.copyWith(
        verified: true,
        verifiedBy: recordToSave.verifiedBy ?? 'Self (Consultant)',
        verifiedAt: recordToSave.verifiedAt ?? DateTime.now(),
      );
    }
    final cases = await getAllCases();
    cases.removeWhere((c) => c.id == recordToSave.id);
    cases.add(recordToSave);
    await _persist(cases);
    unawaited(FirebaseLeaderboardService.syncAllLeagues(providedCases: cases));
  }

  static Future<void> verifyCases(
    List<String> caseIds, {
    required String verifiedBy,
    DateTime? verifiedAt,
  }) async {
    final timestamp = verifiedAt ?? DateTime.now();
    final cases = await getAllCases();
    final updated = cases.map((c) {
      if (caseIds.contains(c.id)) {
        return c.copyWith(
          verified: true,
          verifiedBy: verifiedBy,
          verifiedAt: timestamp,
        );
      }
      return c;
    }).toList();
    await _persist(updated);
  }

  static Future<void> unverifyCases(List<String> caseIds) async {
    final cases = await getAllCases();
    final updated = cases.map((c) {
      if (caseIds.contains(c.id)) {
        return c.copyWith(clearVerification: true);
      }
      return c;
    }).toList();
    await _persist(updated);
  }

  static Future<CaseRecord?> getCase(String id) async {
    final cases = await getAllCases();
    try {
      final found = cases.firstWhere((c) => c.id == id);
      if (found.role.toLowerCase().contains('consultant') && !found.verified) {
        final fixed = found.copyWith(
          verified: true,
          verifiedBy: found.verifiedBy ?? 'Self (Consultant)',
          verifiedAt: found.verifiedAt ?? found.date,
        );
        await saveCase(fixed);
        return fixed;
      }
      return found;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteCase(String id) async {
    final cases = await getAllCases();
    cases.removeWhere((c) => c.id == id);
    await _persist(cases);
    unawaited(FirebaseLeaderboardService.syncAllLeagues(providedCases: cases));
  }

  static Future<int> deleteAllCases() async {
    final cases = await getAllCases();
    final count = cases.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    unawaited(FirebaseLeaderboardService.syncAllLeagues(providedCases: []));
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