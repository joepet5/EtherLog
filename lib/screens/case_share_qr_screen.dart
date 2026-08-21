import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/case_share_service.dart';
import '../utils/app_haptics.dart';
import '../widgets/animated_gradient_background.dart';

/// Stage 1: show a temporary QR so another Etherlog user can import this case later (Stage 2).
class CaseShareQrScreen extends StatefulWidget {
  final CaseRecord caseRecord;

  const CaseShareQrScreen({super.key, required this.caseRecord});

  @override
  State<CaseShareQrScreen> createState() => _CaseShareQrScreenState();
}

class _CaseShareQrScreenState extends State<CaseShareQrScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  bool _stripHospitalNumbers = true;
  late String _payload;
  bool _tooLarge = false;

  @override
  void initState() {
    super.initState();
    _rebuildPayload();
  }

  void _rebuildPayload() {
    final encoded = CaseShareService.encodePayload(
      widget.caseRecord,
      stripHospitalNumbers: _stripHospitalNumbers,
    );
    setState(() {
      _payload = encoded;
      _tooLarge = CaseShareService.isPayloadTooLarge(encoded);
    });
  }

  Future<void> _copyPayload() async {
    await Clipboard.setData(ClipboardData(text: _payload));
    await AppHaptics.light();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.caseDataCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseRecord;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.shareCase),
        actions: [
          IconButton(
            tooltip: 'Copy data',
            onPressed: _copyPayload,
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.shareCase,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.procedure.isNotEmpty ? c.procedure : c.diagnosis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.specialty} · ${c.asaGrade} · ${c.priority}',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.hideHospitalNumber,
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.hideHospitalNumberHint,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            value: _stripHospitalNumbers,
            activeColor: AppTheme.primary,
            onChanged: (v) {
              setState(() => _stripHospitalNumbers = v);
              _rebuildPayload();
            },
          ),
          const SizedBox(height: 12),
          if (_tooLarge)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
              ),
              child: Text(
                l10n.qrPayloadLarge,
                style: TextStyle(color: AppTheme.danger, fontSize: 13, height: 1.35),
              ),
            ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _payload,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F172A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.shareCaseFooter,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _copyPayload,
            icon: const Icon(Icons.copy),
            label: Text(l10n.copyCaseData),
          ),
        ],
      ),
    );
  }
}
