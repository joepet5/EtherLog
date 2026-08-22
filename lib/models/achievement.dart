import 'package:flutter/material.dart';

/// Eight difficulty tiers — icon / accent colour when unlocked.
enum AchievementTier {
  copper,
  bronze,
  ruby,
  silver,
  gold,
  platinum,
  obsidian,
  diamond,
}

extension AchievementTierX on AchievementTier {
  String get label {
    switch (this) {
      case AchievementTier.copper:
        return 'Copper';
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.ruby:
        return 'Ruby';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.obsidian:
        return 'Obsidian';
      case AchievementTier.diamond:
        return 'Diamond';
    }
  }

  Color get color {
    switch (this) {
      case AchievementTier.copper:
        return const Color(0xFF45B08C);
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.ruby:
        return const Color(0xFFE11D48);
      case AchievementTier.silver:
        return const Color(0xFFE2E8F0);
      case AchievementTier.gold:
        return const Color(0xFFD4AF37);
      case AchievementTier.platinum:
        return const Color(0xFF22D3EE);
      case AchievementTier.obsidian:
        return const Color(0xFF8B5CF6);
      case AchievementTier.diamond:
        return const Color(0xFF67E8F9);
    }
  }

  static AchievementTier fromName(String? raw) {
    if (raw == null || raw.isEmpty) return AchievementTier.copper;
    switch (raw.toLowerCase().trim()) {
      case 'copper':
        return AchievementTier.copper;
      case 'bronze':
        return AchievementTier.bronze;
      case 'iron':
        return AchievementTier.ruby;
      case 'silver':
        return AchievementTier.silver;
      case 'gold':
        return AchievementTier.gold;
      case 'platinum':
        return AchievementTier.platinum;
      case 'obsidian':
        return AchievementTier.obsidian;
      case 'diamond':
        return AchievementTier.diamond;
      default:
        return AchievementTier.copper;
    }
  }

  /// Base tier from numeric target (max progress).
  static AchievementTier fromTarget(int target) {
    if (target <= 1) return AchievementTier.copper;
    if (target <= 5) return AchievementTier.bronze;
    if (target <= 15) return AchievementTier.ruby;
    if (target <= 40) return AchievementTier.silver;
    if (target <= 100) return AchievementTier.gold;
    if (target <= 250) return AchievementTier.platinum;
    if (target <= 500) return AchievementTier.obsidian;
    return AchievementTier.diamond;
  }

  AchievementTier bump(int steps) {
    final i = (index + steps).clamp(0, AchievementTier.values.length - 1);
    return AchievementTier.values[i];
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final int currentProgress;
  final int maxProgress;
  final String category;
  final AchievementTier tier;
  final Color? iconColor;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.currentProgress,
    required this.maxProgress,
    required this.category,
    this.tier = AchievementTier.copper,
    this.iconColor,
  });

  /// Colour to show for the icon when unlocked.
  Color get displayColor => iconColor ?? tier.color;
}
