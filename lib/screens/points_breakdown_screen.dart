import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/case_storage.dart';
import '../services/points_service.dart';
import '../services/profile_storage.dart';
import '../l10n/app_localizations.dart';
import 'case_detail_screen.dart';
import '../widgets/animated_gradient_background.dart';

class PointsBreakdownScreen extends StatefulWidget {
  const PointsBreakdownScreen({super.key});

  @override
  State<PointsBreakdownScreen> createState() => _PointsBreakdownScreenState();
}

class _PointsBreakdownScreenState extends State<PointsBreakdownScreen> {
  bool _loading = true;
  List<CaseRecord> _cases = [];
  int _profileBonus = 0;
  Map<String, int> _categories = {};

  AppLocalizations get l10n => AppLocalizations.of(context);

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
      _categories = PointsService.categoryBreakdown(cases);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l10n.points)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final caseTotal = PointsService.totalFor(_cases);
    final grand = caseTotal + _profileBonus;
    final sortedCases = List<CaseRecord>.from(_cases)
      ..sort((a, b) =>
          PointsService.forCase(b).compareTo(PointsService.forCase(a)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.pointsBreakdown)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.totalPoints,
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '$grand',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                if (_profileBonus > 0)
                  Text(
                    l10n.includesProfileCompletionBonus(_profileBonus),
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.byCategory,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          ..._categories.entries.map((e) {
            if (e.value == 0) return const SizedBox.shrink();
            final positive = e.value > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.term(e.key),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    positive ? '+${e.value}' : '${e.value}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: positive ? AppTheme.primary : AppTheme.danger,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_profileBonus > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.profileCompletionBonus,
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ),
                  Text(
                    '+$_profileBonus',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            l10n.byCase,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          if (sortedCases.isEmpty)
            Text(l10n.noCasesYet,
                style: TextStyle(color: AppTheme.textSecondary))
          else
            ...sortedCases.map((c) {
              final pts = PointsService.forCase(c);
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CaseDetailScreen(caseRecord: c)),
                  ).then((_) => _load());
                },
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
                              c.procedure,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.date.day}/${c.date.month}/${c.date.year} · ${c.asaGrade} · ${l10n.term(c.priority)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        pts >= 0 ? '+$pts' : '$pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: pts >= 0
                              ? AppTheme.primary
                              : AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
