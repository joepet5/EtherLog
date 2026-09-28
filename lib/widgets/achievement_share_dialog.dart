import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/achievement.dart';
import '../services/rank_service.dart';
import '../utils/achievement_sharing.dart';
import '../l10n/achievement_localizations.dart';
import '../l10n/app_localizations.dart';

class AchievementShareDialog extends StatefulWidget {
  final Achievement achievement;
  final String? customTitle;
  final String? customDescription;

  const AchievementShareDialog({
    super.key,
    required this.achievement,
    this.customTitle,
    this.customDescription,
  });

  static Future<void> show(
    BuildContext context,
    Achievement achievement, {
    String? customTitle,
    String? customDescription,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => AchievementShareDialog(
        achievement: achievement,
        customTitle: customTitle,
        customDescription: customDescription,
      ),
    );
  }

  @override
  State<AchievementShareDialog> createState() => _AchievementShareDialogState();
}

class _AchievementShareDialogState extends State<AchievementShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;

  IconData _getTierIcon(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.diamond:
        return Icons.diamond_rounded;
      case AchievementTier.obsidian:
        return Icons.auto_awesome_rounded;
      case AchievementTier.platinum:
        return Icons.military_tech_rounded;
      case AchievementTier.gold:
        return Icons.stars_rounded;
      case AchievementTier.silver:
        return Icons.shield_rounded;
      case AchievementTier.ruby:
        return Icons.favorite_rounded;
      case AchievementTier.bronze:
        return Icons.workspace_premium_rounded;
      case AchievementTier.copper:
        return Icons.circle_outlined;
    }
  }

  String _getTierEmoji(AchievementTier tier) {
    return AchievementSharing.getTierEmoji(tier);
  }

  String _buildShareText(String title, String description) {
    return AchievementSharing.buildShareText(
      widget.achievement,
      customTitle: title,
      customDescription: description,
    );
  }

  Future<void> _shareImage(String title, String description) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      // Allow rendering to settle
      await Future.delayed(const Duration(milliseconds: 120));

      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();
      final cleanId = widget.achievement.id.replaceAll(RegExp(r'[^\w]'), '_');
      final file = File('${tempDir.path}/etherlog_badge_$cleanId.png');
      await file.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );

      final shareText = _buildShareText(title, description);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'EtherLog Achievement: $title',
      );
    } catch (e) {
      debugPrint('Error sharing achievement badge: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareTextOnly(String title, String description) async {
    final shareText = _buildShareText(title, description);
    await Share.share(
      shareText,
      subject: 'EtherLog Achievement: $title',
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final ach = widget.achievement;

    final title = widget.customTitle ??
        AchievementLocalizations.getTitle(ach.id, ach.title, locale);
    final description = widget.customDescription ??
        AchievementLocalizations.getDescription(ach.id, ach.description, locale);

    final tier = ach.tier;
    final tierColor = ach.displayColor;
    final tierXp = RankService.tierPoints[tier] ?? 10;
    final tierIcon = _getTierIcon(tier);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The Visual Badge Card captured for sharing
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: 360,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Slate 900
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: tierColor.withValues(alpha: 0.6),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.35),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                    const BoxShadow(
                      color: Colors.black87,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      // Ambient Radial Background Glow
                      Positioned(
                        top: -60,
                        left: -60,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                tierColor.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -60,
                        right: -60,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                tierColor.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // App Brand Header & Category
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.medical_services_rounded,
                                        size: 14,
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'ETHERLOG',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Text(
                                    ach.category.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Floating Glowing Jewel Icon
                            Center(
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      tierColor.withValues(alpha: 0.6),
                                      tierColor.withValues(alpha: 0.2),
                                      const Color(0xFF0F172A),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: tierColor.withValues(alpha: 0.7),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    ach.icon,
                                    size: 54,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Tier Badge Pill (Visual Tier with XP)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: tierColor.withValues(alpha: 0.8),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: tierColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(tierIcon, color: tierColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${tier.displayName.toUpperCase()} TIER  •  +$tierXp XP',
                                    style: TextStyle(
                                      color: tierColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Title
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Witty Line in Stylish Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                '“$description”',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 13.5,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Status Pill
                            if (ach.isUnlocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.stars_rounded,
                                      color: Colors.amber,
                                      size: 15,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'VERIFIED & UNLOCKED',
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                'Progress: ${ach.currentProgress} / ${ach.maxProgress} (${(ach.maxProgress > 0 ? (ach.currentProgress / ach.maxProgress * 100).toInt() : 0)}%)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                            const SizedBox(height: 20),

                            // Watermark Footer
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Colors.white38,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'EtherLog • Clinical Anaesthesia Portfolio',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Share Actions
            SizedBox(
              width: 360,
              child: Column(
                children: [
                  // Primary Share Image Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _shareImage(title, description),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 20),
                      label: Text(
                        _isExporting ? 'Generating Badge...' : 'Share Badge Image',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tierColor,
                        foregroundColor: tier == AchievementTier.silver
                            ? Colors.blue.shade900
                            : Colors.white,
                        elevation: 8,
                        shadowColor: tierColor.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Secondary Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareTextOnly(title, description),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text(
                            'Share Text',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
