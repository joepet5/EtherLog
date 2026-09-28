import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/points_service.dart';
import '../l10n/app_localizations.dart';
import 'case_detail_screen.dart';

class CategoryPointsDetailScreen extends StatelessWidget {
  final String categoryKey;
  final List<CaseRecord> cases;
  final int profileBonus;

  const CategoryPointsDetailScreen({
    super.key,
    required this.categoryKey,
    required this.cases,
    this.profileBonus = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = PointsService.getCategoryDetail(
      categoryKey,
      cases,
      profileBonus: profileBonus,
    );

    final isPositive = detail.totalPoints >= 0;
    final displayTitle = categoryKey == 'Profile completion bonus'
        ? l10n.profileCompletionBonus
        : l10n.term(categoryKey);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(displayTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isPositive ? AppTheme.primary : AppTheme.danger).withValues(alpha: 0.15),
                  AppTheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isPositive ? AppTheme.primary : AppTheme.danger).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPositive ? AppTheme.primary : AppTheme.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPositive ? '+${detail.totalPoints} pts' : '${detail.totalPoints} pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 15, color: AppTheme.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            '${detail.totalTriggers} ${detail.totalTriggers == 1 ? "trigger" : "triggers"}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (detail.contributingCases.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medical_services_outlined, size: 15, color: AppTheme.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              '${detail.contributingCases.length} ${detail.contributingCases.length == 1 ? "case" : "cases"}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Section 1: Itemized Breakdown with Trigger Counts
          Text(
            'CATEGORY BREAKDOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),

          if (detail.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: Text(
                'No triggers recorded for this category yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            )
          else
            ...detail.items.map((item) {
              final itemPositive = item.totalPoints >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Trigger Count Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, size: 13, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Triggered ${item.count} ${item.count == 1 ? "time" : "times"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          itemPositive ? '+${item.totalPoints}' : '${item.totalPoints}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: itemPositive ? AppTheme.primary : AppTheme.danger,
                          ),
                        ),
                        if (item.pointsPerTrigger != 0 && item.count > 1) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.pointsPerTrigger > 0
                                ? '+${item.pointsPerTrigger} each'
                                : '${item.pointsPerTrigger} each',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),

          // Section 2: Contributing Cases
          if (detail.contributingCases.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'CONTRIBUTING CASES (${detail.contributingCases.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            ...detail.contributingCases.map((c) {
              final casePositive = c.points >= 0;
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, __, ___) => CaseDetailScreen(caseRecord: c.caseRecord),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.caseRecord.procedure.isNotEmpty
                                  ? c.caseRecord.procedure
                                  : (c.caseRecord.diagnosis.isNotEmpty
                                      ? c.caseRecord.diagnosis
                                      : l10n.procedure),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${c.caseRecord.date.day}/${c.caseRecord.date.month}/${c.caseRecord.date.year}'
                              ' · ${c.caseRecord.asaGrade}'
                              '${c.detail != null && c.detail!.isNotEmpty ? " · ${c.detail}" : ""}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        casePositive ? '+${c.points}' : '${c.points}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: casePositive ? AppTheme.primary : AppTheme.danger,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
