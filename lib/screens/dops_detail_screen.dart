import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/case_record.dart';
import '../theme/app_theme.dart';

class DopsDetailScreen extends StatelessWidget {
  final CaseRecord caseRecord;
  final Map<String, dynamic> dops;

  const DopsDetailScreen({
    super.key,
    required this.caseRecord,
    required this.dops,
  });

  @override
  Widget build(BuildContext context) {
    final assessor = dops['assessorName'] ?? 'Assessor';
    final competence = dops['overallCompetence']?.toString() ?? 'Not Rated';
    final procedure = dops['procedure'] ?? caseRecord.procedure;
    final strengths = dops['strengths'] ?? 'None provided.';
    final improvements = dops['areasForImprovement'] ?? 'None provided.';
    final scores = dops['scores'] as Map<String, dynamic>? ?? {};
    
    double avgScore = 0.0;
    if (scores.isNotEmpty) {
      double total = 0.0;
      for (var val in scores.values) {
        total += (val as num).toDouble();
      }
      avgScore = total / scores.length;
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow AnimatedGradientBackground to show
      appBar: AppBar(
        title: const Text('DOPS Assessment'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(procedure, assessor, competence, avgScore),
            const SizedBox(height: 20),
            if (scores.isNotEmpty) ...[
              Text(
                'Individual Scores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...scores.entries.map((e) => _buildScoreRow(e.key, e.value.toString())),
              const SizedBox(height: 24),
            ],
            Text(
              'Feedback',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeedbackSection('Strengths', strengths, Icons.thumb_up_alt_outlined),
            const SizedBox(height: 16),
            _buildFeedbackSection('Areas for Improvement', improvements, Icons.trending_up),
            const SizedBox(height: 32),
            _buildSignatureBlock(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String procedure, String assessor, String competence, double avgScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.8), // Glassmorphism style
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            procedure,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assessed by $assessor',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Average Score: ${avgScore.toStringAsFixed(1)}/5',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Competence: $competence',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String category, String score) {
    String formattedCategory = category.replaceAllMapped(
        RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}');
    formattedCategory = formattedCategory.substring(0, 1).toUpperCase() +
        formattedCategory.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              formattedCategory,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$score/5',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBlock() {
    final timestamp = dops['signatureTimestamp'] != null 
        ? DateTime.tryParse(dops['signatureTimestamp'])
        : caseRecord.date;
    final timeStr = timestamp != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp)
        : DateFormat('dd MMM yyyy').format(caseRecord.date);
    final device = dops['signatureDevice'];

    String infoStr = timeStr;
    if (device != null && device.toString().isNotEmpty) {
      infoStr += '\nDevice: $device';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Icon(Icons.verified, color: Colors.green.shade600, size: 32),
        const SizedBox(height: 8),
        Text(
          'Cryptographically Signed',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          infoStr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

