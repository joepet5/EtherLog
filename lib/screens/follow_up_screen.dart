import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/case_storage.dart';
import '../services/follow_up_service.dart';
import '../utils/app_haptics.dart';
import '../widgets/animated_gradient_background.dart';

class FollowUpScreen extends StatefulWidget {
  final CaseRecord caseRecord;

  const FollowUpScreen({super.key, required this.caseRecord});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  late double _restPain;
  late double _movementPain;
  String _ponv = 'None';
  final Set<String> _blockTags = {};
  final Set<String> _complications = {};
  final _notesController = TextEditingController();
  bool _saving = false;

  static const _ponvOptions = ['None', 'Nausea only', 'Vomiting'];
  static const _blockOptions = [
    'Motor block resolved',
    'Sensory block dense',
    'Failed block',
  ];
  static const _day1Complications = [
    'PDPH',
    'Urinary retention',
    'Hoarseness',
    'Sore throat',
    'Nerve injury suspected',
    'None of the above',
  ];

  bool get _hadRegional {
    final names = widget.caseRecord.regionalBlockNames;
    if (names.isEmpty) return false;
    if (names.length == 1 && names.first == 'None / Not performed') {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final c = widget.caseRecord;
    _restPain = (c.restPainScore ?? 0).toDouble();
    _movementPain = (c.movementPainScore ?? 0).toDouble();
    _ponv = c.ponv ?? 'None';
    _blockTags.addAll(c.blockAssessmentTags);
    _complications.addAll(c.followUpComplications);
    _notesController.text = c.followUpNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await AppHaptics.medium();

    final updated = widget.caseRecord.copyWith(
      restPainScore: _restPain.round(),
      movementPainScore: _movementPain.round(),
      ponv: _ponv,
      blockAssessmentTags: _blockTags.toList(),
      followUpComplications: _complications.toList(),
      followUpNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      followUpStatus: 'completed',
      followUpCompletedAt: DateTime.now(),
    );

    await CaseStorage.saveCase(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Follow-up saved'),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.pop(context, true);
  }

  Future<void> _dismiss() async {
    await FollowUpService.dismiss(widget.caseRecord);
    await AppHaptics.selection();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseRecord;
    final title = c.procedure.isNotEmpty ? c.procedure : c.diagnosis;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Post-op follow-up'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _dismiss,
            child: Text(
              'Skip',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.date.day}/${c.date.month}/${c.date.year} · ${c.asaGrade} · ${c.priority}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (c.specialty.isNotEmpty)
                  Text(
                    c.specialty,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _label('Pain at rest (0–10)'),
          _painSlider(
            value: _restPain,
            onChanged: (v) => setState(() => _restPain = v),
          ),
          const SizedBox(height: 12),
          _label('Pain on movement (0–10)'),
          _painSlider(
            value: _movementPain,
            onChanged: (v) => setState(() => _movementPain = v),
          ),
          const SizedBox(height: 20),
          _label('PONV'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ponvOptions.map((o) {
              final selected = _ponv == o;
              return ChoiceChip(
                label: Text(o),
                selected: selected,
                selectedColor: AppTheme.primary.withOpacity(0.25),
                labelStyle: TextStyle(
                  color: selected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                onSelected: (_) => setState(() => _ponv = o),
              );
            }).toList(),
          ),
          if (_hadRegional) ...[
            const SizedBox(height: 20),
            _label('Block assessment'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _blockOptions.map((o) {
                final selected = _blockTags.contains(o);
                return FilterChip(
                  label: Text(o),
                  selected: selected,
                  selectedColor: AppTheme.primary.withOpacity(0.25),
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.primary : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _blockTags.add(o);
                      } else {
                        _blockTags.remove(o);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          _label('Day-1 issues'),
          const SizedBox(height: 8),
          ..._day1Complications.map((o) {
            final selected = _complications.contains(o);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                o,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
              value: selected,
              activeColor: AppTheme.primary,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    if (o == 'None of the above') {
                      _complications
                        ..clear()
                        ..add(o);
                    } else {
                      _complications.remove('None of the above');
                      _complications.add(o);
                    }
                  } else {
                    _complications.remove(o);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 12),
          _label('Notes (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Brief ward note…',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Save follow-up'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.primary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _painSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            label: value.round().toString(),
            activeColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${value.round()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
