import 'package:share_plus/share_plus.dart';
import '../models/achievement.dart';

class AchievementSharing {
  static Future<void> share(
    Achievement achievement, {
    String? customTitle,
    String? customDescription,
  }) async {
    final title = customTitle ?? achievement.title;
    final description = customDescription ?? achievement.description;
    final statusEmoji = achievement.isUnlocked ? '🏆' : '🎯';
    final statusText = achievement.isUnlocked
        ? 'Just unlocked this achievement in EtherLog!'
        : 'Working towards this achievement in EtherLog (${achievement.currentProgress}/${achievement.maxProgress})!';

    final text = '$statusEmoji **$title**\n\n'
        '"$description"\n\n'
        '$statusText 🩺✨';

    await Share.share(
      text,
      subject: 'EtherLog Achievement: $title',
    );
  }
}