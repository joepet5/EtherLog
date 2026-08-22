import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: achievement.isUnlocked ? iconColor.withValues(alpha: 0.5) : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: achievement.isUnlocked ? 2 : 1,
          ),
          boxShadow: achievement.isUnlocked
              ? [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating 3D-like Jewel Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.4),
                    iconColor.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: achievement.isUnlocked
                    ? [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
                border: Border.all(
                  color: achievement.isUnlocked ? Colors.white.withValues(alpha: 0.5) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                achievement.icon,
                size: 56,
                color: achievement.isUnlocked ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
            ).animate(target: achievement.isUnlocked ? 1 : 0)
             .scaleXY(end: 1.2, duration: 600.ms, curve: Curves.elasticOut)
             .shimmer(duration: 2000.ms, color: Colors.white, delay: 600.ms),
             
            const SizedBox(height: 24),
            
            // Unlocked Badge
            if (achievement.isUnlocked)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'UNLOCKED',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 400.ms).slideY(begin: 0.5),

            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (achievement.isUnlocked)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AchievementSharing.share(achievement);
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l10n.shareAchievement, style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: iconColor.withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.progress,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.close, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ).animate().fade(duration: 200.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack);
  }
}
