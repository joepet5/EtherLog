import 'dart:io';

void main() {
  var file = File('lib/screens/statistics_screen.dart');
  var content = file.readAsStringSync();

  // 1. Add imports
  if (!content.contains('package:fl_chart/fl_chart.dart')) {
    content = content.replaceFirst('import \\'package:flutter/material.dart\\';', 'import \\'package:flutter/material.dart\\';\\nimport \\'package:fl_chart/fl_chart.dart\\';\\nimport \\'package:flutter_animate/flutter_animate.dart\\';');
  }

  // 2. Add the chart methods
  var chartMethods = '''
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
                  title: '\',
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
                  '\\\n\',
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
''';

  content = content.replaceFirst('  Widget _colorStatCard(String title, String value, Color color) {', chartMethods);

  // 3. Replace _barList with _buildBarChart or _buildDonutChartWithLegend
  content = content.replaceFirst('_barList(_sorted(ageMap), total, color: AppTheme.primary)', '_buildBarChart(_sorted(ageMap), AppTheme.primary)');
  content = content.replaceFirst('_barList(_sorted(bmiMap), total, color: AppTheme.primary)', '_buildBarChart(_sorted(bmiMap), AppTheme.primary)');
  content = content.replaceFirst('_barList(_sorted(specialtyMap), total, color: AppTheme.primary)', '_buildDonutChartWithLegend(_sorted(specialtyMap), AppTheme.primary)');
  content = content.replaceFirst('_barList(_sorted(priorityMap), total, color: AppTheme.warning)', '_buildDonutChartWithLegend(_sorted(priorityMap), AppTheme.warning)');
  content = content.replaceFirst('_barList(_sorted(asaMap), total, color: AppTheme.danger)', '_buildDonutChartWithLegend(_sorted(asaMap), AppTheme.danger)');
  content = content.replaceFirst('_barList(_sorted(techniqueMap), total, color: AppTheme.primary)', '_buildDonutChartWithLegend(_sorted(techniqueMap), AppTheme.primary)');
  content = content.replaceFirst('_barList(_sorted(airwayMap), null, color: AppTheme.primary)', '_buildDonutChartWithLegend(_sorted(airwayMap), AppTheme.primary)');
  content = content.replaceFirst('_barList(_sorted(intubationTypeMap), null,\\n                color: AppTheme.success)', '_buildDonutChartWithLegend(_sorted(intubationTypeMap), AppTheme.success)');

  file.writeAsStringSync(content);
}
