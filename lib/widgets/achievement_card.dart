import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../utils/achievement_sharing.dart';
import 'achievement_detail_dialog.dart';
import '../l10n/achievement_localizations.dart';
import '../l10n/app_localizations.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);

    final title = AchievementLocalizations.getTitle(
      achievement.id,
      achievement.title,
      locale,
    );
    final description = AchievementLocalizations.getDescription(
      achievement.id,
      achievement.description,
      locale,
    );

    final iconColor = achievement.iconColor ?? Colors.blue;

    return Card(
      elevation: achievement.isUnlocked ? 2 : 0,
      color: achievement.isUnlocked
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: achievement.isUnlocked
              ? iconColor.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: achievement.isUnlocked ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AchievementDetailDialog(achievement: achievement),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement.icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  Row(
                    children: [
                      // Direct Share Button on the Card
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 20),
                        color: theme.colorScheme.onSurfaceVariant,
                        tooltip: l10n.shareAchievement,
                        onPressed: () => AchievementSharing.share(achievement),
                      ),
                      Icon(
                        achievement.isUnlocked ? Icons.verified : Icons.lock_outline,
                        color: achievement.isUnlocked ? Colors.green : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (!achievement.isUnlocked) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.maxProgress > 0
                        ? (achievement.currentProgress / achievement.maxProgress).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${achievement.currentProgress} / ${achievement.maxProgress}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                Text(
                  l10n.unlockedLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}