import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pac_record.dart';
import '../services/pac_storage.dart';
import '../theme/app_theme.dart';
import '../utils/app_haptics.dart';

class PacScreen extends StatefulWidget {
  final DateTime? initialDate;

  const PacScreen({super.key, this.initialDate});

  @override
  State<PacScreen> createState() => _PacScreenState();
}

class _PacScreenState extends State<PacScreen> {
  late DateTime _selectedDate;
  final _countController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String? _editingId;
  List<PacRecord> _history = [];
  bool _isLoading = true;
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final history = await PacStorage.getAllPacRecords();

    // Check if there is an existing record for the selected date
    final existing = history.firstWhere(
      (r) =>
          r.date.year == _selectedDate.year &&
          r.date.month == _selectedDate.month &&
          r.date.day == _selectedDate.day,
      orElse: () => PacRecord(date: _selectedDate, patientCount: 0),
    );

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
        if (existing.patientCount > 0) {
          _editingId = existing.id;
          _countController.text = existing.patientCount.toString();
          final hasNotes = existing.notes != null && existing.notes!.trim().isNotEmpty;
          _notesController.text = existing.notes ?? '';
          _showNotes = hasNotes;
        } else {
          _showNotes = false;
        }
      });
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      // Check if existing record exists for new date
      final existing = _history.firstWhere(
        (r) =>
            r.date.year == newDate.year &&
            r.date.month == newDate.month &&
            r.date.day == newDate.day,
        orElse: () => PacRecord(date: newDate, patientCount: 0),
      );
      if (existing.patientCount > 0) {
        _editingId = existing.id;
        _countController.text = existing.patientCount.toString();
        final hasNotes = existing.notes != null && existing.notes!.trim().isNotEmpty;
        _notesController.text = existing.notes ?? '';
        _showNotes = hasNotes;
      } else {
        _editingId = null;
        _countController.text = '1';
        _notesController.clear();
        _showNotes = false;
      }
    });
  }

  void _adjustCount(int delta) {
    AppHaptics.selection();
    final current = int.tryParse(_countController.text.trim()) ?? 0;
    final next = (current + delta).clamp(1, 999);
    setState(() {
      _countController.text = next.toString();
    });
  }

  Future<void> _pickDate() async {
    await AppHaptics.light();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _onDateChanged(picked);
    }
  }

  Future<void> _save() async {
    final count = int.tryParse(_countController.text.trim());
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid number of patients'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    await AppHaptics.medium();

    final record = PacRecord(
      id: _editingId,
      date: _selectedDate,
      patientCount: count,
      notes: (_showNotes && _notesController.text.trim().isNotEmpty)
          ? _notesController.text.trim()
          : null,
    );

    await PacStorage.savePacRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingId != null
                ? 'Updated PAC entry for ${_fmtDate(_selectedDate)}'
                : 'Saved PAC entry: $count patients on ${_fmtDate(_selectedDate)}',
          ),
          backgroundColor: const Color(0xFF0D9488),
        ),
      );
      await _loadData();
    }
  }

  Future<void> _confirmDelete(PacRecord record) async {
    await AppHaptics.selection();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete PAC Entry'),
        content: Text(
          'Delete the PAC entry for ${_fmtDate(record.date)} (${record.patientCount} patients)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppHaptics.heavy();
      await PacStorage.deletePacRecord(record.id);
      if (_editingId == record.id) {
        setState(() {
          _editingId = null;
          _countController.text = '1';
          _notesController.clear();
          _showNotes = false;
        });
      }
      await _loadData();
    }
  }

  void _editRecord(PacRecord record) {
    AppHaptics.light();
    _onDateChanged(record.date);
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final totalPatients =
        _history.fold<int>(0, (sum, r) => sum + r.patientCount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/pac_icon.png',
              width: 24,
              height: 24,
              color: AppTheme.textPrimary,
            ),
            const SizedBox(width: 8),
            const Text(
              'PAC Clinic',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEntryCard(),
                const SizedBox(height: 20),
                _buildHistoryHeader(totalPatients),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'No PAC entries logged yet.\nUse the form above to record patients seen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  )
                else
                  ..._history.map(_buildHistoryTile),
              ],
            ),
    );
  }

  Widget _buildEntryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0D9488).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/icon/pac_icon.png',
                  width: 22,
                  height: 22,
                  color: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingId != null ? 'Edit PAC Entry' : 'Log PAC Clinic',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Pre-Anaesthetic Checkup Patients',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_editingId != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _editingId = null;
                      _selectedDate = DateTime.now();
                      _countController.text = '1';
                      _notesController.clear();
                    });
                  },
                  child: const Text('New Entry',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Date Selector
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18, color: const Color(0xFF0D9488)),
                  const SizedBox(width: 10),
                  Text(
                    'Date: ',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Text(
                    _fmtDate(_selectedDate),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Number of Patients Stepper & Input
          Text(
            'Number of Patients Seen',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stepperBtn('-5', () => _adjustCount(-5)),
              const SizedBox(width: 6),
              _stepperBtn('-1', () => _adjustCount(-1)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.5),
                    ),
                  ),
                  child: TextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _stepperBtn('+1', () => _adjustCount(1)),
              const SizedBox(width: 6),
              _stepperBtn('+5', () => _adjustCount(5)),
            ],
          ),
          const SizedBox(height: 12),
          // Option designated by + to add a note
          if (!_showNotes)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  AppHaptics.light();
                  setState(() => _showNotes = true);
                },
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF0D9488)),
                label: const Text(
                  'Add Note',
                  style: TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            )
          else ...[
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Note',
                hintText: 'e.g. High-risk clearances, pre-op assessments',
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Cancel Note',
                  onPressed: () {
                    setState(() {
                      _notesController.clear();
                      _showNotes = false;
                    });
                  },
                ),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.surfaceLight),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(
                _editingId != null ? Icons.check_rounded : Icons.save_rounded,
                size: 20,
              ),
              label: Text(
                _editingId != null ? 'Update PAC Entry' : 'Save PAC Entry',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 44,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: const Color(0xFF0D9488).withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF0D9488),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(int totalPatients) {
    return Row(
      children: [
        Text(
          'PAC History (${_history.length} days)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalPatients Total Patients',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D9488),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTile(PacRecord record) {
    final isEditing = record.id == _editingId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isEditing
            ? const Color(0xFF0D9488).withValues(alpha: 0.1)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? const Color(0xFF0D9488)
              : AppTheme.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${record.patientCount}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtDate(record.date),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${record.patientCount} ${record.patientCount == 1 ? "patient" : "patients"} seen in PAC',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (record.notes != null && record.notes!.isNotEmpty)
                  Text(
                    record.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit',
            color: AppTheme.textSecondary,
            onPressed: () => _editRecord(record),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Delete',
            color: AppTheme.danger.withValues(alpha: 0.8),
            onPressed: () => _confirmDelete(record),
          ),
        ],
      ),
    );
  }
}
