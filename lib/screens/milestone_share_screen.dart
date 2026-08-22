import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/insights_service.dart';
import '../widgets/animated_gradient_background.dart';

class MilestoneShareScreen extends StatefulWidget {
  final InsightsData data;
  const MilestoneShareScreen({super.key, required this.data});

  @override
  State<MilestoneShareScreen> createState() => _MilestoneShareScreenState();
}

class _MilestoneShareScreenState extends State<MilestoneShareScreen> {
  final GlobalKey _posterKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      // Small delay to allow any loading states to clear if necessary
      await Future.delayed(const Duration(milliseconds: 100));
      
      final boundary = _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final buffer = byteData.buffer;
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/etherlog_milestone_${widget.data.year}.png');
      await file.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      
      await Share.shareXFiles([XFile(file.path)], text: 'My Etherlog ${widget.data.year} in Review!');
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = widget.data;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the share screen
      appBar: AppBar(title: Text('Share Milestone'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _posterKey,
                  child: Container(
                    width: 350,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary.withValues(alpha: 0.9), const Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ETHERLOG',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${d.year}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.yourYearInReview(d.year),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Top Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(l10n.cases, '${d.totalCases}', Colors.white),
                            _buildStat(l10n.avgDuration, d.overallAvgMinutes == 0 ? '-' : '${d.overallAvgMinutes.toStringAsFixed(0)}m', Colors.cyanAccent),
                            _buildStat(l10n.uneventful, '${d.overallUneventfulPercent.toStringAsFixed(0)}%', Colors.greenAccent),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Top Specialties
                        if (d.topSpecialties.isNotEmpty) ...[
                          _buildSectionTitle(l10n.topSpecialties),
                          const SizedBox(height: 12),
                          ...d.topSpecialties.take(3).map((s) => _buildBar(l10n.term(s.name), s.count, d.topSpecialties.first.count, Colors.cyanAccent)),
                          const SizedBox(height: 24),
                        ],

                        // Top Blocks
                        if (d.topBlocks.isNotEmpty) ...[
                          _buildSectionTitle(l10n.topRegionalBlocks),
                          const SizedBox(height: 12),
                          ...d.topBlocks.take(3).map((b) => _buildBar(l10n.term(b.name), b.count, d.topBlocks.first.count, Colors.purpleAccent)),
                          const SizedBox(height: 24),
                        ],
                        
                        // ASA Mix
                        if (d.asaMix.isNotEmpty) ...[
                          _buildSectionTitle(l10n.asaMix),
                          const SizedBox(height: 12),
                          ...d.asaMix.take(3).map((a) => _buildBar(l10n.term(a.name), a.count, d.asaMix.first.count, Colors.orangeAccent)),
                          const SizedBox(height: 24),
                        ],
                        
                        // Top Airways
                        if (d.topAirways.isNotEmpty) ...[
                          _buildSectionTitle('Top Airways'),
                          const SizedBox(height: 12),
                          ...d.topAirways.take(3).map((a) => _buildBar(a.name, a.count, d.topAirways.first.count, Colors.lightBlueAccent)),
                          const SizedBox(height: 24),
                        ],

                        // Top Complications
                        if (d.topComplications.isNotEmpty) ...[
                          _buildSectionTitle('Top Complications'),
                          const SizedBox(height: 12),
                          ...d.topComplications.take(3).map((c) => _buildBar(c.name, c.count, d.topComplications.first.count, Colors.redAccent)),
                          const SizedBox(height: 24),
                        ],

                        // Top Techniques
                        if (d.topTechniques.isNotEmpty) ...[
                          _buildSectionTitle('Top Techniques'),
                          const SizedBox(height: 12),
                          ...d.topTechniques.take(3).map((tech) => _buildBar(l10n.term(tech.name), tech.count, d.topTechniques.first.count, Colors.amberAccent)),
                          const SizedBox(height: 24),
                        ],

                        // Top Invasive Lines
                        if (d.topInvasiveLines.isNotEmpty) ...[
                          _buildSectionTitle('Top Invasive Lines'),
                          const SizedBox(height: 12),
                          ...d.topInvasiveLines.take(3).map((inv) => _buildBar(l10n.term(inv.name), inv.count, d.topInvasiveLines.first.count, Colors.pinkAccent)),
                        ],

                        // Top Procedures
                        if (d.topProcedures.isNotEmpty) ...[
                          _buildSectionTitle('Top Procedures'),
                          const SizedBox(height: 12),
                          ...d.topProcedures.take(3).map((proc) => _buildBar(proc.name, proc.count, d.topProcedures.first.count, Colors.lightGreenAccent)),
                        ],

                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Logged with Etherlog',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white38,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSharing ? null : _share,
                icon: _isSharing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.share),
                label: Text(
                  _isSharing ? 'GENERATING...' : 'SHARE MILESTONE POSTER',
                  style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.white54,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildBar(String name, int count, int maxCount, Color color) {
    final frac = maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
