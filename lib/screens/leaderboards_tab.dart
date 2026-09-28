import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/leaderboard_league.dart';
import '../services/alias_storage.dart';
import '../widgets/alias_setup_dialog.dart';
import 'league_detail_screen.dart';
import 'groups_hub_screen.dart';

class LeaderboardsTab extends StatefulWidget {
  final Map<String, int> userScores;
  final String userRankEmoji;

  const LeaderboardsTab({
    super.key,
    required this.userScores,
    required this.userRankEmoji,
  });

  @override
  State<LeaderboardsTab> createState() => _LeaderboardsTabState();
}

class _LeaderboardsTabState extends State<LeaderboardsTab> {
  bool _hasOptedIn = false;
  String? _alias;
  bool _showPrivate = false;

  @override
  void initState() {
    super.initState();
    _checkAlias();
  }

  Future<void> _checkAlias() async {
    final optedIn = await AliasStorage.hasOptedIn();
    final alias = await AliasStorage.getAlias();
    if (mounted) {
      setState(() {
        _hasOptedIn = optedIn;
        _alias = alias;
      });
    }
  }

  Future<void> _editProfile() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => const AliasSetupDialog(),
    );
    if (updated == true) {
      await _checkAlias();
    }
  }

  void _openLeague(LeaderboardLeague league) async {
    if (!_hasOptedIn || _alias == null) {
      final joined = await showDialog<bool>(
        context: context,
        builder: (ctx) => const AliasSetupDialog(),
      );
      if (joined == true) {
        await _checkAlias();
        if (!mounted) return;
      } else {
        return; // User cancelled
      }
    }

    if (!mounted || _alias == null) return;
    
    final customIcon = await AliasStorage.getIcon();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeagueDetailScreen(
          league: league,
          userAlias: _alias!,
          userEmoji: customIcon ?? widget.userRankEmoji,
          userScore: widget.userScores[league.id] ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showPrivate = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showPrivate ? AppTheme.primary : AppTheme.surfaceSolid,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Global Leagues',
                      style: TextStyle(
                        color: !_showPrivate ? Colors.white : AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showPrivate = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showPrivate ? AppTheme.primary : AppTheme.surfaceSolid,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Private Groups',
                      style: TextStyle(
                        color: _showPrivate ? Colors.white : AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_hasOptedIn && _alias != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: _editProfile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(widget.userRankEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Playing as (Tap to edit)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          Text(_alias!, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: _showPrivate
              ? GroupsHubScreen(
                  userScores: widget.userScores,
                  userAlias: _alias ?? 'Unknown',
                  userRankEmoji: widget.userRankEmoji,
                )
              : CustomScrollView(
                  slivers: [
                    const SliverPadding(padding: EdgeInsets.only(top: 8)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final league = LeaderboardLeague.allLeagues[index];
                            final myScore = widget.userScores[league.id] ?? 0;

                            return GestureDetector(
                              onTap: () => _openLeague(league),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceSolid,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Hero(
                                      tag: league.id,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          league.imageAsset, 
                                          width: 64, 
                                          height: 64, 
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 64),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      league.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Text(
                                        league.subtitle,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$myScore ${league.metricUnit}',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: LeaderboardLeague.allLeagues.length,
                        ),
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                  ],
                ),
        ),
      ],
    );
  }
}
