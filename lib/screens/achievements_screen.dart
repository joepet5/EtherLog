import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/achievement.dart';
import '../services/case_storage.dart';
import '../services/achievement_service.dart';
import '../services/rank_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/achievement_localizations.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/achievement_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  String _selectedCategory = 'All';
  AchievementTier? _selectedTier; // null = all tiers
  late Future<List<Achievement>> _achievementsFuture;

  final List<String> _categories = const [
    'All',
    'Volume',
    'Time',
    'Risk',
    'Emergency',
    'Specialties',
    'Techniques',
    'Airway',
    'Regional',
    'Monitoring',
    'Demographics',
    'Safety',
    'Power User',
    'Complications',
  ];

  @override
  void initState() {
    super.initState();
    _achievementsFuture = _fetchAchievements();
  }

  Future<List<Achievement>> _fetchAchievements() async {
    final cases = await CaseStorage.getAllCases();
    return await AchievementService.getAllAchievements(cases);
  }

  Future<void> _shareOverall(int unlocked, int total) async {
    final pct = total == 0 ? 0 : ((unlocked / total) * 100).round();
    final text =
        '🏅 *EtherLog ${l10n.achievements}*\n"$unlocked / $total ${l10n.unlockedLabel.toLowerCase()} ($pct%)"\nTracking my anaesthesia logbook progress in EtherLog! 🩺✨';
    await Share.share(text, subject: 'EtherLog ${l10n.achievements}');
  }

  Future<void> _shareAchievement(Achievement ach, String locale) async {
    final title = AchievementLocalizations.getTitle(ach.id, ach.title, locale).trim();
    final quote = AchievementLocalizations.getDescription(ach.id, ach.description, locale).trim();
    final String text;
    if (ach.isUnlocked) {
      text =
      '🏆 *$title*\n"$quote"\nJust unlocked this achievement in EtherLog! 🩺✨';
    } else {
      text =
      '🎯 *$title*\n"$quote"\nWorking towards this achievement in EtherLog (${ach.currentProgress}/${ach.maxProgress})! 🩺✨';
    }
    await Share.share(text, subject: title);
  }


  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.achievementsBadges)),
      body: FutureBuilder<List<Achievement>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                l10n.couldNotLoadAchievements,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final all = snapshot.data ?? [];
          var filtered = all;
          if (_selectedCategory != 'All') {
            filtered =
                filtered.where((a) => a.category == _selectedCategory).toList();
          }
          if (_selectedTier != null) {
            filtered =
                filtered.where((a) => a.tier == _selectedTier).toList();
          }

          final unlocked = all.where((a) => a.isUnlocked).length;
          final currentRank = RankService.getRank(all);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentRank.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentRank.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textSecondary.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rank Points: ${currentRank.currentPoints}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.shareProgress,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: Icon(
                              Icons.ios_share,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                            onPressed: () => _shareOverall(unlocked, all.length),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$unlocked / ${all.length}',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            all.isEmpty
                                ? '0%'
                                : '${((unlocked / all.length) * 100).round()}%',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _AnimatedProgressBar(
                        // Fills with unlocked achievements only (e.g. 351/702 ≈ half).
                        value: all.isEmpty
                            ? 0.0
                            : (unlocked / all.length).clamp(0.0, 1.0),
                        height: 12,
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceLight,
                        duration: const Duration(milliseconds: 900),
                      ),
                    ],
                  ),
                ),
              ),
              // Category chips
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final selected = _selectedCategory == cat;
                    final catLabel = AchievementLocalizations.getCategoryName(cat, locale);
                    return ChoiceChip(
                      label: Text(
                        catLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.surfaceLight,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
              // Tier chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(l10n.allTiers,
                            style: const TextStyle(fontSize: 11)),
                        selected: _selectedTier == null,
                        onSelected: (_) =>
                            setState(() => _selectedTier = null),
                        selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    ...AchievementTier.values.map((tier) {
                      final selected = _selectedTier == tier;
                      final tierLabel = AchievementLocalizations.getTierName(tier, locale);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            tierLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : tier.color,
                            ),
                          ),
                          selected: selected,
                          selectedColor: tier.color,
                          backgroundColor: AppTheme.surface,
                          side: BorderSide(color: tier.color.withValues(alpha: 0.7)),
                          onSelected: (_) =>
                              setState(() => _selectedTier = tier),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                  child: Text(
                    l10n.noAchievementsInFilter,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ach = filtered[index];
                    final title = AchievementLocalizations.getTitle(ach.id, ach.title, locale);
                    final desc = AchievementLocalizations.getDescription(ach.id, ach.description, locale);
                    final tierName = AchievementLocalizations.getTierName(ach.tier, locale);
                    final catName = AchievementLocalizations.getCategoryName(ach.category, locale);

                    final accent = ach.isUnlocked
                        ? ach.displayColor
                        : AppTheme.textSecondary;
                    final progress = ach.maxProgress > 0
                        ? (ach.currentProgress / ach.maxProgress)
                        .clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AchievementCard(achievement: ach),
                    );

                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


/// Smoothly animates fill from 0 → [value] (and between value changes).
class _AnimatedProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color color;
  final Color backgroundColor;
  final Duration duration;

  const _AnimatedProgressBar({
    required this.value,
    required this.height,
    required this.color,
    required this.backgroundColor,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: animated,
            minHeight: height,
            backgroundColor: backgroundColor,
            color: color,
          ),
        );
      },
    );
  }
}
