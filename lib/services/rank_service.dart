import '../models/achievement.dart';

class AchievementRank {
  final String name;
  final String subtitle;
  final int currentPoints;
  final int pointsForCurrentRank;
  final int? pointsForNextRank;

  AchievementRank({
    required this.name,
    required this.subtitle,
    required this.currentPoints,
    required this.pointsForCurrentRank,
    this.pointsForNextRank,
  });

  double get progressToNext {
    if (pointsForNextRank == null) return 1.0;
    if (currentPoints <= pointsForCurrentRank) return 0.0;
    return (currentPoints - pointsForCurrentRank) / (pointsForNextRank! - pointsForCurrentRank);
  }
}

class RankService {
  static const Map<AchievementTier, int> tierPoints = {
    AchievementTier.copper: 10,
    AchievementTier.bronze: 25,
    AchievementTier.ruby: 50,
    AchievementTier.silver: 100,
    AchievementTier.gold: 250,
    AchievementTier.platinum: 500,
    AchievementTier.obsidian: 1000,
    AchievementTier.diamond: 2500,
  };

  static final List<Map<String, dynamic>> _ranks = [
    {
      'name': 'Medical Student',
      'subtitle': 'Standing awkwardly by the anaesthetic machine, afraid to touch anything.',
      'threshold': 0
    },
    {
      'name': 'Ward IV Service',
      'subtitle': 'Getting constantly bleeped because \"the ward nurses have already tried twice.\"',
      'threshold': 100
    },
    {
      'name': 'Pre-Op Survivor',
      'subtitle': 'Navigating a sea of missing notes and incomplete drug charts.',
      'threshold': 500
    },
    {
      'name': 'Coffee Room Regular',
      'subtitle': 'You\\'ve finally memorised the exact schedule of the espresso machine.',
      'threshold': 1500
    },
    {
      'name': 'Break Relief Hero',
      'subtitle': 'The most beloved person in the entire department at exactly 10:30 AM.',
      'threshold': 3500
    },
    {
      'name': 'Night On-Call Veteran',
      'subtitle': 'Functioning at 3 AM purely on adrenaline and stale biscuits.',
      'threshold': 7500
    },
    {
      'name': 'List Coordinator',
      'subtitle': 'Endlessly negotiating \"just one quick add-on\" with the surgical team.',
      'threshold': 12500
    },
    {
      'name': 'Regional Block Fanatic',
      'subtitle': 'Offering to do a complex ultrasound-guided block for literally any surgical procedure.',
      'threshold': 20000
    },
    {
      'name': 'The Educator',
      'subtitle': 'Grilling the poor medical students on the exact pharmacology of propofol.',
      'threshold': 35000
    },
    {
      'name': 'Clinical Lead',
      'subtitle': 'Spending more time in morbidity meetings than in theatre.',
      'threshold': 50000
    },
    {
      'name': 'Senior Consultant',
      'subtitle': 'Doing the crossword while the junior resident sweats over the airway.',
      'threshold': 65000
    },
    {
      'name': 'The Oracle',
      'subtitle': 'The one everyone calls in at 2 AM when Plan A, B, and C have failed.',
      'threshold': 71500
    },
  ];

  static int calculateTotalPoints(List<Achievement> achievements) {
    int total = 0;
    for (final ach in achievements) {
      if (ach.isUnlocked) {
        total += tierPoints[ach.tier] ?? 0;
      }
    }
    return total;
  }

  static AchievementRank getRank(List<Achievement> achievements) {
    final points = calculateTotalPoints(achievements);
    
    int currentRankIndex = 0;
    for (int i = 0; i < _ranks.length; i++) {
      if (points >= (_ranks[i]['threshold'] as int)) {
        currentRankIndex = i;
      } else {
        break;
      }
    }

    final currentRank = _ranks[currentRankIndex];
    final nextRank = currentRankIndex < _ranks.length - 1 ? _ranks[currentRankIndex + 1] : null;

    return AchievementRank(
      name: currentRank['name'] as String,
      subtitle: currentRank['subtitle'] as String,
      currentPoints: points,
      pointsForCurrentRank: currentRank['threshold'] as int,
      pointsForNextRank: nextRank?['threshold'] as int?,
    );
  }
}
