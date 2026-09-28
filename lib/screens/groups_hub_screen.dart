import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../models/leaderboard_league.dart';
import 'league_detail_screen.dart';
import '../theme/app_theme.dart';

class GroupsHubScreen extends StatefulWidget {
  final Map<String, int> userScores;
  final String userAlias;
  final String userRankEmoji;

  const GroupsHubScreen({
    super.key,
    required this.userScores,
    required this.userAlias,
    required this.userRankEmoji,
  });

  @override
  State<GroupsHubScreen> createState() => _GroupsHubScreenState();
}

class _GroupsHubScreenState extends State<GroupsHubScreen> {
  List<Group> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final groups = await GroupService.getJoinedGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _createGroup() {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSolid,
        title: Text('Create Private Group', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: tc,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Mass Gen Residents',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tc.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _loading = true);
              await GroupService.createGroup(tc.text.trim());
              _loadGroups();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinGroup() {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSolid,
        title: Text('Join Group', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: tc,
          style: TextStyle(color: AppTheme.textPrimary),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit code',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tc.text.trim().isEmpty) return;
              final code = tc.text.trim().toUpperCase();
              Navigator.pop(ctx);
              setState(() => _loading = true);
              try {
                await GroupService.joinGroup(code);
                _loadGroups();
              } catch (e) {
                setState(() => _loading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim())),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _leaveGroup(Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSolid,
        title: Text('Leave Group', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Are you sure you want to leave "${group.name}"?', style: TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              await GroupService.leaveGroup(group.id);
              _loadGroups();
            },
            child: Text('Leave', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  void _openGroupLeagues(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _GroupLeaguesListScreen(
          group: group,
          userScores: widget.userScores,
          userAlias: widget.userAlias,
          userRankEmoji: widget.userRankEmoji,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Private Hospital Leagues',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Compete exclusively against your own department or residency program.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _joinGroup,
                      icon: const Icon(Icons.group_add),
                      label: const Text('Join Code'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _createGroup,
                      icon: const Icon(Icons.add),
                      label: const Text('Create'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_groups.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'You haven\'t joined any private groups yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ..._groups.map((g) => Card(
                      color: AppTheme.surfaceSolid,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(g.name, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text('Invite Code: ${g.id}', style: TextStyle(color: AppTheme.textSecondary)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.exit_to_app, color: AppTheme.danger.withValues(alpha: 0.8)),
                              onPressed: () => _leaveGroup(g),
                              tooltip: 'Leave Group',
                            ),
                            Icon(Icons.chevron_right, color: AppTheme.primary),
                          ],
                        ),
                        onTap: () => _openGroupLeagues(g),
                      ),
                    )),
            ],
          );
  }
}

class _GroupLeaguesListScreen extends StatelessWidget {
  final Group group;
  final Map<String, int> userScores;
  final String userAlias;
  final String userRankEmoji;

  const _GroupLeaguesListScreen({
    required this.group,
    required this.userScores,
    required this.userAlias,
    required this.userRankEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceSolid,
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code ${group.id} copied to clipboard!')));
            },
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: LeaderboardLeague.allLeagues.length,
        itemBuilder: (context, index) {
          final league = LeaderboardLeague.allLeagues[index];
          final myScore = userScores[league.id] ?? 0;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeagueDetailScreen(
                    league: league,
                    userAlias: userAlias,
                    userEmoji: userRankEmoji,
                    userScore: myScore,
                    groupId: group.id, // passing the groupId!
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSolid,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: '${group.id}_${league.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(league.imageAsset, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, size: 64)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(league.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(league.subtitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('$myScore ${league.metricUnit}', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
