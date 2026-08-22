import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/usage_stats.dart';
import '../services/case_storage.dart';
import '../services/pdf_service.dart';
import '../services/points_service.dart';
import '../services/profile_storage.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_gradient_background.dart';
import 'points_breakdown_screen.dart';
import '../utils/page_transitions.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loading = true;
  List<CaseRecord> _cases = [];
  int _profileBonus = 0;

  String? _expandedRegional;
  String? _expandedInvasive;
  String? _expandedIntubationMethod;

  AppLocalizations get l10n => AppLocalizations.of(context);

  static const _ageOrder = [
    'Neonate (<28 days)',
    'Infant (29 days to 1 year)',
    'Toddler (>1 to <3 years)',
    'Child (>3 to <12 years)',
    'Adolescent (>12 to <18 years)',
    'Adult (18 to <65 years)',
    'Elderly (65 years and above)',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cases = await CaseStorage.getAllCases();
    final bonus = await ProfileStorage.getProfileBonusPoints();
    setState(() {
      _cases = cases;
      _profileBonus = bonus;
      _loading = false;
    });
  }

  double? _ageInYears(CaseRecord c) {
    if (c.patientAge == null) return null;
    final a = c.patientAge!;
    switch (c.ageUnit) {
      case 'months':
        return a / 12.0;
      case 'days':
        return a / 365.25;
      default:
        return a;
    }
  }

  String _ageBand(CaseRecord c) {
    final y = _ageInYears(c);
    if (y == null) return 'Unknown';
    final neonateMax = 28 / 365.25;
    if (y < neonateMax) return 'Neonate (<28 days)';
    if (y < 1.0) return 'Infant (29 days to 1 year)';
    if (y < 3.0) return 'Toddler (>1 to <3 years)';
    if (y < 12.0) return 'Child (>3 to <12 years)';
    if (y < 18.0) return 'Adolescent (>12 to <18 years)';
    if (y < 65.0) return 'Adult (18 to <65 years)';
    return 'Elderly (65 years and above)';
  }

  String _bmiBand(CaseRecord c) {
    final b = c.bmi;
    if (b == null) return 'Unknown';
    if (b < 18.5) return 'Underweight (<18.5)';
    if (b < 25) return 'Normal (18.5-24.9)';
    if (b < 30) return 'Overweight (25-29.9)';
    if (b < 35) return 'Obese Class I (30-34.9)';
    if (b < 40) return 'Obese Class II (35-39.9)';
    return 'Obese Class III (>=40)';
  }

  int? _parseDurationMinutes(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final text = s.toLowerCase().trim();
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(text);
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(text);
    final h = hourMatch != null ? int.tryParse(hourMatch.group(1)!) ?? 0 : 0;
    final m = minMatch != null ? int.tryParse(minMatch.group(1)!) ?? 0 : 0;
    if (h == 0 && m == 0) return null;
    return h * 60 + m;
  }

  String _formatAvgMinutes(double avg) {
    final total = avg.round();
    final h = total ~/ 60;
    final m = total % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Map<String, int> _countBy(Iterable<String> values) {
    final map = <String, int>{};
    for (final v in values) {
      if (v.trim().isEmpty) continue;
      map[v] = (map[v] ?? 0) + 1;
    }
    return map;
  }

  List<MapEntry<String, int>> _sorted(Map<String, int> map) {
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<MapEntry<String, int>> _orderedAge(Map<String, int> map) {
    return _ageOrder
        .where((k) => map.containsKey(k))
        .map((k) => MapEntry(k, map[k]!))
        .toList();
  }

  Map<String, int> _regionalRoleBreakdown(String blockName) {
    final roles = <String, int>{};
    var catheters = 0;
    for (final c in _cases) {
      final matches = c.regionalBlocks
          .where((e) => (e['name']?.toString() ?? '') == blockName);
      if (matches.isEmpty) continue;
      if (c.catheterPlaced) catheters++;
      for (final e in matches) {
        final role = e['role']?.toString() ?? 'Performed';
        roles[role] = (roles[role] ?? 0) + 1;
      }
    }
    if (catheters > 0) roles['Catheter placed'] = catheters;
    return roles;
  }

  Map<String, int> _invasiveRoleBreakdown(String itemName) {
    final roles = <String, int>{};
    for (final c in _cases) {
      for (final e in c.invasiveMonitoring) {
        if ((e['name']?.toString() ?? '') != itemName) continue;
        final role = e['role']?.toString() ?? 'Performed';
        roles[role] = (roles[role] ?? 0) + 1;
      }
    }
    return roles;
  }

  Map<String, int> _intubationMethodRoleBreakdown(String method) {
    final roles = <String, int>{};
    for (final c in _cases) {
      if (c.methodOfIntubation != method) continue;
      final role = c.methodOfIntubationRole ?? 'Unspecified';
      roles[role] = (roles[role] ?? 0) + 1;
    }
    return roles;
  }

  Future<void> _exportPdf() async {
    if (_cases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noCasesToExport)),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await UsageStats.incrementPdfExport();
      await PdfService.generateStatisticsPdf(_cases);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.statistics)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = _cases.length;
    final elective = _cases.where((c) => c.priority == 'Elective').length;
    final emergency = _cases.where((c) => c.priority == 'Emergency').length;
    final difficult = _cases.where((c) => c.difficultAirway).length;
    final casePoints = PointsService.totalFor(_cases);
    final points = casePoints + _profileBonus;
    final avgPoints = total > 0 ? (casePoints / total) : 0.0;

    final durationMinutes = _cases
        .map((c) => _parseDurationMinutes(c.anaesthesiaDuration))
        .whereType<int>()
        .toList();
    final avgDuration = durationMinutes.isEmpty
        ? null
        : durationMinutes.reduce((a, b) => a + b) / durationMinutes.length;

    final ageMap = _countBy(_cases.map(_ageBand));
    final bmiMap = _countBy(_cases.map(_bmiBand));

    final regionalNameMap = <String, int>{};
    for (final c in _cases) {
      for (final e in c.regionalBlocks) {
        final name = e['name']?.toString() ?? '';
        if (name.isEmpty || name == 'None / Not performed') continue;
        regionalNameMap[name] = (regionalNameMap[name] ?? 0) + 1;
      }
    }

    final airwayMap = _countBy(
      _cases
          .map((c) => c.airwayManagement ?? '')
          .where((s) => s.isNotEmpty && s != 'Not applicable'),
    );
    final intubationTypeMap = _countBy(
      _cases.map((c) => c.typeOfIntubation ?? '').where((s) => s.isNotEmpty),
    );
    final intubationMethodMap = _countBy(
      _cases.map((c) => c.methodOfIntubation ?? '').where((s) => s.isNotEmpty),
    );

    final invasiveNameMap = <String, int>{};
    for (final c in _cases) {
      for (final e in c.invasiveMonitoring) {
        final name = e['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        invasiveNameMap[name] = (invasiveNameMap[name] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.statistics),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l10n.exportStatisticsPdf,
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: total == 0
          ? Center(
        child: Text(
          l10n.noCasesYet,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                  child: _colorStatCard(
                      l10n.total, '$total', AppTheme.primary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _colorStatCard(
                      l10n.elective, '$elective', AppTheme.success)),
              const SizedBox(width: 8),
              Expanded(
                  child: _colorStatCard(
                      l10n.emergency, '$emergency', AppTheme.warning)),
              const SizedBox(width: 8),
              Expanded(
                  child: _colorStatCard(l10n.diffAirwayShort,
                      '$difficult', AppTheme.danger)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(onTap: () => AppPageRoute.push(context, const PointsBreakdownScreen()), child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border:
              Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded,
                    color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.totalPoints,
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      Text(
                        '$points',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (_profileBonus > 0)
                        Text(
                          l10n.includesProfileBonus(_profileBonus),
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.avgPerCase,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      avgPoints.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 12),
          _summaryCard(
            title: l10n.averageAnaesthesiaDuration,
            value: avgDuration == null
                ? 'â€”'
                : _formatAvgMinutes(avgDuration),
            subtitle: durationMinutes.isEmpty
                ? l10n.noDurationData
                : l10n.basedOnCases(durationMinutes.length),
          ),
          const SizedBox(height: 20),
          _section(l10n.divisionByAge),
          _barList(_orderedAge(ageMap), total, color: AppTheme.primary),
          _section(l10n.divisionByBmi),
          _barList(_sorted(bmiMap), total, color: AppTheme.success),
          _section(l10n.regionalBlocksByType),
          _expandableTypeList(
            entries: _sorted(regionalNameMap),
            expandedKey: _expandedRegional,
            onToggle: (name) => setState(() {
              _expandedRegional =
              _expandedRegional == name ? null : name;
            }),
            breakdownBuilder: _regionalRoleBreakdown,
            accent: AppTheme.warning,
          ),
          _section(l10n.airwayManagementStats),
          _buildDonutChartWithLegend(_sorted(airwayMap), AppTheme.primary),
          _section(l10n.typeOfIntubation),
          _buildDonutChartWithLegend(_sorted(intubationTypeMap), AppTheme.success),
          _section(l10n.methodOfIntubation),
          _expandableTypeList(
            entries: _sorted(intubationMethodMap),
            expandedKey: _expandedIntubationMethod,
            onToggle: (name) => setState(() {
              _expandedIntubationMethod =
              _expandedIntubationMethod == name ? null : name;
            }),
            breakdownBuilder: _intubationMethodRoleBreakdown,
            accent: AppTheme.warning,
          ),
          _section(l10n.invasiveLinesByType),
          _expandableTypeList(
            entries: _sorted(invasiveNameMap),
            expandedKey: _expandedInvasive,
            onToggle: (name) => setState(() {
              _expandedInvasive =
              _expandedInvasive == name ? null : name;
            }),
            breakdownBuilder: _invasiveRoleBreakdown,
            accent: AppTheme.danger,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDonutChartWithLegend(List<MapEntry<String, int>> entries, Color baseColor) {
    if (entries.isEmpty) return const SizedBox();
    
    final sorted = List.of(entries)..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    if (sorted.length > 5) {
      final otherSum = sorted.skip(5).map((e) => e.value).reduce((a, b) => a + b);
      top.add(MapEntry('Other', otherSum));
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: top.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final color = idx == 0 ? baseColor : 
                              idx == 1 ? baseColor.withValues(alpha: 0.8) :
                              idx == 2 ? baseColor.withValues(alpha: 0.6) :
                              idx == 3 ? baseColor.withValues(alpha: 0.4) :
                              baseColor.withValues(alpha: 0.2);
                              
                return PieChartSectionData(
                  color: color,
                  value: e.value.toDouble(),
                  title: '${e.value}',
                  radius: 35,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: top.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final color = idx == 0 ? baseColor : 
                          idx == 1 ? baseColor.withValues(alpha: 0.8) :
                          idx == 2 ? baseColor.withValues(alpha: 0.6) :
                          idx == 3 ? baseColor.withValues(alpha: 0.4) :
                          baseColor.withValues(alpha: 0.2);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(l10n.term(e.key), style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              ],
            );
          }).toList(),
        ).animate().fade(delay: 300.ms),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBarChart(List<MapEntry<String, int>> entries, Color baseColor) {
    if (entries.isEmpty) return const SizedBox();
    
    final top = entries.take(6).toList();
    final maxVal = top.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.surfaceLight,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${top[group.x.toInt()].key}\n${rod.toY.toInt()}',
                  TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= top.length) return const SizedBox();
                  String text = top[value.toInt()].key;
                  if (text.length > 6) text = text.substring(0, 6) + '..';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(text, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: top.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: baseColor,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.2,
                    color: AppTheme.surfaceLight.withValues(alpha: 0.2),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ).animate().slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _colorStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      {required String title, required String value, String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _barList(List<MapEntry<String, int>> entries, int? totalForPct,
      {required Color color}) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(l10n.noData,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      );
    }
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: entries.map((e) {
        final pct = totalForPct != null && totalForPct > 0
            ? (e.value / totalForPct * 100)
            : null;
        final barFraction = maxVal > 0 ? e.value / maxVal : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.term(e.key),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                  ),
                  Text(
                    pct != null
                        ? '${e.value}  (${pct.toStringAsFixed(1)}%)'
                        : '${e.value}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: barFraction.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceLight,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _expandableTypeList({
    required List<MapEntry<String, int>> entries,
    required String? expandedKey,
    required void Function(String name) onToggle,
    required Map<String, int> Function(String name) breakdownBuilder,
    required Color accent,
  }) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(l10n.noData,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      );
    }
    final maxVal = entries.first.value;

    return Column(
      children: entries.map((e) {
        final expanded = expandedKey == e.key;
        final barFraction = maxVal > 0 ? e.value / maxVal : 0.0;
        final breakdown = expanded ? breakdownBuilder(e.key) : <String, int>{};
        final breakdownEntries = _sorted(breakdown);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: expanded
                    ? accent.withValues(alpha: 0.5)
                    : AppTheme.surfaceLight),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onToggle(e.key),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.term(e.key),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${e.value}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accent),
                          ),
                          Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: barFraction.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppTheme.surfaceLight,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: breakdownEntries.isEmpty
                        ? [
                      Text(l10n.noRoleData,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                    ]
                        : breakdownEntries.map((role) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.term(role.key),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary),
                              ),
                            ),
                            Text(
                              '${role.value}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

