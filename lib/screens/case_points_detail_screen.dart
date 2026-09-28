import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/points_service.dart';
import '../l10n/app_localizations.dart';

class CasePointsDetailScreen extends StatelessWidget {
  final CaseRecord caseRecord;

  const CasePointsDetailScreen({super.key, required this.caseRecord});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalPoints = PointsService.forCase(caseRecord);
    final items = PointsService.caseBreakdown(caseRecord);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.pointsBreakdown),
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
                  AppTheme.primary.withValues(alpha: 0.2),
                  AppTheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      caseRecord.caseNumber.isNotEmpty
                          ? caseRecord.caseNumber
                          : l10n.caseDetails,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+$totalPoints pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  caseRecord.procedure.isNotEmpty
                      ? caseRecord.procedure
                      : (caseRecord.diagnosis.isNotEmpty ? caseRecord.diagnosis : l10n.procedure),
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                ...[
                const SizedBox(height: 4),
                Text(
                  '${caseRecord.date.day}/${caseRecord.date.month}/${caseRecord.date.year}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.8)),
                ),
              ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            l10n.byCategory,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),

          // Breakdown Items
          ...items.map((item) {
            final isPos = item.points >= 0;
            final color = isPos ? AppTheme.success : AppTheme.danger;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPos ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.term(item.title),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            l10n.term(item.subtitle!),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    isPos ? '+${item.points}' : '${item.points}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
