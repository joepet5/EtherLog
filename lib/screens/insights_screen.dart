import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/case_record.dart';
import '../services/case_storage.dart';
import '../services/insights_service.dart';
import 'milestone_share_screen.dart';
import 'regional_heatmap_screen.dart';
import '../widgets/animated_gradient_background.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  bool _loading = true;
  InsightsData? _data;
  late int _year;
  final GlobalKey _reviewCardKey = GlobalKey();

  Future<void> _shareMilestoneCard() async {
    if (_data == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => MilestoneShareScreen(data: _data!),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cases = await CaseStorage.getAllCases();
    final data = InsightsService.build(cases, year: _year);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.insights, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: l10n.previousYear,
            onPressed: () {
              setState(() => _year--);
              _load();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Center(
            child: Text(
              '$_year',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.nextYear,
            onPressed: _year >= DateTime.now().year
                ? null
                : () {
                    setState(() => _year++);
                    _load();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_data == null || _data!.totalCases == 0)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.noCasesLoggedYearYet(_year),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                        _yearSummary(_data!),
                        const SizedBox(height: 16),
                        _sectionTitle(l10n.activityHeatmap),
                        _ActivityHeatmap(
                          days: _data!.activityHeatmap,
                          maxCount: _data!.heatmapMax,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.heatmapCaption,
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        _sectionTitle(l10n.monthlyCaseVolume),
                        _BarChart(
                          values: _data!.monthlyTrends.map((e) => e.caseCount.toDouble()).toList(),
                          labels: l10n.monthAbbrs,
                          color: AppTheme.primary,
                          valueFormatter: (v) => v.toInt().toString(),
                        ),
                        const SizedBox(height: 16),
                        _sectionTitle(l10n.avgAnaesthesiaDurationMin),
                        _BarChart(
                          values: _data!.monthlyTrends
                              .map((e) => e.avgAnaesthesiaMinutes)
                              .toList(),
                          labels: l10n.monthAbbrs,
                          color: const Color(0xFF0891B2),
                          valueFormatter: (v) => v == 0 ? '\u2014' : v.toStringAsFixed(0),
                        ),
                        const SizedBox(height: 16),
                        _sectionTitle(l10n.percentUneventful),
                        _BarChart(
                          values: _data!.monthlyTrends
                              .map((e) => e.uneventfulPercent)
                              .toList(),
                          labels: l10n.monthAbbrs,
                          color: AppTheme.success,
                          maxValue: 100,
                          valueFormatter: (v) => v == 0 ? '\u2014' : '${v.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: 16),
                        _sectionTitle(l10n.percentDifficultAirway),
                        _BarChart(
                          values: _data!.monthlyTrends
                              .map((e) => e.difficultAirwayPercent)
                              .toList(),
                          labels: l10n.monthAbbrs,
                          color: AppTheme.danger,
                          maxValue: 100,
                          valueFormatter: (v) => v == 0 ? '\u2014' : '${v.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: 20),
                        _sectionTitle(l10n.topSpecialties),
                        _RankList(items: _data!.topSpecialties, color: AppTheme.primary),
                        const SizedBox(height: 16),
                        _sectionTitle(l10n.topRegionalBlocks),
                        _RankList(
                          items: _data!.topBlocks.take(8).toList(),
                          color: const Color(0xFF7C3AED),
                          emptyLabel: l10n.noRegionalBlocksThisYear,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.accessibility_new),
                            label: const Text('View Anatomical Heatmap'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                              foregroundColor: const Color(0xFF7C3AED),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => RegionalHeatmapScreen(data: _data!),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionTitle(l10n.asaMix),
                        _RankList(items: _data!.asaMix, color: AppTheme.warning),
                        const SizedBox(height: 16),
                        _sectionTitle(l10n.topTechniques),
                        _RankList(items: _data!.topTechniques, color: const Color(0xFF059669)),
                      ],
                ),
    );
  }

  Widget _yearSummary(InsightsData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _shareMilestoneCard,
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Share Milestone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        RepaintBoundary(
          key: _reviewCardKey,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourYearInReview(d.year),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat(l10n.cases, '${d.totalCases}', AppTheme.primary),
                    _miniStat(
                      l10n.avgDuration,
                      d.overallAvgMinutes == 0
                          ? '-'
                          : '${d.overallAvgMinutes.toStringAsFixed(0)}m',
                      const Color(0xFF0891B2),
                    ),
                    _miniStat(
                      l10n.uneventful,
                      '${d.overallUneventfulPercent.toStringAsFixed(0)}%',
                      AppTheme.success,
                    ),
                    _miniStat(
                      l10n.diffAirwayMini,
                      '${d.overallDifficultPercent.toStringAsFixed(0)}%',
                      AppTheme.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  final List<NamedCount> items;
  final Color color;
  final String? emptyLabel;

  const _RankList({required this.items, required this.color, this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(emptyLabel ?? AppLocalizations.of(context).term('None'), style: TextStyle(color: AppTheme.textSecondary));
    final max = items.first.count.toDouble().clamp(1, double.infinity);
    return Column(
      children: items.map<Widget>((e) {
        final frac = e.count / max;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).term(e.name),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${e.count}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: frac,
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
}

class _BarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double? maxValue;
  final String Function(double) valueFormatter;

  const _BarChart({
    required this.values,
    required this.labels,
    required this.color,
    this.maxValue,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = maxValue ??
        (values.isEmpty
            ? 1.0
            : values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity));

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final v = values[i];
          final h = (v / maxV).clamp(0.0, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    v == 0 ? '' : valueFormatter(v),
                    style: TextStyle(fontSize: 8, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: h == 0 ? 0.02 : h,
                      widthFactor: 1,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: v == 0
                              ? AppTheme.surfaceLight
                              : color.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final List<DayCount> days;
  final int maxCount;

  const _ActivityHeatmap({required this.days, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 7 rows (Sun–Sat), columns = weeks
    if (days.isEmpty) return const SizedBox.shrink();

    // Align first day to weekday (Mon=1..Sun=7) → use DateTime.weekday
    final first = days.first.day;
    final leadingEmpty = first.weekday % 7; // Sun=0 if we map later

    // Build weeks: list of 7 cells (null = pad)
    final cells = <DayCount?>[];
    // Start week on Monday to match clinical week feel
    final pad = (first.weekday - 1) % 7;
    for (var i = 0; i < pad; i++) {
      cells.add(null);
    }
    cells.addAll(days);

    final weeks = <List<DayCount?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      final slice = cells.sublist(i, i + 7 > cells.length ? cells.length : i + 7);
      while (slice.length < 7) {
        slice.add(null);
      }
      weeks.add(slice);
    }

    Color colorFor(int count) {
      if (count <= 0) return AppTheme.surfaceLight;
      final t = (count / maxCount).clamp(0.15, 1.0);
      return Color.lerp(
        AppTheme.primary.withValues(alpha: 0.25),
        AppTheme.primary,
        t,
      ) ??
          AppTheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // weekday labels
              Column(
                children: const [
                  SizedBox(height: 14),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: weeks.map((week) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Column(
                          children: week.map((d) {
                            if (d == null) {
                              return const SizedBox(width: 12, height: 12);
                            }
                            return Tooltip(
                              message:
                              '${d.day.day}/${d.day.month}: ${d.count} ${d.count == 1 ? l10n.term('case') : l10n.cases}',
                              child: Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(bottom: 3),
                                decoration: BoxDecoration(
                                  color: colorFor(d.count),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(AppLocalizations.of(context).less, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              const SizedBox(width: 4),
              ...[0.0, 0.25, 0.5, 0.75, 1.0].map((t) {
                final c = t == 0
                    ? AppTheme.surfaceLight
                    : (Color.lerp(AppTheme.primary.withValues(alpha: 0.25), AppTheme.primary, t) ??
                    AppTheme.primary);
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(AppLocalizations.of(context).more, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
