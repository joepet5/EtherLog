import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/alias_storage.dart';
import '../services/firebase_leaderboard_service.dart';

class AliasSetupDialog extends StatefulWidget {
  const AliasSetupDialog({super.key});

  @override
  State<AliasSetupDialog> createState() => _AliasSetupDialogState();
}

class _AliasSetupDialogState extends State<AliasSetupDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  String _selectedIcon = '🥷';

  final List<String> _availableIcons = [
    '🥷', '🩺', '😴', '🦸‍♂️', '🦸‍♀️', '🦹', '🧙‍♂️', '🧜‍♀️', '🧛', '🧟', 
    '🦉', '🦁', '🦖', '🐉', '👽', '👻', '🤖', '👾', '🔥', '💧', 
    '⚡', '🌟', '💉', '🩹', '🦊', '🐼', '🐯', '🦄', '🦇', '🐵', 
    '🐸', '🐨', '🐻', '🐰', '🐭', '🐱', '🐶', '🐻‍❄️', '🐙', '🦑', 
    '🦋', '🐞', '🐢', '🐍', '🦕', '🦂', '🦈', '🐊', '🐅', '🐆', 
    '🦏', '🦍', '🦧', '🐘', '🦛', '🐪', '🐫', '🦒', '🦘', '🦬', 
    '🐃', '🐂', '🐄', '🐎', '🐖', '🐏', '🐑', '🦙', '🐐', '🦌', 
    '🐕', '🐩', '🦮', '🐕‍🦺', '🐈', '🐈‍⬛', '🐓', '🦃', '🦚', '🦜', 
    '🦢', '🦩', '🕊️', '🐇', '🦝', '🦨', '🦡', '🦦', '🦥', '🐁', 
    '🐀', '🐿️', '💊', '🧬', '🔬', '🚑', '🏥', '🧠', '🫀', '🫁', '🦴',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existingAlias = await AliasStorage.getAlias();
    final existingIcon = await AliasStorage.getIcon();
    if (mounted) {
      if (existingAlias != null) _controller.text = existingAlias;
      if (existingIcon != null && _availableIcons.contains(existingIcon)) {
        setState(() => _selectedIcon = existingIcon);
      }
    }
  }

  Future<void> _saveAlias() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alias must be at least 3 characters long.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final uid = await FirebaseLeaderboardService.getUserId();
    final claimResult = await FirebaseLeaderboardService.claimAlias(text, uid);
    if (!claimResult.success) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(claimResult.errorMessage ?? 'Alias unavailable.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    await AliasStorage.setAlias(text, icon: _selectedIcon);
    await FirebaseLeaderboardService.syncAllLeagues();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceSolid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        children: [
          Icon(Icons.public, size: 48, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            'Leaderboard Profile',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Customize how you appear to others entirely anonymously.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: AppTheme.primary, width: 2) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(icon, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Choose an Alias (e.g. SleepDoc99)',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                ),
                maxLength: 20,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveAlias(),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveAlias,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
