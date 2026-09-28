class LeaderboardLeague {
  final String id;
  final String title;
  final String subtitle;
  final String imageAsset;
  final String metricUnit;
  final String description;

  const LeaderboardLeague({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.metricUnit,
    required this.description,
  });

  static const List<LeaderboardLeague> allLeagues = [
    LeaderboardLeague(
      id: 'all_time_xp',
      title: 'The Hall of Fame',
      subtitle: 'All-Time XP',
      imageAsset: 'assets/leagues/hall_of_fame.jpg',
      metricUnit: 'XP',
      description: 'The absolute legends of the app. Ranked by total lifetime Experience Points.',
    ),
    LeaderboardLeague(
      id: 'monthly_xp',
      title: 'The Monthly Hustle',
      subtitle: 'Monthly XP',
      imageAsset: 'assets/leagues/monthly_hustle.jpg',
      metricUnit: 'XP',
      description: 'Who has gained the most XP this current month. Resets every 30 days.',
    ),
    LeaderboardLeague(
      id: 'night_shift',
      title: 'The 3 AM Club',
      subtitle: 'Night Shifts',
      imageAsset: 'assets/leagues/three_am_club.jpg',
      metricUnit: 'Cases',
      description: 'Validating the brutal night shifts. Ranked by cases logged between 00:00 and 06:00.',
    ),
    LeaderboardLeague(
      id: 'high_acuity',
      title: 'The Heavyweight Champion',
      subtitle: 'High Acuity',
      imageAsset: 'assets/leagues/heavyweight_champion.jpg',
      metricUnit: 'Cases',
      description: 'Ranked by volume of high-acuity cases: ASA 4 & 5, and emergency cases of ASA 3, 4, and 5.',
    ),
    LeaderboardLeague(
      id: 'regional',
      title: 'The Block Master',
      subtitle: 'Regional Blocks',
      imageAsset: 'assets/leagues/block_master.jpg',
      metricUnit: 'Blocks',
      description: 'Ranked by the total number of regional anaesthesia blocks performed.',
    ),
    LeaderboardLeague(
      id: 'paediatric',
      title: 'The Paediatric Whisperer',
      subtitle: 'Paediatrics (<16)',
      imageAsset: 'assets/leagues/paediatric_whisperer.jpg',
      metricUnit: 'Cases',
      description: 'Masters of the small airways. Ranked by cases with patients under 16 years old.',
    ),
    LeaderboardLeague(
      id: 'geriatric',
      title: 'The Geriatric Guardian',
      subtitle: 'Geriatrics (80+)',
      imageAsset: 'assets/leagues/geriatric_guardian.jpg',
      metricUnit: 'Cases',
      description: 'Ranked by cases involving elderly and often frail patients over 80 years old.',
    ),
    LeaderboardLeague(
      id: 'airway',
      title: 'The Airway Ninja',
      subtitle: 'Complex Airways',
      imageAsset: 'assets/leagues/airway_ninja.jpg',
      metricUnit: 'Airways',
      description: 'Ranked by volume of difficult airways, videolaryngoscopies, and fibreoptic intubations.',
    ),
    LeaderboardLeague(
      id: 'invasive',
      title: 'The Line Lord',
      subtitle: 'Invasive Lines',
      imageAsset: 'assets/leagues/line_lord.jpg',
      metricUnit: 'Lines',
      description: 'Ranked by total invasive monitoring lines (A-lines, CVCs, PACs) inserted.',
    ),
    LeaderboardLeague(
      id: 'high_volume',
      title: 'The Turnover Titan',
      subtitle: 'Max Cases / 8hr',
      imageAsset: 'assets/leagues/turnover_titan.jpg',
      metricUnit: 'Cases/8hr',
      description: 'The efficiency kings. Ranked by the highest number of cases completed within any single 8-hour window.',
    ),
    LeaderboardLeague(
      id: 'obstetric',
      title: 'The Obstetric Hero',
      subtitle: 'Obstetrics',
      imageAsset: 'assets/leagues/obstetric_hero.jpg',
      metricUnit: 'Cases',
      description: 'Ranked by total cases in the Obstetric specialty.',
    ),
    LeaderboardLeague(
      id: 'endurance',
      title: 'The Marathon Runner',
      subtitle: 'Cases > 6 hrs',
      imageAsset: 'assets/leagues/marathon_runner.jpg',
      metricUnit: 'Cases',
      description: 'Ranked by the number of gruelling, endurance cases lasting over 6 hours.',
    ),
  ];
}
