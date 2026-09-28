import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/league_calculator.dart';
import '../services/case_storage.dart';
import '../services/achievement_service.dart';
import '../services/alias_storage.dart';
import '../services/firebase_leaderboard_service.dart';
import '../widgets/alias_setup_dialog.dart';
import 'leaderboards_tab.dart';

class LeaderboardsScreen extends StatefulWidget {
  final String userRankEmoji; // fallback
  
  const LeaderboardsScreen({super.key, required this.userRankEmoji});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final cases = await CaseStorage.getAllCases();
    final achievements = await AchievementService.getAllAchievements(cases);
    final scores = await LeagueCalculator.calculateAllScores(cases, achievements);
    final customIcon = await AliasStorage.getIcon();
    // Keep Firebase in sync with calculated scores across all leagues
    FirebaseLeaderboardService.syncAllLeagues(providedCases: cases);
    return {
      'scores': scores,
      'icon': customIcon,
    };
  }

  void _editProfile() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AliasSetupDialog(),
    );
    if (result == true) {
      setState(() {
        _dataFuture = _fetchData(); // reload so custom icon updates
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Global Leaderboards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts, color: AppTheme.primary),
            tooltip: 'Edit Profile',
            onPressed: _editProfile,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load leaderboards.', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          final scores = snapshot.data?['scores'] as Map<String, int>? ?? {};
          final icon = snapshot.data?['icon'] as String?;
          
          return LeaderboardsTab(
            userScores: scores,
            userRankEmoji: icon ?? widget.userRankEmoji,
          );
        },
      ),
    );
  }
}
