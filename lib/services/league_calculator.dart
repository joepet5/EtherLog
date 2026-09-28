import '../models/case_record.dart';
import '../models/achievement.dart';
import '../services/rank_service.dart';

class LeagueCalculator {
  static Future<Map<String, int>> calculateAllScores(List<CaseRecord> cases, List<Achievement> achievements) async {
    final now = DateTime.now();
    final scores = <String, int>{};

    // 1. All-Time XP
    scores['all_time_xp'] = RankService.calculateTotalPoints(achievements);

    // 2. Monthly XP
    final monthlyCases = cases.where((c) => c.date.year == now.year && c.date.month == now.month).toList();
    int monthlyXp = 0;
    for (var c in monthlyCases) {
      monthlyXp += 50; // base points
      final asa = _parseAsa(c.asaGrade);
      if (asa >= 3) monthlyXp += 20;
      if (c.priority.toLowerCase().contains('emergency')) monthlyXp += 30;
      if (c.difficultAirway) monthlyXp += 50;
      if (c.regionalBlocks.any((b) => b['name'] != null && b['name'] != 'None / Not performed')) monthlyXp += 40;
    }
    scores['monthly_xp'] = monthlyXp;

    // 3. The 3 AM Club (00:00 - 05:59)
    scores['night_shift'] = cases.where((c) {
      if (c.anaesthesiaStartTime == null || c.anaesthesiaStartTime!.isEmpty) return false;
      final raw = c.anaesthesiaStartTime!.trim().toLowerCase();
      final isPm = raw.contains('pm');
      final isAm = raw.contains('am');
      final clean = raw.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = clean.split(':');
      if (parts.isEmpty) return false;
      int h = int.tryParse(parts[0]) ?? -1;
      if (h < 0) return false;
      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;
      return h >= 0 && h < 6;
    }).length;

    // 4. Heavyweight Champion (ASA 4, 5 and emergency cases of ASA 3, 4, 5)
    scores['high_acuity'] = cases.where((c) {
      final asa = _parseAsa(c.asaGrade);
      final isEmergency = c.priority.toLowerCase().contains('emergency');
      return asa >= 4 || (isEmergency && asa >= 3);
    }).length;

    // 5. Block Master
    scores['regional'] = cases.fold(0, (sum, c) => sum + c.regionalBlocks.where((b) => b['name'] != null && b['name'] != 'None / Not performed').length);

    // 6. Paediatric Whisperer (< 16 years or paediatric/pediatric specialty)
    scores['paediatric'] = cases.where((c) {
      final age = _getAgeInYears(c);
      final spec = c.specialty.toLowerCase();
      return (age != null && age < 16) || spec.contains('paediatric') || spec.contains('pediatric');
    }).length;

    // 7. Geriatric Guardian (80+)
    scores['geriatric'] = cases.where((c) {
      final age = _getAgeInYears(c);
      return age != null && age >= 80;
    }).length;

    // 8. Airway Ninja
    scores['airway'] = cases.where((c) {
      final method = c.methodOfIntubation?.toLowerCase() ?? '';
      return c.difficultAirway ||
          method.contains('video') ||
          method.contains('fiberoptic') ||
          method.contains('fibreoptic');
    }).length;

    // 9. Line Lord
    scores['invasive'] = cases.fold(0, (sum, c) => sum + c.invasiveMonitoring.where((m) => m['name'] != null && (m['name'] as String).isNotEmpty && m['name'] != 'None').length);

    // 10. Turnover Titan (Max cases in any 8-hour window, <= 480 mins)
    scores['high_volume'] = _calculateMaxCasesIn8Hours(cases);

    // 11. Obstetric Hero
    scores['obstetric'] = cases.where((c) => c.specialty.toLowerCase().contains('obstetric')).length;

    // 12. Marathon Runner (Cases >= 6 hours / 360 mins)
    scores['endurance'] = cases.where((c) => _parseDurationMinutes(c.anaesthesiaDuration) >= 360).length;

    return scores;
  }

  static int _parseDurationMinutes(String? dur) {
    if (dur == null || dur.trim().isEmpty) return 0;
    final text = dur.toLowerCase().trim();
    
    // Check "X:YY" format (e.g. "06:30")
    if (text.contains(':')) {
      final parts = text.split(':');
      final h = int.tryParse(parts[0].trim()) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
      return h * 60 + m;
    }
    
    final hourMatch = RegExp(r'(\d+)\s*(?:h|hr|hour)').firstMatch(text);
    final minMatch = RegExp(r'(\d+)\s*(?:m|min)').firstMatch(text);
    
    final h = hourMatch != null ? (int.tryParse(hourMatch.group(1)!) ?? 0) : 0;
    final m = minMatch != null ? (int.tryParse(minMatch.group(1)!) ?? 0) : 0;
    
    if (hourMatch == null && minMatch == null) {
      return int.tryParse(text) ?? 0;
    }
    
    return (h * 60 + m);
  }

  static DateTime _getCaseTime(CaseRecord c) {
    if (c.anaesthesiaStartTime == null || c.anaesthesiaStartTime!.isEmpty) return c.date;
    final raw = c.anaesthesiaStartTime!.trim().toLowerCase();
    final isPm = raw.contains('pm');
    final isAm = raw.contains('am');
    final clean = raw.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = clean.split(':');
    if (parts.isEmpty) return c.date;
    int h = int.tryParse(parts[0]) ?? 0;
    if (isPm && h < 12) h += 12;
    if (isAm && h == 12) h = 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(c.date.year, c.date.month, c.date.day, h, m);
  }

  static int _calculateMaxCasesIn8Hours(List<CaseRecord> cases) {
    if (cases.isEmpty) return 0;
    
    // Sort cases by actual start time
    final sorted = List<CaseRecord>.from(cases)..sort((a, b) => _getCaseTime(a).compareTo(_getCaseTime(b)));
    
    int maxCases = 0;
    for (int i = 0; i < sorted.length; i++) {
      int currentCases = 1;
      final startTime = _getCaseTime(sorted[i]);
      for (int j = i + 1; j < sorted.length; j++) {
        // Exactly 8 hours = 480 minutes
        if (_getCaseTime(sorted[j]).difference(startTime).inMinutes <= 480) {
          currentCases++;
        } else {
          break;
        }
      }
      if (currentCases > maxCases) {
        maxCases = currentCases;
      }
    }
    return maxCases;
  }

  static int _parseAsa(String grade) {
    final g = grade.toUpperCase().trim();
    if (g.contains('V') && !g.contains('IV') && !g.contains('VI')) {
      return 5;
    }
    if (g.contains('IV')) {
      return 4;
    }
    if (g.contains('III')) {
      return 3;
    }
    if (g.contains('II') && !g.contains('III')) {
      return 2;
    }
    if (g.contains('I') &&
        !g.contains('II') &&
        !g.contains('IV') &&
        !g.contains('VI')) {
      return 1;
    }
    if (g.contains('5')) {
      return 5;
    }
    if (g.contains('4')) {
      return 4;
    }
    if (g.contains('3')) {
      return 3;
    }
    if (g.contains('2')) {
      return 2;
    }
    if (g.contains('1')) {
      return 1;
    }
    return 0;
  }

  static double? _getAgeInYears(CaseRecord c) {
    if (c.patientAge == null) {
      return null;
    }
    final unit = c.ageUnit.toLowerCase();
    if (unit.contains('day')) {
      return c.patientAge! / 365.25;
    }
    if (unit.contains('month')) {
      return c.patientAge! / 12.0;
    }
    return c.patientAge!;
  }
}
