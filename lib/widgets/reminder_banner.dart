import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/reminder_service.dart';
import '../services/template_storage.dart';
import '../screens/new_case_screen.dart';
import '../l10n/app_localizations.dart';

/// Drop this near the top of the dashboard body (below AppBar content).
class ReminderBanner extends StatefulWidget {
  final VoidCallback? onChanged;
  const ReminderBanner({super.key, this.onChanged});

  @override
  State<ReminderBanner> createState() => _ReminderBannerState();
}

class _ReminderBannerState extends State<ReminderBanner> {
  ReminderInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await ReminderService.evaluate();
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _info == null || !_info!.hasAny) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final info = _info!;
    return Column(
      children: [
        if (info.showIncompleteDraft) _card(
          icon: Icons.edit_note,
          color: AppTheme.primary,
          title: l10n.incompleteCaseDraft,
          subtitle: info.draftSavedAt != null
              ? l10n.incompleteDraftSaved(DateFormat('dd MMM, HH:mm').format(info.draftSavedAt!))
              : l10n.incompleteDraftSubtitle,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewCaseScreen()),
            );
            _load();
            widget.onChanged?.call();
          },
          trailing: IconButton(
            icon: Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
            onPressed: () async {
              await TemplateStorage.clearDraft();
              _load();
              widget.onChanged?.call();
            },
          ),
        ),
        if (info.showInactivity) _card(
          icon: Icons.notifications_active_outlined,
          color: const Color(0xFFF59E0B),
          title: l10n.noCasesInDays(info.daysSinceLastCase),
          subtitle: info.lastCaseDate != null
              ? l10n.lastCaseOn(DateFormat('dd MMM yyyy').format(info.lastCaseDate!))
              : l10n.timeForLogbookEntry,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewCaseScreen()),
            );
            _load();
            widget.onChanged?.call();
          },
        ),
      ],
    );
  }

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}