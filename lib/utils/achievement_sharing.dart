import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/achievement.dart';
import '../services/rank_service.dart';
import '../widgets/achievement_share_dialog.dart';

class AchievementSharing {
  /// The official Google Play Store URL for EtherLog.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.etherlog.etherlog';

  /// Returns the emoji representing the given tier.
  static String getTierEmoji(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.diamond:
        return '💎';
      case AchievementTier.obsidian:
        return '🔮';
      case AchievementTier.platinum:
        return '💠';
      case AchievementTier.gold:
        return '🥇';
      case AchievementTier.silver:
        return '🥈';
      case AchievementTier.ruby:
        return '🔴';
      case AchievementTier.bronze:
        return '🥉';
      case AchievementTier.copper:
        return '🪵';
    }
  }

  /// Builds the standard share message for an achievement.
  static String buildShareText(
    Achievement achievement, {
    String? customTitle,
    String? customDescription,
  }) {
    final title = customTitle ?? achievement.title;
    final description = customDescription ?? achievement.description;
    final xp = RankService.tierPoints[achievement.tier] ?? 10;
    final tierEmoji = getTierEmoji(achievement.tier);
    final tierName = achievement.tier.displayName;
    final statusEmoji = achievement.isUnlocked ? '🏆' : '🎯';
    final statusText = achievement.isUnlocked
        ? 'Just unlocked in EtherLog!'
        : 'Working towards this in EtherLog (${achievement.currentProgress}/${achievement.maxProgress})!';

    return '$statusEmoji *$title*\n'
        '$tierEmoji $tierName Tier (+$xp XP)\n\n'
        '“$description”\n\n'
        '$statusText 🩺✨\n'
        'Track your clinical anaesthesia cases with EtherLog!\n'
        'Download on Google Play: $playStoreUrl';
  }

  /// Opens the visual badge share dialog for the achievement.
  static Future<void> share(
    BuildContext context,
    Achievement achievement, {
    String? customTitle,
    String? customDescription,
  }) async {
    return AchievementShareDialog.show(
      context,
      achievement,
      customTitle: customTitle,
      customDescription: customDescription,
    );
  }

  /// Text-only share fallback.
  static Future<void> shareTextOnly(
    Achievement achievement, {
    String? customTitle,
    String? customDescription,
  }) async {
    final title = customTitle ?? achievement.title;
    final text = buildShareText(
      achievement,
      customTitle: customTitle,
      customDescription: customDescription,
    );

    await Share.share(
      text,
      subject: 'EtherLog Achievement: $title',
    );
  }
}