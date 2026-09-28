import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/dops_assessment.dart';
import '../services/dops_service.dart';
import '../theme/app_theme.dart';

class DopsReturnQrScreen extends StatelessWidget {
  final DopsAssessment assessment;

  const DopsReturnQrScreen({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final payload = DopsService.generateReturnPayload(assessment);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Return Assessment'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Assessment Signed & Completed!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.success),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Show this QR code to the trainee so they can import the assessment into their logbook.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: payload,
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
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
