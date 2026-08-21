import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/complication_localizations.dart';
import '../widgets/animated_gradient_background.dart';

class ComplicationDetailScreen extends StatelessWidget {
  final String complicationName;

  const ComplicationDetailScreen({super.key, required this.complicationName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final info = ComplicationLocalizations.getLocalizedInfo(
      complicationName,
      l10n.locale.languageCode,
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surface = cs.surface;
    final border = cs.outlineVariant.withOpacity(0.5);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.term(info.title)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.clinicalOverview,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  info.overview,
                  style: TextStyle(fontSize: 14, height: 1.4, color: cs.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Immediate Actions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.immediateManagementSteps,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ...info.immediateActions.map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    action,
                    style: TextStyle(fontSize: 13, height: 1.4, color: cs.onSurface),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Differential Diagnosis Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rule_folder_outlined, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.differentialDiagnosis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ...info.differentialDiagnosis.map((diff) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          diff,
                          style: TextStyle(fontSize: 13, color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // References Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, color: Colors.purpleAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.referencesAndGuidelines,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ...info.references.map((ref) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '📚 $ref',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withOpacity(0.75),
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
