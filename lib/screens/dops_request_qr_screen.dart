import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/case_record.dart';
import '../services/dops_service.dart';
import '../theme/app_theme.dart';
import 'dops_receive_scanner_screen.dart';
import '../utils/page_transitions.dart';

class DopsRequestQrScreen extends StatefulWidget {
  final CaseRecord caseRecord;
  final String? requestedProcedure;

  const DopsRequestQrScreen({
    super.key,
    required this.caseRecord,
    this.requestedProcedure,
  });

  @override
  State<DopsRequestQrScreen> createState() => _DopsRequestQrScreenState();
}

class _DopsRequestQrScreenState extends State<DopsRequestQrScreen> {
  String? _payload;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildPayload();
  }

  Future<void> _buildPayload() async {
    final procedureName = widget.requestedProcedure ??
        (widget.caseRecord.procedure.isNotEmpty
            ? widget.caseRecord.procedure
            : widget.caseRecord.diagnosis);
            
    final payload = await DopsService.generateRequestPayload(
      widget.caseRecord.id,
      procedureName,
    );
    if (mounted) {
      setState(() {
        _payload = payload;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final procedureName = widget.requestedProcedure ??
        (widget.caseRecord.procedure.isNotEmpty
            ? widget.caseRecord.procedure
            : widget.caseRecord.diagnosis);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Request DOPS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Procedure', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  procedureName,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Step 1: Ask your Consultant to scan this code from their EtherLog app (Dashboard -> Scanner).',
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.4),
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
                data: _payload!,
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
          Text(
            'Step 2: Once they finish grading you on their phone, they will show you a return code. Tap below to scan it.',
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
                Navigator.push(
                  context,
                  AppPageRoute(
                    page: DopsReceiveScannerScreen(caseRecord: widget.caseRecord),
                    style: TransitionStyle.fade,
                  ),
                );
            },
            icon: const Icon(Icons.document_scanner),
            label: const Text('Scan Return Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

