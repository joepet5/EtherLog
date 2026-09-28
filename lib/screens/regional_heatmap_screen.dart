import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';
import '../theme/app_theme.dart';
import '../services/insights_service.dart';

enum AnatomicalZone { headNeck, chest, abdomen, upperLimbs, lowerLimbs, neuraxial }

class RegionalHeatmapScreen extends StatefulWidget {
  final InsightsData data;

  const RegionalHeatmapScreen({super.key, required this.data});

  @override
  State<RegionalHeatmapScreen> createState() => _RegionalHeatmapScreenState();
}

class _RegionalHeatmapScreenState extends State<RegionalHeatmapScreen> {
  bool _showBack = false;

  final Map<AnatomicalZone, List<String>> _zoneKeywords = {
    AnatomicalZone.headNeck: ['cervical', 'occipital', 'scalp', 'trigeminal', 'sphenopalatine', 'facial', 'eye'],
    AnatomicalZone.chest: ['pecs', 'serratus', 'intercostal', 'brimp', 'pectointercostal'],
    AnatomicalZone.abdomen: ['tap', 'rectus sheath', 'quadratus lumborum', 'ql', 'ilioinguinal', 'iliohypogastric', 'transversalis', 'erector spinae (lumbar)'],
    AnatomicalZone.upperLimbs: ['interscalene', 'supraclavicular', 'infraclavicular', 'axillary', 'median', 'ulnar', 'radial', 'bier', 'forearm', 'suprascapular', 'musculocutaneous'],
    AnatomicalZone.lowerLimbs: ['fascia iliaca', 'femoral', 'sciatic', 'popliteal', 'saphenous', 'adductor', 'ankle', 'lumbar plexus', 'sacral plexus', 'obturator', 'ipack'],
    AnatomicalZone.neuraxial: ['spinal', 'epidural', 'cse', 'caudal', 'paravertebral', 'esp', 'erector spinae'],
  };

  static const List<Color> _heatmapColors = [
    Color(0xFFFFFFFF), // White (fewer blocks)
    Color(0xFF38BDF8), // Cyan / Sky Blue
    Color(0xFF34D399), // Emerald Mint Green
    Color(0xFFFBBF24), // Amber Gold
    Color(0xFFF97316), // Coral Orange
    Color(0xFFA855F7), // Vivid Orchid Purple
    Color(0xFF4C1D95), // Deep Dark Purple (most blocks)
  ];

  final Map<AnatomicalZone, List<NamedCount>> _zoneCounts = {};
  int _maxZoneCount = 1;
  int _minZoneCount = 1;

  @override
  void initState() {
    super.initState();
    _computeHeatmap();
  }

  void _computeHeatmap() {
    for (final zone in AnatomicalZone.values) {
      _zoneCounts[zone] = [];
    }

    for (final block in widget.data.allBlocks) {
      final lowerName = block.name.toLowerCase();
      AnatomicalZone? matchedZone;

      for (final entry in _zoneKeywords.entries) {
        if (entry.value.any((kw) => lowerName.contains(kw))) {
          matchedZone = entry.key;
          break;
        }
      }

      if (matchedZone == null) {
        if (lowerName.contains('pudendal')) {
          matchedZone = AnatomicalZone.neuraxial;
        }
      }

      if (matchedZone != null) {
        _zoneCounts[matchedZone]!.add(block);
      }
    }

    int minVal = 999999;
    int maxVal = 0;
    for (final zone in AnatomicalZone.values) {
      _zoneCounts[zone]!.sort((a, b) => b.count.compareTo(a.count));
      final totalInZone = _zoneCounts[zone]!.fold(0, (sum, b) => sum + b.count);
      if (totalInZone > 0) {
        if (totalInZone < minVal) minVal = totalInZone;
        if (totalInZone > maxVal) maxVal = totalInZone;
      }
    }
    _minZoneCount = minVal == 999999 ? 1 : minVal;
    _maxZoneCount = maxVal == 0 ? 1 : maxVal;
  }

  int _getTotal(AnatomicalZone zone) {
    return _zoneCounts[zone]!.fold(0, (sum, b) => sum + b.count);
  }

  Color _getColorForCount(int count) {
    if (count <= 0) return Colors.transparent;
    if (_maxZoneCount == _minZoneCount) {
      return const Color(0xFFA855F7);
    }
    final t = ((count - _minZoneCount) / (_maxZoneCount - _minZoneCount)).clamp(0.0, 1.0);
    final scaled = t * (_heatmapColors.length - 1);
    final index = scaled.floor();
    final remainder = scaled - index;
    if (index >= _heatmapColors.length - 1) {
      return _heatmapColors.last;
    }
    return Color.lerp(_heatmapColors[index], _heatmapColors[index + 1], remainder)!;
  }

  void _showZoneDetails(AnatomicalZone zone) {
    final blocks = _zoneCounts[zone]!;
    final total = _getTotal(zone);
    final String zoneName = _getZoneName(zone);
    final zoneColor = _getColorForCount(total);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceSolid,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: zoneColor == Colors.transparent ? Colors.white24 : zoneColor,
                      border: Border.all(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(zoneName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total Blocks: $total',
                style: TextStyle(
                  color: zoneColor == Colors.transparent
                      ? AppTheme.textSecondary
                      : (zoneColor == Colors.white ? const Color(0xFFE2E8F0) : zoneColor),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              if (blocks.isEmpty)
                Text('No blocks logged in this region.', style: TextStyle(color: AppTheme.textSecondary))
              else
                ...blocks.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (zoneColor == Colors.transparent ? const Color(0xFFA855F7) : zoneColor).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (zoneColor == Colors.transparent ? const Color(0xFFA855F7) : zoneColor).withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${b.count}',
                          style: TextStyle(
                            color: zoneColor == Colors.transparent
                                ? const Color(0xFFA855F7)
                                : (zoneColor == Colors.white ? const Color(0xFFE2E8F0) : zoneColor),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _getZoneName(AnatomicalZone zone) {
    switch (zone) {
      case AnatomicalZone.headNeck: return 'Head & Neck';
      case AnatomicalZone.chest: return 'Chest / Torso';
      case AnatomicalZone.abdomen: return 'Abdomen';
      case AnatomicalZone.upperLimbs: return 'Upper Limbs';
      case AnatomicalZone.lowerLimbs: return 'Lower Limbs';
      case AnatomicalZone.neuraxial: return 'Neuraxial / Spine / Back';
    }
  }

  AnatomicalZone? _mapMuscleToZone(MuscleInfo muscleInfo) {
    switch (muscleInfo.group) {
      case MuscleGroup.neck:
        return AnatomicalZone.headNeck;
      case MuscleGroup.chest:
        return AnatomicalZone.chest;
      case MuscleGroup.core:
        return AnatomicalZone.abdomen;
      case MuscleGroup.shoulders:
      case MuscleGroup.arms:
        return AnatomicalZone.upperLimbs;
      case MuscleGroup.legs:
      case MuscleGroup.glutes:
      case MuscleGroup.hamstrings:
      case MuscleGroup.adductors:
        return AnatomicalZone.lowerLimbs;
      case MuscleGroup.back:
        return AnatomicalZone.neuraxial;
    }
  }

  void _showAttributionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSolid,
        title: const Text(
          'Anatomical Atlas Attribution',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The anatomical body illustrations used in this regional heatmap are based on open-source vector works by Ryan Graves.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '• Creator: Ryan Graves\n• Source: Figma Community\n• License: Creative Commons Attribution 4.0 International (CC BY 4.0)\n• Packaged via: flutter_body_atlas (BSD 3-Clause)',
              style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFFA855F7))),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    final totalBlocks = widget.data.allBlocks.fold<int>(0, (sum, b) => sum + b.count);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSolid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, size: 16, color: const Color(0xFFA855F7)),
                  const SizedBox(width: 6),
                  const Text(
                    'BLOCK INTENSITY KEY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Text(
                '$totalBlocks Total Blocks',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA855F7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Gradient Bar: White -> Multi-colour -> Deep Dark Purple
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: _heatmapColors,
              ),
              border: Border.all(color: Colors.white24, width: 1),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white70, width: 0.8),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Fewer ($_minZoneCount)',
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Text(
                'Moderate',
                style: TextStyle(fontSize: 11, color: Colors.white38),
              ),
              Row(
                children: [
                  Text(
                    'Most ($_maxZoneCount)',
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4C1D95),
                      border: Border.all(color: Colors.white38, width: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<MuscleInfo, Color> colorMapping = {};
    for (final info in MuscleCatalog.all) {
      final zone = _mapMuscleToZone(info);
      if (zone != null) {
        final count = _getTotal(zone);
        if (count > 0) {
          colorMapping[info] = _getColorForCount(count);
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Regional Heatmap'),
        actions: [
          IconButton(
            icon: Icon(_showBack ? Icons.flip_to_front : Icons.flip_to_back),
            tooltip: 'Flip Body',
            onPressed: () {
              setState(() {
                _showBack = !_showBack;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Anterior / Posterior Segmented Toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Anterior (Front)'),
                  selected: !_showBack,
                  onSelected: (val) {
                    if (val) setState(() => _showBack = false);
                  },
                  selectedColor: const Color(0xFFA855F7),
                  backgroundColor: AppTheme.surfaceSolid,
                  labelStyle: TextStyle(
                    color: !_showBack ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Posterior (Back)'),
                  selected: _showBack,
                  onSelected: (val) {
                    if (val) setState(() => _showBack = true);
                  },
                  selectedColor: const Color(0xFFA855F7),
                  backgroundColor: AppTheme.surfaceSolid,
                  labelStyle: TextStyle(
                    color: _showBack ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 480,
                child: BodyAtlasView<MuscleInfo>(
                  view: _showBack ? AtlasAsset.musclesBack : AtlasAsset.musclesFront,
                  resolver: const MuscleResolver(),
                  colorMapping: colorMapping,
                  onTapElement: (muscleInfo) {
                    final zone = _mapMuscleToZone(muscleInfo);
                    if (zone != null) {
                      _showZoneDetails(zone);
                    }
                  },
                ),
              ),
            ),
          ),
          // Heatmap Key / Legend
          _buildHeatmapLegend(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tap any highlighted region to inspect specific blocks.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _showAttributionDialog,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 11, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'Atlas illustration by Ryan Graves (CC BY 4.0)',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.65),
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.textSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
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
