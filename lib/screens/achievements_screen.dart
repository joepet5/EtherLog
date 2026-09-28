import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/achievement.dart';
import '../services/case_storage.dart';
import '../services/achievement_service.dart';
import '../services/rank_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/achievement_localizations.dart';
import '../l10n/rank_localizations.dart';
import '../widgets/achievement_card.dart';
import '../utils/achievement_sharing.dart';
import 'leaderboards_screen.dart';
import 'recent_achievements_screen.dart';
import '../utils/page_transitions.dart';
import 'xp_titles_screen.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  AppLocalizations get l10n => AppLocalizations.of(context);
  String _selectedCategory = 'All';
  AchievementTier? _selectedTier; // null = all tiers
  late Future<List<Achievement>> _achievementsFuture;
  final Map<String, GlobalKey> _achievementKeys = {};

  final List<String> _categories = const [
    'All',
    'Volume',
    'PAC Clinic',
    'Time',
    'Fatigue',
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
    'Post-Op & ERAS',
    'Mentorship',
    'Portfolio',
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _achievementsFuture = _fetchAchievements();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<List<Achievement>> _fetchAchievements() async {
    final cases = await CaseStorage.getAllCases();
    return await AchievementService.getAllAchievements(cases);
  }

  Future<void> _shareOverall(int unlocked, int total,
      AchievementRank currentRank, String locale) async {
    final pct = total == 0 ? 0 : ((unlocked / total) * 100).round();
    final rankName = RankLocalizations.getName(currentRank.rankIndex, locale);
    final emoji = RankLocalizations.getEmoji(currentRank.rankIndex);
    final text =
        '$emoji I just reached the rank of *$rankName* in EtherLog! [${currentRank.currentPoints} ${RankLocalizations.getXP(locale)}]\n\n'
        '"$unlocked / $total ${l10n.achievements.toLowerCase()} ($pct%)"\n\n'
        'Tracking my anaesthesia logbook progress! 🩺✨\n'
        'Download on Google Play: ${AchievementSharing.playStoreUrl}';
    await Share.share(text, subject: 'EtherLog ${l10n.achievements}');
  }

  Future<void> _shareAchievement(Achievement ach, String locale) async {
    await AchievementSharing.share(context, ach);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.achievements),
        actions: [
          FutureBuilder<List<Achievement>>(
            future: _achievementsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final all = snapshot.data!;
              final currentRank = RankService.getRank(all);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.history, color: AppTheme.primary),
                    tooltip: 'Recent Achievements',
                    onPressed: () async {
                      final selectedAch = await Navigator.push<Achievement?>(
                        context,
                        AppPageRoute(
                          page: RecentAchievementsScreen(achievements: all),
                          style: TransitionStyle.fade,
                        ),
                      );
                      if (selectedAch != null && mounted) {
                        setState(() {
                          _selectedCategory = 'All';
                          _selectedTier = selectedAch.tier;
                        });
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (_achievementKeys[selectedAch.id]?.currentContext != null) {
                          Scrollable.ensureVisible(
                            _achievementKeys[selectedAch.id]!.currentContext!,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: 0.1,
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Icon(Icons.emoji_events, color: AppTheme.primary),
                    ),
                    tooltip: 'Global Leaderboards',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaderboardsScreen(
                            userRankEmoji:
                                RankLocalizations.getEmoji(currentRank.rankIndex),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
            filtered = filtered.where((a) => a.tier == _selectedTier).toList();
          }

          final unlocked = all.where((a) => a.isUnlocked).length;
          final currentRank = RankService.getRank(all);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => XpTitlesScreen(
                                      currentRank: currentRank,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    '${RankLocalizations.getEmoji(currentRank.rankIndex)} ${RankLocalizations.getName(currentRank.rankIndex, locale)}',
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: -0.3,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 16,
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${currentRank.currentPoints} XP',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      RankLocalizations.getSubtitle(
                                          currentRank.rankIndex, locale),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            onPressed: () => _shareOverall(
                                unlocked, all.length, currentRank, locale),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentRank.pointsForNextRank != null
                                ? '${RankLocalizations.getXP(locale)} to next rank: ${currentRank.pointsForNextRank! - currentRank.currentPoints}'
                                : 'Max Rank Reached!',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            currentRank.pointsForNextRank != null
                                ? '${(currentRank.progressToNext * 100).round()}%'
                                : '100%',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _AnimatedProgressBar(
                        value: currentRank.pointsForNextRank != null
                            ? currentRank.progressToNext.clamp(0.0, 1.0)
                            : 1.0,
                        height: 6,
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceLight,
                        duration: const Duration(milliseconds: 900),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$unlocked / ${all.length} ${l10n.achievements.toLowerCase()} (${all.isEmpty ? 0 : ((unlocked / all.length) * 100).round()}%)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
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
                    final catLabel =
                        AchievementLocalizations.getCategoryName(cat, locale);
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
                      backgroundColor: AppTheme.surfaceSolid,
                      side: BorderSide(
                        color:
                            selected ? AppTheme.primary : AppTheme.surfaceLight,
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
                        onSelected: (_) => setState(() => _selectedTier = null),
                        selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    ...AchievementTier.values.map((tier) {
                      final selected = _selectedTier == tier;
                      final tierLabel =
                          AchievementLocalizations.getTierName(tier, locale);
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
                          backgroundColor: AppTheme.surfaceSolid,
                          side: BorderSide(
                              color: tier.color.withValues(alpha: 0.7)),
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
                          final title = AchievementLocalizations.getTitle(
                              ach.id, ach.title, locale);
                          final desc = AchievementLocalizations.getDescription(
                              ach.id, ach.description, locale);
                          final tierName = AchievementLocalizations.getTierName(
                              ach.tier, locale);
                          final catName =
                              AchievementLocalizations.getCategoryName(
                                  ach.category, locale);

                          final accent = ach.isUnlocked
                              ? ach.displayColor
                              : AppTheme.textSecondary;
                          final progress = ach.maxProgress > 0
                              ? (ach.currentProgress / ach.maxProgress)
                                  .clamp(0.0, 1.0)
                              : 0.0;

                          if (!_achievementKeys.containsKey(ach.id)) {
                            _achievementKeys[ach.id] = GlobalKey();
                          }

                          return Padding(
                            key: _achievementKeys[ach.id],
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





