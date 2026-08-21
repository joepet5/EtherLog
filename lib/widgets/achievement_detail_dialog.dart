import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../utils/achievement_sharing.dart';
import '../l10n/achievement_localizations.dart';
import '../l10n/app_localizations.dart';

class AchievementDetailDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementDetailDialog({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final iconColor = achievement.iconColor ?? Colors.blue;

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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              size: 40,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? Colors.green.withOpacity(0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              achievement.isUnlocked
                  ? l10n.unlockedLabel.toUpperCase()
                  : l10n.inProgressLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: achievement.isUnlocked ? Colors.green : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (!achievement.isUnlocked) ... [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: achievement.maxProgress > 0
                    ? (achievement.currentProgress / achievement.maxProgress).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${achievement.currentProgress} / ${achievement.maxProgress}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => AchievementSharing.share(
                  achievement,
                  customTitle: title,
                  customDescription: description,
                ),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(l10n.shareAchievement),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.done),
              ),
            ],
          ),
        ],
      ),
    );
  }
}