import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:etherlog/models/achievement.dart';
import 'package:etherlog/utils/achievement_sharing.dart';

void main() {
  group('AchievementSharing tests', () {
    test('playStoreUrl points to com.etherlog.etherlog', () {
      expect(
        AchievementSharing.playStoreUrl,
        'https://play.google.com/store/apps/details?id=com.etherlog.etherlog',
      );
    });

    test('buildShareText formats unlocked achievement with Google Play link', () {
      final ach = Achievement(
        id: 'ach_10',
        title: 'Getting the Hang of It',
        description: 'Ten cases. You\'ve officially stopped apologizing to the IV pole when you bump it.',
        icon: Icons.star,
        tier: AchievementTier.ruby,
        category: 'Volume',
        currentProgress: 10,
        maxProgress: 10,
        isUnlocked: true,
      );

      final text = AchievementSharing.buildShareText(ach);

      expect(text, contains('🏆 *Getting the Hang of It*'));
      expect(text, contains('🔴 Ruby Tier (+50 XP)'));
      expect(text, contains('“Ten cases. You\'ve officially stopped apologizing to the IV pole when you bump it.”'));
      expect(text, contains('Just unlocked in EtherLog! 🩺✨'));
      expect(text, contains('Track your clinical anaesthesia cases with EtherLog!'));
      expect(text, contains('Download on Google Play: https://play.google.com/store/apps/details?id=com.etherlog.etherlog'));
      expect(text, isNot(contains('etherlog.app')));
    });

    test('buildShareText formats in-progress achievement with Google Play link', () {
      final ach = Achievement(
        id: 'ach_20',
        title: 'Block Master',
        description: 'Perform fifty ultrasound-guided nerve blocks.',
        icon: Icons.star,
        tier: AchievementTier.gold,
        category: 'Regional',
        currentProgress: 25,
        maxProgress: 50,
        isUnlocked: false,
      );

      final text = AchievementSharing.buildShareText(ach);

      expect(text, contains('🎯 *Block Master*'));
      expect(text, contains('🥇 Gold Tier (+250 XP)'));
      expect(text, contains('Working towards this in EtherLog (25/50)! 🩺✨'));
      expect(text, contains('Download on Google Play: https://play.google.com/store/apps/details?id=com.etherlog.etherlog'));
      expect(text, isNot(contains('etherlog.app')));
    });
  });
}
