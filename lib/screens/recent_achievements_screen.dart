import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/achievement_localizations.dart';

class RecentAchievementsScreen extends StatelessWidget {
  final List<Achievement> achievements;

  const RecentAchievementsScreen({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    
    // Filter to only unlocked achievements that have a timestamp,
    // then sort descending (most recent first).
    final unlocked = achievements
        .where((a) => a.isUnlocked && a.unlockedAt != null)
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Recent Achievements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: unlocked.isEmpty
          ? Center(
              child: Text(
                'No recent achievements yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: unlocked.length,
              itemBuilder: (context, index) {
                final a = unlocked[index];
                final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(a.unlockedAt!);
                final title = AchievementLocalizations.getTitle(a.id, a.title, locale);
                final desc = AchievementLocalizations.getDescription(a.id, a.description, locale);
                return InkWell(
                  onTap: () {
                    Navigator.pop(context, a);
                  },
                  child: Card(
                    color: AppTheme.surface.withValues(alpha: 0.72),
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
                    ),
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: a.displayColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(a.icon, color: a.displayColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Unlocked: $dateStr',
                                style: TextStyle(
                                  color: a.displayColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                );
              },
            ),
    );
  }
}




