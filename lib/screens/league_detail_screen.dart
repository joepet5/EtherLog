import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/leaderboard_league.dart';
import '../services/leaderboard_service.dart';
import '../services/firebase_leaderboard_service.dart';

class LeagueDetailScreen extends StatefulWidget {
  final LeaderboardLeague league;
  final String userAlias;
  final String userEmoji;
  final int userScore;
  final String? groupId;

  const LeagueDetailScreen({
    super.key,
    required this.league,
    required this.userAlias,
    required this.userEmoji,
    required this.userScore,
    this.groupId,
  });

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = FirebaseLeaderboardService.getLeaderboardForLeague(
      widget.league,
      widget.userAlias,
      widget.userEmoji,
      widget.userScore,
      groupId: widget.groupId,
    );
  }


  Future<void> _refresh() async {
    setState(() {
      _leaderboardFuture = FirebaseLeaderboardService.getLeaderboardForLeague(
        widget.league,
        widget.userAlias,
        widget.userEmoji,
        widget.userScore,
        groupId: widget.groupId,
      );
    });
    await _leaderboardFuture;
  }

  Widget _buildMedal(int index) {
    if (index == 0) return const SizedBox(width: 36, child: Center(child: Text('🥇', style: TextStyle(fontSize: 24))));
    if (index == 1) return const SizedBox(width: 36, child: Center(child: Text('🥈', style: TextStyle(fontSize: 24))));
    if (index == 2) return const SizedBox(width: 36, child: Center(child: Text('🥉', style: TextStyle(fontSize: 24))));
    return SizedBox(
      width: 36,
      child: Text(
        '#${index + 1}',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.league.title, style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primary),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading leaderboard', style: TextStyle(color: AppTheme.danger)));
          }

          final entries = snapshot.data!;
          final userIndex = entries.indexWhere((e) => e.isCurrentUser);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Hero(
                      tag: widget.league.id,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          widget.league.imageAsset,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.league.description,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: entries.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.45,
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.emoji_events_outlined,
                                      size: 64,
                                      color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No active entries yet',
                                    style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Log cases to claim the #1 spot on this leaderboard!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppTheme.textSecondary, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                          final entry = entries[index];
                          final isUser = entry.isCurrentUser;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isUser ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceSolid,
                        borderRadius: BorderRadius.circular(16),
                        border: isUser ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2) : null,
                      ),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMedal(index),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              backgroundColor: AppTheme.background,
                              child: Text(entry.rankEmoji, style: const TextStyle(fontSize: 20)),
                            ),
                          ],
                        ),
                        title: Text(
                          entry.alias,
                          style: TextStyle(
                            color: isUser ? AppTheme.primary : AppTheme.textPrimary,
                            fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${entry.score}',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.league.metricUnit,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Sticky User Banner
              if (userIndex >= 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSolid,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        _buildMedal(userIndex),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You are Rank #${userIndex + 1}',
                                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                              ),
                              if (userIndex > 0)
                                Text(
                                  '${entries[userIndex - 1].score - entries[userIndex].score} ${widget.league.metricUnit} away from #$userIndex',
                                  style: TextStyle(color: AppTheme.primary, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${entries[userIndex].score}',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (widget.userScore <= 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSolid,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Score at least 1 ${widget.league.metricUnit} to enter this leaderboard.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                        Text(
                          '0 ${widget.league.metricUnit}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
