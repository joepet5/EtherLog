import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    final iconColor = achievement.displayColor;

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: achievement.isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  iconColor.withValues(alpha: 0.15),
                  theme.colorScheme.surface,
                ],
                stops: const [0.0, 0.5, 1.0],
              )
            : null,
        color: achievement.isUnlocked ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: achievement.isUnlocked
              ? iconColor.withValues(alpha: 0.6)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: achievement.isUnlocked ? 2.0 : 1.0,
        ),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.25),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AchievementDetailDialog(achievement: achievement),
            );
          },
          child: Stack(
            children: [
              // Reflection/Gloss effect for HD feel
              if (achievement.isUnlocked)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // HD Jewel Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: achievement.isUnlocked
                                ? RadialGradient(
                                    colors: [
                                      iconColor.withValues(alpha: 0.3),
                                      iconColor.withValues(alpha: 0.1),
                                    ],
                                  )
                                : null,
                            color: achievement.isUnlocked ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            border: Border.all(
                              color: achievement.isUnlocked ? iconColor.withValues(alpha: 0.5) : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: achievement.isUnlocked
                                ? [
                                    BoxShadow(
                                      color: iconColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: Icon(
                            achievement.icon,
                            color: achievement.isUnlocked ? iconColor : theme.colorScheme.onSurfaceVariant,
                            size: 28,
                          ).animate(target: achievement.isUnlocked ? 1 : 0)
                           .scaleXY(end: 1.1, curve: Curves.easeOutBack, duration: 300.ms),
                        ),
                        Row(
                          children: [
                            if (achievement.isUnlocked)
                              IconButton(
                                icon: const Icon(Icons.ios_share_rounded, size: 22),
                                color: iconColor,
                                tooltip: l10n.shareAchievement,
                                onPressed: () => AchievementSharing.share(achievement),
                              ),
                            Icon(
                              achievement.isUnlocked ? Icons.workspace_premium_rounded : Icons.lock_outline,
                              color: achievement.isUnlocked ? Colors.amber : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
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
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (achievement.isUnlocked)
                      Text(
                        l10n.unlockedLabel.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (achievement.maxProgress > 0 ? (achievement.currentProgress / achievement.maxProgress).clamp(0.0, 1.0) : 0.0),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor.withValues(alpha: 0.4)),
                          minHeight: 6,
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

    if (achievement.isUnlocked) {
      // Add a shimmering sweep over the entire card if unlocked
      card = card.animate(onPlay: (c) => c.repeat(reverse: true))
                 .shimmer(duration: 3000.ms, color: Colors.white.withValues(alpha: 0.1), blendMode: BlendMode.screen);
    }

    return card;
  }
}



