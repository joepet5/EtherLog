import '../models/case_record.dart';

class MonthTrend {
  final DateTime month; // first day of month
  final int caseCount;
  final double avgAnaesthesiaMinutes;
  final double uneventfulPercent;
  final double difficultAirwayPercent;

  const MonthTrend({
    required this.month,
    required this.caseCount,
    required this.avgAnaesthesiaMinutes,
    required this.uneventfulPercent,
    required this.difficultAirwayPercent,
  });
}

class NamedCount {
  final String name;
  final int count;
  const NamedCount(this.name, this.count);
}

class DayCount {
  final DateTime day;
  final int count;
  const DayCount(this.day, this.count);
}

class InsightsData {
  final List<MonthTrend> monthlyTrends;
  final List<NamedCount> topSpecialties;
  final List<NamedCount> topBlocks;
  final List<NamedCount> allBlocks;
  final List<NamedCount> asaMix;
  final List<NamedCount> topTechniques;
  final List<NamedCount> topComplications;
  final List<NamedCount> topAirways;
  final List<NamedCount> topInvasiveLines;
  final List<NamedCount> topProcedures;
  final int totalCases;
  final double overallAvgMinutes;
  final double overallUneventfulPercent;
  final double overallDifficultPercent;
  final int year;
  final List<DayCount> activityHeatmap;
  final int heatmapMax;

  const InsightsData({
    required this.monthlyTrends,
    required this.topSpecialties,
    required this.topBlocks,
    required this.allBlocks,
    required this.asaMix,
    required this.topTechniques,
    required this.topComplications,
    required this.topAirways,
    required this.topInvasiveLines,
    required this.topProcedures,
    required this.totalCases,
    required this.overallAvgMinutes,
    required this.overallUneventfulPercent,
    required this.overallDifficultPercent,
    required this.year,
    required this.activityHeatmap,
    required this.heatmapMax,
  });
}

class InsightsService {
  static int parseMinutes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    final t = raw.toLowerCase().trim();
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(t);
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(t);
    int hours = hourMatch != null ? int.tryParse(hourMatch.group(1)!) ?? 0 : 0;
    int mins = minMatch != null ? int.tryParse(minMatch.group(1)!) ?? 0 : 0;
    if (hours == 0 && mins == 0) {
      // plain number = minutes
      final n = int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), ''));
      return n ?? 0;
    }
    return hours * 60 + mins;
  }

  static bool isUneventful(CaseRecord c) {
    if (c.outcome == 'Uneventful PACU discharge') return true;
    return c.complications.any((x) {
      final s = x.toLowerCase();
      return s.contains('none') || s.contains('uneventful');
    });
  }

  static InsightsData build(List<CaseRecord> cases, {int? year}) {
    final y = year ?? DateTime.now().year;
    final inYear = cases.where((c) => c.date.year == y).toList();

    // Monthly buckets for the year
    final Map<int, List<CaseRecord>> byMonth = {
      for (var m = 1; m <= 12; m++) m: <CaseRecord>[],
    };
    for (final c in inYear) {
      byMonth[c.date.month]!.add(c);
    }

    final trends = <MonthTrend>[];
    for (var m = 1; m <= 12; m++) {
      final list = byMonth[m]!;
      if (list.isEmpty) {
        trends.add(MonthTrend(
          month: DateTime(y, m),
          caseCount: 0,
          avgAnaesthesiaMinutes: 0,
          uneventfulPercent: 0,
          difficultAirwayPercent: 0,
        ));
        continue;
      }
      int totalMin = 0;
      int withDuration = 0;
      int uneventful = 0;
      int difficult = 0;
      for (final c in list) {
        final mins = parseMinutes(c.anaesthesiaDuration);
        if (mins > 0) {
          totalMin += mins;
          withDuration++;
        }
        if (isUneventful(c)) uneventful++;
        if (c.difficultAirway) difficult++;
      }
      trends.add(MonthTrend(
        month: DateTime(y, m),
        caseCount: list.length,
        avgAnaesthesiaMinutes:
        withDuration == 0 ? 0 : totalMin / withDuration,
        uneventfulPercent: 100.0 * uneventful / list.length,
        difficultAirwayPercent: 100.0 * difficult / list.length,
      ));
    }

    // Top lists (year)
    final specialtyMap = <String, int>{};
    final blockMap = <String, int>{};
    final asaMap = <String, int>{};
    final techniqueMap = <String, int>{};
    final complicationsMap = <String, int>{};
    final airwayMap = <String, int>{};
    final invasiveMap = <String, int>{};
    final procedureMap = <String, int>{};
    int totalMinAll = 0, withDur = 0, uneventfulAll = 0, difficultAll = 0;

    for (final c in inYear) {
      final sp = c.specialty.trim().isEmpty ? 'Unspecified' : c.specialty.trim();
      specialtyMap[sp] = (specialtyMap[sp] ?? 0) + 1;

      final asa = c.asaGrade.trim().isEmpty ? 'Unknown' : c.asaGrade.trim();
      asaMap[asa] = (asaMap[asa] ?? 0) + 1;

      final tech =
      c.technique.trim().isEmpty ? 'Unspecified' : c.technique.trim();
      techniqueMap[tech] = (techniqueMap[tech] ?? 0) + 1;

      for (final inv in c.invasiveMonitoring) {
        final name = inv['name']?.toString() ?? '';
        if (name.isNotEmpty && name != 'None') {
          invasiveMap[name] = (invasiveMap[name] ?? 0) + 1;
        }
      }

      final proc = c.procedure.trim().isEmpty ? 'Unknown' : c.procedure.trim();
      procedureMap[proc] = (procedureMap[proc] ?? 0) + 1;

      final air = (c.airwayManagement?.trim().isEmpty ?? true) ? 'Unknown' : c.airwayManagement!.trim();
      if (air != 'Unknown' && air != 'None') {
        airwayMap[air] = (airwayMap[air] ?? 0) + 1;
      }

      for (final comp in c.complications) {
        if (comp.isEmpty || comp.toLowerCase().contains('none') || comp.toLowerCase().contains('uneventful')) continue;
        complicationsMap[comp] = (complicationsMap[comp] ?? 0) + 1;
      }

      for (final name in c.regionalBlockNames) {
        if (name.isEmpty || name == 'None / Not performed') continue;
        blockMap[name] = (blockMap[name] ?? 0) + 1;
      }

      final mins = parseMinutes(c.anaesthesiaDuration);
      if (mins > 0) {
        totalMinAll += mins;
        withDur++;
      }
      if (isUneventful(c)) uneventfulAll++;
      if (c.difficultAirway) difficultAll++;
    }

    List<NamedCount> top(Map<String, int> map, [int n = 8]) {
      final items = map.entries.map((e) => NamedCount(e.key, e.value)).toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      return items.take(n).toList();
    }

    // Daily activity heatmap for the year
    final dayMap = <String, int>{};
    for (final c in inYear) {
      final key =
          '${c.date.year}-${c.date.month.toString().padLeft(2, '0')}-${c.date.day.toString().padLeft(2, '0')}';
      dayMap[key] = (dayMap[key] ?? 0) + 1;
    }
    final heatmap = <DayCount>[];
    final start = DateTime(y, 1, 1);
    final end = DateTime(y, 12, 31);
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      heatmap.add(DayCount(d, dayMap[key] ?? 0));
    }
    final heatMax = heatmap.fold<int>(0, (m, e) => e.count > m ? e.count : m);

    return InsightsData(
      monthlyTrends: trends,
      topSpecialties: top(specialtyMap),
      topBlocks: top(blockMap),
      allBlocks: top(blockMap, 999),
      asaMix: top(asaMap, 6),
      topTechniques: top(techniqueMap),
      topComplications: top(complicationsMap, 5),
      topAirways: top(airwayMap, 5),
      topInvasiveLines: top(invasiveMap, 5),
      topProcedures: top(procedureMap, 5),
      totalCases: inYear.length,
      overallAvgMinutes: withDur == 0 ? 0 : totalMinAll / withDur,
      overallUneventfulPercent:
      inYear.isEmpty ? 0 : 100.0 * uneventfulAll / inYear.length,
      overallDifficultPercent:
      inYear.isEmpty ? 0 : 100.0 * difficultAll / inYear.length,
      year: y,
      activityHeatmap: heatmap,
      heatmapMax: heatMax < 1 ? 1 : heatMax,
    );
  }
}