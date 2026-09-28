import 'dart:math';
import '../models/leaderboard_league.dart';

class LeaderboardEntry {
  final String alias;
  final String rankEmoji;
  final int score;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.alias,
    required this.rankEmoji,
    required this.score,
    this.isCurrentUser = false,
  });
}

class LeaderboardService {
  static final _random = Random(42); // Fixed seed for consistent mock data

  static const _mockAliases = [
    'SleepDoc99', 'AirwayNinja', 'ThePropofolWhisperer', 'GasMan',
    'BlockMaster_X', 'Intubator3000', 'LmaQueen', 'DrDream', 'NightOwl_Anaes',
    'SuggamadexFan', 'MacBlade', 'RegionalHero', 'CricoidPressure', 'SuxLife',
    'KetamineKev', 'RocStar', 'TivaTime', 'EpiduralExpert', 'SpinalTap',
    'TheMac', 'AwakeFOB', 'DesfluraneDestroyer', 'SevoSurfer', 'PreOxygenator'
  ];

  static const _mockEmojis = ['🎒', '💉', '📋', '☕', '🦸', '🦉', '🤹', '🎯', '🧠', '💼', '🗞️', '👑'];

  static Future<List<LeaderboardEntry>> getLeaderboardForLeague(
      LeaderboardLeague league, String userAlias, String userEmoji, int userScore) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final entries = <LeaderboardEntry>[];
    
    // Add user
    entries.add(LeaderboardEntry(
      alias: userAlias,
      rankEmoji: userEmoji,
      score: userScore,
      isCurrentUser: true,
    ));

    // Determine scale for this league
    int maxScore = 0;
    if (league.metricUnit == 'XP') {
      maxScore = 150000; // Large number for XP
    } else if (league.metricUnit == 'Cases') {
      maxScore = 1000;
    } else {
      maxScore = 300;
    }

    // Generate 50 mock entries
    for (int i = 0; i < 50; i++) {
      final alias = _mockAliases[_random.nextInt(_mockAliases.length)] + _random.nextInt(99).toString();
      final emoji = _mockEmojis[_random.nextInt(_mockEmojis.length)];
      
      // We want a curve where a few are very high, many are in the middle
      final scoreVal = (_random.nextDouble() * _random.nextDouble() * maxScore).toInt();
      
      entries.add(LeaderboardEntry(
        alias: alias,
        rankEmoji: emoji,
        score: scoreVal,
      ));
    }

    // Sort descending by score
    entries.sort((a, b) => b.score.compareTo(a.score));

    return entries;
  }
}
