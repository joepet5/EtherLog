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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: achievement.isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  iconColor.withValues(alpha: 0.12),
                  theme.colorScheme.surface,
                ],
                stops: const [0.0, 0.4, 1.0],
              )
            : null,
        color: achievement.isUnlocked ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        border: Border.all(
          color: achievement.isUnlocked
              ? iconColor.withValues(alpha: 0.45)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: achievement.isUnlocked ? 1.5 : 1.0,
        ),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AchievementDetailDialog(achievement: achievement),
            );
          },
          child: Stack(
            children: [
              if (achievement.isUnlocked)
                Positioned(
                  top: 0, left: 0, right: 0, height: 25,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HD Jewel Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: achievement.isUnlocked
                          ? RadialGradient(
                              colors: [
                                iconColor.withValues(alpha: 0.3),
                                iconColor.withValues(alpha: 0.05),
                              ],
                            )
                          : null,
                      color: achievement.isUnlocked ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: Border.all(
                        color: achievement.isUnlocked ? iconColor.withValues(alpha: 0.4) : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: achievement.isUnlocked
                          ? [
                              BoxShadow(
                                color: iconColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      achievement.icon,
                      color: achievement.isUnlocked ? iconColor : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ).animate(target: achievement.isUnlocked ? 1 : 0)
                     .scaleXY(end: 1.1, curve: Curves.easeOutBack, duration: 300.ms),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                  color: achievement.isUnlocked ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Share Icon (if unlocked)
                            if (achievement.isUnlocked)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                icon: const Icon(Icons.ios_share_rounded, size: 16),
                                color: iconColor,
                                tooltip: l10n.shareAchievement,
                                onPressed: () => AchievementSharing.share(context, achievement),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Progress bar for BOTH locked and unlocked
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (achievement.maxProgress > 0 ? (achievement.currentProgress / achievement.maxProgress).clamp(0.0, 1.0) : 0.0),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              achievement.isUnlocked ? iconColor : iconColor.withValues(alpha: 0.4)
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Progress Text on far right
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${achievement.currentProgress}/${achievement.maxProgress}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: achievement.isUnlocked ? Colors.green.shade600 : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (achievement.isUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            l10n.unlockedLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (achievement.isUnlocked) {
      card = card.animate(onPlay: (c) => c.repeat(reverse: true))
                 .shimmer(duration: 3500.ms, color: Colors.white.withValues(alpha: 0.08), blendMode: BlendMode.screen);
    }

    return card;
  }
}
