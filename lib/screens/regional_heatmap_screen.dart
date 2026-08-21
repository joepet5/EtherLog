import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';
import '../theme/app_theme.dart';
import '../services/insights_service.dart';
import '../widgets/animated_gradient_background.dart';

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

  final Map<AnatomicalZone, List<NamedCount>> _zoneCounts = {};
  int _maxZoneCount = 1;

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

    for (final zone in AnatomicalZone.values) {
      _zoneCounts[zone]!.sort((a, b) => b.count.compareTo(a.count));
      final totalInZone = _zoneCounts[zone]!.fold(0, (sum, b) => sum + b.count);
      if (totalInZone > _maxZoneCount) {
        _maxZoneCount = totalInZone;
      }
    }
  }

  int _getTotal(AnatomicalZone zone) {
    return _zoneCounts[zone]!.fold(0, (sum, b) => sum + b.count);
  }

  void _showZoneDetails(AnatomicalZone zone) {
    final blocks = _zoneCounts[zone]!;
    final total = _getTotal(zone);

    final String zoneName = _getZoneName(zone);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zoneName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total Blocks: $total', style: TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                      Text('${b.count}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
              const SizedBox(height: 20),
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
      case AnatomicalZone.neuraxial: return 'Neuraxial/Spine/Back';
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

  @override
  Widget build(BuildContext context) {
    final Map<MuscleInfo, Color> colorMapping = {};
    for (final info in MuscleCatalog.all) {
      final zone = _mapMuscleToZone(info);
      if (zone != null) {
        final intensity = _maxZoneCount > 0 ? (_getTotal(zone) / _maxZoneCount.toDouble()) : 0.0;
        if (intensity > 0) {
          // Calculate the color based on intensity
          // Use .withAlpha(128) instead of withOpacity(0.5) to avoid deprecated lints
          final c = Color.lerp(AppTheme.primary.withAlpha(128), const Color(0xFF00E5FF), intensity)!;
          colorMapping[info] = c;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Regional Heatmap'),
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
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _showBack ? 'Posterior View' : 'Anterior View',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, letterSpacing: 1.2),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 500,
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Tap any highlighted region to view specific blocks.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
