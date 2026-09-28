import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/case_record.dart';
import '../models/dops_assessment.dart';
import '../services/dops_service.dart';
import '../services/case_storage.dart';
import '../theme/app_theme.dart';
import '../utils/app_haptics.dart';

class DopsReceiveScannerScreen extends StatefulWidget {
  final CaseRecord caseRecord;

  const DopsReceiveScannerScreen({super.key, required this.caseRecord});

  @override
  State<DopsReceiveScannerScreen> createState() => _DopsReceiveScannerScreenState();
}

class _DopsReceiveScannerScreenState extends State<DopsReceiveScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _processing = true);
    AppHaptics.medium();

    final decoded = DopsService.decodePayload(code);
    if (decoded == null || decoded['type'] != DopsService.resType) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid DOPS assessment QR code.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
      return;
    }

    final assessmentData = decoded['assessment'] as Map<String, dynamic>;
    if (!DopsService.verifySignature(assessmentData)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Signature verification failed! Data may be corrupted or tampered.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
      return;
    }

    final assessment = DopsAssessment.fromJson(assessmentData);
    
    // Save to the CaseRecord
    final updatedCase = widget.caseRecord.copyWith(
      dopsAssessment: assessment.toJson(),
      verified: true,
      verifiedBy: assessment.assessorName,
      verifiedAt: assessment.date,
    );

    await CaseStorage.saveCase(updatedCase);
    AppHaptics.heavy();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('DOPS successfully imported and case verified!'),
          backgroundColor: AppTheme.success,
        ),
      );
      // Pop back twice to return to Case Detail
      Navigator.pop(context); // close scanner
      Navigator.pop(context); // close request screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Return Code'),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Text(
              'Position the Consultant\'s QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4)],
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
