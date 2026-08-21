import '../models/case_record.dart';
import 'case_storage.dart';

/// Stage 1: eligibility + rounding queue lifecycle (form comes in Stage 2).
class FollowUpService {
  /// Auto or manual reason to track post-op.
  static bool isEligible(CaseRecord c) {
    if (c.flagForFollowUp) return true;

    final asa = c.asaGrade.toUpperCase();
    // ASA 3 / 4 / 5 (numeric or Roman)
    if (RegExp(r'ASA\s*(?:[345]|III|IV|V)\b').hasMatch(asa)) return true;

    for (final e in c.regionalBlocks) {
      final name = (e['name'] ?? '').toString();
      if (name.isNotEmpty && name != 'None / Not performed') return true;
    }
    return false;
  }

  /// Queue becomes active the calendar day after the case date (local).
  static DateTime dueAt(CaseRecord c) {
    final d = DateTime(c.date.year, c.date.month, c.date.day);
    return d.add(const Duration(days: 1));
  }

  /// Auto-archive 72 hours after due.
  static DateTime expiresAt(CaseRecord c) =>
      dueAt(c).add(const Duration(hours: 72));

  static bool isExpired(CaseRecord c, [DateTime? now]) {
    final n = now ?? DateTime.now();
    return n.isAfter(expiresAt(c));
  }

  /// Visible in the Pending Follow-Up queue.
  static bool isInQueue(CaseRecord c, [DateTime? now]) {
    final n = now ?? DateTime.now();
    if (!isEligible(c)) return false;
    final status = c.followUpStatus;
    if (status == 'completed' ||
        status == 'dismissed' ||
        status == 'expired') {
      return false;
    }
    if (n.isBefore(dueAt(c))) return false;
    if (isExpired(c, n)) return false;
    return true;
  }

  static List<CaseRecord> queueFrom(List<CaseRecord> all, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final list = all.where((c) => isInQueue(c, n)).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Status to store when saving a case.
  static String initialStatus(CaseRecord c) {
    if (!isEligible(c)) return 'none';
    return 'pending';
  }

  static Future<void> complete(CaseRecord c) async {
    await CaseStorage.saveCase(
      c.copyWith(
        followUpStatus: 'completed',
        followUpCompletedAt: DateTime.now(),
      ),
    );
  }

  static Future<void> dismiss(CaseRecord c) async {
    await CaseStorage.saveCase(c.copyWith(followUpStatus: 'dismissed'));
  }

  static Future<int> expireOverdue(List<CaseRecord> all) async {
    var count = 0;
    final now = DateTime.now();
    for (final c in all) {
      if (!isEligible(c)) continue;
      if (c.followUpStatus == 'completed' ||
          c.followUpStatus == 'dismissed' ||
          c.followUpStatus == 'expired') {
        continue;
      }
      if (isExpired(c, now)) {
        await CaseStorage.saveCase(c.copyWith(followUpStatus: 'expired'));
        count++;
      }
    }
    return count;
  }
}