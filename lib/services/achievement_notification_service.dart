import 'dart:async';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/achievement_localizations.dart';

/// Shows achievement unlock banners one after another (queue).
/// Uses the root overlay so banners survive Navigator.pop after save.
class AchievementNotificationService {
  static OverlayEntry? _currentOverlay;
  static final List<Achievement> _queue = [];
  static bool _showing = false;
  static OverlayState? _overlay;

  /// Enqueue a single achievement. Safe to call multiple times in a row.
  static void show(BuildContext context, Achievement achievement) {
    _overlay ??= Overlay.maybeOf(context, rootOverlay: true);
    _queue.add(achievement);
    if (!_showing) {
      _processQueue();
    }
  }

  /// Enqueue many achievements and show them sequentially.
  static void showAll(BuildContext context, List<Achievement> achievements) {
    if (achievements.isEmpty) return;
    _overlay ??= Overlay.maybeOf(context, rootOverlay: true);
    _queue.addAll(achievements);
    if (!_showing) {
      _processQueue();
    }
  }

  static Future<void> _processQueue() async {
    if (_showing) return;
    _showing = true;

    while (_queue.isNotEmpty) {
      final overlay = _overlay;
      if (overlay == null) {
        _queue.clear();
        break;
      }

      final next = _queue.removeAt(0);
      final completer = Completer<void>();
      _showOne(overlay, next, onDone: () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
      // Brief gap between banners
      await Future.delayed(const Duration(milliseconds: 400));
    }

    _showing = false;
  }

  static void _showOne(
      OverlayState overlay,
      Achievement achievement, {
        required VoidCallback onDone,
      }) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AchievementPopupWidget(
        achievement: achievement,
        onDismiss: () {
          try {
            entry.remove();
          } catch (_) {}
          if (_currentOverlay == entry) _currentOverlay = null;
          onDone();
        },
      ),
    );

    _currentOverlay = entry;
    overlay.insert(entry);
  }

  /// Clear any pending banners (e.g. on logout).
  static void clear() {
    _queue.clear();
    try {
      _currentOverlay?.remove();
    } catch (_) {}
    _currentOverlay = null;
    _showing = false;
  }
}

class _AchievementPopupWidget extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const _AchievementPopupWidget({
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<_AchievementPopupWidget> createState() => _AchievementPopupWidgetState();
}

class _AchievementPopupWidgetState extends State<_AchievementPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    // Visible duration, then slide out and dismiss
    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (!mounted || _dismissed) return;
      await _controller.reverse();
      _finish();
    });
  }

  void _finish() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.achievement.iconColor ?? AppTheme.primary;
    final top = MediaQuery.of(context).padding.top + 8;

    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final title = AchievementLocalizations.getTitle(widget.achievement.id, widget.achievement.title, locale);
    final desc = AchievementLocalizations.getDescription(widget.achievement.id, widget.achievement.description, locale);
    final categoryName = AchievementLocalizations.getCategoryName(widget.achievement.category, locale);

    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () async {
                if (_dismissed) return;
                await _controller.reverse();
                _finish();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        color: accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.achievementUnlocked,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                categoryName.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}