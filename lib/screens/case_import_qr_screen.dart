import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/case_share_service.dart';
import '../services/case_storage.dart';
import '../services/subscription_service.dart';
import '../utils/app_haptics.dart';
import '../widgets/animated_gradient_background.dart';

/// Stage 2: scan (or paste) a shared Etherlog case QR and save as Consultant.
class CaseImportQrScreen extends StatefulWidget {
  const CaseImportQrScreen({super.key});

  @override
  State<CaseImportQrScreen> createState() => _CaseImportQrScreenState();
}

class _CaseImportQrScreenState extends State<CaseImportQrScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _handling = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRaw(String raw) async {
    if (_handling) return;
    setState(() => _handling = true);

    final payload = CaseShareService.decodePayload(raw);
    if (payload == null) {
      await AppHaptics.heavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidCaseQr),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() => _handling = false);
      return;
    }

    final canAdd = await SubscriptionService.canAddCases();
    if (!canAdd) {
      await AppHaptics.heavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.subscriptionRequiredImport),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() => _handling = false);
      return;
    }

    try {
      await _controller.stop();
    } catch (_) {}

    final caseData = Map<String, dynamic>.from(payload['case'] as Map);
    final previewProcedure =
        caseData['procedure']?.toString() ?? caseData['diagnosis']?.toString() ?? 'Shared case';
    final previewSpecialty = caseData['specialty']?.toString() ?? '';
    final previewAsa = caseData['asaGrade']?.toString() ?? '';

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.importSharedCase, style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '$previewProcedure\n$previewSpecialty · $previewAsa\n\n'
              '${l10n.importSharedCaseBody}',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.import),
          ),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => _handling = false);
      try {
        await _controller.start();
      } catch (_) {}
      return;
    }

    try {
      final record = await CaseShareService.toCaseRecord(payload);
      await CaseStorage.saveCase(record);
      await AppHaptics.medium();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.caseImportedConsultant),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      await AppHaptics.heavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() => _handling = false);
      try {
        await _controller.start();
      } catch (_) {}
    }
  }

  Future<void> _pasteImport() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clipboardEmpty)),
      );
      return;
    }
    await _handleRaw(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(l10n.importCaseQr),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            tooltip: 'Paste case data',
            icon: const Icon(Icons.content_paste),
            onPressed: _handling ? null : _pasteImport,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handling) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _handleRaw(raw);
            },
          ),
          // Dim overlay with clear center
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.45),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              children: [
                Text(
                  _handling
                      ? l10n.importing
                      : l10n.alignQrHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (_handling) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
