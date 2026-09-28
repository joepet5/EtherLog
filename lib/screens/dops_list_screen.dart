import 'package:flutter/material.dart';
import '../models/case_record.dart';
import '../services/case_storage.dart';
import '../theme/app_theme.dart';
import '../utils/app_haptics.dart';
import 'case_detail_screen.dart';
import '../utils/page_transitions.dart';

class DopsListScreen extends StatefulWidget {
  const DopsListScreen({super.key});

  @override
  State<DopsListScreen> createState() => _DopsListScreenState();
}

class _DopsListScreenState extends State<DopsListScreen> {
  List<CaseRecord> _dopsCases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDopsCases();
  }

  Future<void> _loadDopsCases() async {
    final all = await CaseStorage.getAllCases();
    final dops = all.where((c) => c.dopsAssessment != null).toList();
    dops.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _dopsCases = dops;
      _loading = false;
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My DOPS Assessments'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dopsCases.isEmpty
              ? Center(
                  child: Text(
                    'No DOPS assessments found.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dopsCases.length,
                  itemBuilder: (context, index) {
                    final c = _dopsCases[index];
                    final dops = c.dopsAssessment!;
                    final procedure = dops['procedure']?.toString() ?? (c.procedure.isNotEmpty ? c.procedure : (c.diagnosis.isNotEmpty ? c.diagnosis : 'Procedure'));
                    final assessor = dops['assessorName'] ?? 'Assessor';
                    final competence = dops['overallCompetence']?.toString() ?? '';
                    
                    double avgScore = 0.0;
                    final scores = dops['scores'] as Map<String, dynamic>? ?? {};
                    if (scores.isNotEmpty) {
                      double total = 0.0;
                      for (var val in scores.values) {
                        total += (val as num).toDouble();
                      }
                      avgScore = total / scores.length;
                    }

                    return Card(
                      color: AppTheme.surface.withValues(alpha: 0.72),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          AppHaptics.light();
                            Navigator.push(
                              context,
                              AppPageRoute(
                                page: CaseDetailScreen(caseRecord: c),
                                style: TransitionStyle.fade,
                              ),
                            ).then((_) => _loadDopsCases());
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          procedure,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${_fmtDate(c.date)} - $assessor\n$competence',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${avgScore.toStringAsFixed(1)}/5',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}









