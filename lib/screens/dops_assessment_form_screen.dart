import 'package:flutter/material.dart';
import '../models/dops_assessment.dart';
import '../services/profile_storage.dart';
import '../theme/app_theme.dart';
import 'dops_return_qr_screen.dart';
import '../utils/page_transitions.dart';

class DopsAssessmentFormScreen extends StatefulWidget {
  final Map<String, dynamic> requestPayload;

  const DopsAssessmentFormScreen({super.key, required this.requestPayload});

  @override
  State<DopsAssessmentFormScreen> createState() => _DopsAssessmentFormScreenState();
}

class _DopsAssessmentFormScreenState extends State<DopsAssessmentFormScreen> {
  int _preOpScore = 0;
  int _technicalScore = 0;
  int _postOpScore = 0;
  int _communicationScore = 0;
  
  final _strengthsController = TextEditingController();
  final _improvementsController = TextEditingController();
  String _overall = '';

  final List<String> _overallOptions = [
    'Requires considerable assistance',
    'Requires some assistance',
    'Competent',
    'Excellent',
  ];

  @override
  void dispose() {
    _strengthsController.dispose();
    _improvementsController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_preOpScore == 0 || _technicalScore == 0 || _postOpScore == 0 || _communicationScore == 0 || _overall.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please complete all scores and overall competence.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    final profile = await ProfileStorage.getProfile();
    final assessorName = profile.name.trim().isNotEmpty ? 'Dr. ${profile.name}' : 'Consultant';
    
    final assessment = DopsAssessment(
      caseId: widget.requestPayload['caseId'].toString(),
      traineeName: widget.requestPayload['traineeName']?.toString() ?? 'Trainee',
      traineeGrade: widget.requestPayload['traineeGrade']?.toString() ?? '',
      procedure: widget.requestPayload['procedure']?.toString() ?? 'Procedure',
      assessorName: assessorName,
      assessorPosition: profile.designation,
      scores: {
        'Pre-op prep': _preOpScore,
        'Technical ability': _technicalScore,
        'Post-op management': _postOpScore,
        'Communication': _communicationScore,
      },
      strengths: _strengthsController.text.trim(),
      areasForImprovement: _improvementsController.text.trim(),
      overallCompetence: _overall,
    );

    if (mounted) {
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            page: DopsReturnQrScreen(assessment: assessment),
            style: TransitionStyle.fade,
          ),
        );
    }
  }

  Widget _buildScoreRow(String label, int currentScore, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final score = index + 1;
            final isSelected = currentScore == score;
            return GestureDetector(
              onTap: () => setState(() => onChanged(score)),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.surfaceLight),
                ),
                alignment: Alignment.center,
                child: Text(
                  score.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Needs Help', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              Text('Excellent', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainee = widget.requestPayload['traineeName']?.toString() ?? 'Trainee';
    final procedure = widget.requestPayload['procedure']?.toString() ?? 'Procedure';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('DOPS Assessment'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
                Text('Assessing: $trainee', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Procedure: $procedure', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('1. Scoring (1-5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 16),
          _buildScoreRow('Pre-procedure prep & knowledge', _preOpScore, (v) => _preOpScore = v),
          _buildScoreRow('Technical ability & asepsis', _technicalScore, (v) => _technicalScore = v),
          _buildScoreRow('Post-procedure management', _postOpScore, (v) => _postOpScore = v),
          _buildScoreRow('Communication & professionalism', _communicationScore, (v) => _communicationScore = v),
          
          const Divider(height: 32),
          Text('2. Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 16),
          TextField(
            controller: _strengthsController,
            decoration: InputDecoration(
              labelText: 'Strengths',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppTheme.surface,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _improvementsController,
            decoration: InputDecoration(
              labelText: 'Areas for Improvement',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppTheme.surface,
            ),
            maxLines: 2,
          ),
          
          const Divider(height: 32),
          Text('3. Overall Competence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _overallOptions.map((opt) {
              final isSelected = _overall == opt;
              return ChoiceChip(
                label: Text(opt),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _overall = opt);
                },
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign & Return Assessment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

