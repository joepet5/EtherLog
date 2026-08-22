import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';
import '../services/case_storage.dart';
import '../utils/app_haptics.dart';
import '../services/usage_stats.dart';
import 'case_detail_screen.dart';
import '../services/case_mix_query_storage.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_gradient_background.dart';

enum MixField {
  ageYears,
  priority,
  asa,
  specialty,
  technique,
  role,
  airway,
  intubationType,
  intubationMethod,
  regional,
  invasive,
  difficultAirway,
  starred,
  outcome,
  diagnosis,
  procedure,
  notes,
}

enum MixOp { isEqual, contains, under, over, isTrue, isFalse }

class MixCondition {
  MixField field;
  MixOp op;
  String value;

  MixCondition({
    this.field = MixField.priority,
    this.op = MixOp.isEqual,
    this.value = '',
  });
}

class CaseMixScreen extends StatefulWidget {
  const CaseMixScreen({super.key});

  @override
  State<CaseMixScreen> createState() => _CaseMixScreenState();
}

class _CaseMixScreenState extends State<CaseMixScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  List<CaseRecord> _all = [];
  List<CaseRecord> _matches = [];
  List<SavedMixQuery> _saved = [];
  bool _loading = true;
  final List<MixCondition> _conditions = [
    MixCondition(field: MixField.priority, op: MixOp.isEqual, value: 'Emergency'),
  ];

  static const _fieldLabels = <MixField, String>{
    MixField.ageYears: 'Age (years)',
    MixField.priority: 'Priority',
    MixField.asa: 'ASA grade',
    MixField.specialty: 'Specialty',
    MixField.technique: 'Primary technique',
    MixField.role: 'Role',
    MixField.airway: 'Airway management',
    MixField.intubationType: 'Type of intubation',
    MixField.intubationMethod: 'Method of intubation',
    MixField.regional: 'Regional block',
    MixField.invasive: 'Invasive / monitoring',
    MixField.difficultAirway: 'Difficult airway',
    MixField.starred: 'Starred',
    MixField.outcome: 'Outcome',
    MixField.diagnosis: 'Diagnosis',
    MixField.procedure: 'Procedure',
  };

  String _getFieldLabel(MixField f) {
    switch (f) {
      case MixField.ageYears: return l10n.age;
      case MixField.priority: return l10n.priority;
      case MixField.asa: return l10n.asaGrade;
      case MixField.specialty: return l10n.specialty;
      case MixField.technique: return l10n.primaryTechnique;
      case MixField.role: return l10n.yourRole;
      case MixField.airway: return l10n.airwayManagement;
      case MixField.intubationType: return l10n.typeOfIntubation;
      case MixField.intubationMethod: return l10n.methodOfIntubation;
      case MixField.regional: return l10n.regionalBlock;
      case MixField.invasive: return l10n.invasiveLines;
      case MixField.difficultAirway: return l10n.difficultAirway;
      case MixField.starred: return l10n.starred;
      case MixField.outcome: return l10n.outcome;
      case MixField.diagnosis: return l10n.diagnosis;
      case MixField.procedure: return l10n.procedure;
      case MixField.notes: return 'Notes / Lessons';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }


  /// Suggestions from logged cases for the value field (field-specific).
  List<String> _suggestionsFor(MixField field, String query) {
    final q = query.trim().toUpperCase();
    final set = <String>{};
    for (final c in _all) {
      switch (field) {
        case MixField.priority:
          set.add(c.priority.toUpperCase());
          break;
        case MixField.asa:
          set.add(c.asaGrade.toUpperCase());
          break;
        case MixField.specialty:
          set.add(c.specialty.toUpperCase());
          break;
        case MixField.technique:
          set.add(c.technique.toUpperCase());
          break;
        case MixField.role:
          set.add(c.role.toUpperCase());
          break;
        case MixField.airway:
          if (c.airwayManagement != null) set.add(c.airwayManagement!.toUpperCase());
          break;
        case MixField.intubationType:
          if (c.typeOfIntubation != null) set.add(c.typeOfIntubation!.toUpperCase());
          break;
        case MixField.intubationMethod:
          if (c.methodOfIntubation != null) set.add(c.methodOfIntubation!.toUpperCase());
          break;
        case MixField.regional:
          for (final e in c.regionalBlocks) {
            final n = e['name']?.toString();
            if (n != null && n.isNotEmpty) set.add(n.toUpperCase());
          }
          break;
        case MixField.invasive:
          for (final e in c.invasiveMonitoring) {
            final n = e['name']?.toString();
            if (n != null && n.isNotEmpty) set.add(n.toUpperCase());
          }
          break;
        case MixField.outcome:
          if (c.outcome != null) set.add(c.outcome!.toUpperCase());
          break;
        case MixField.diagnosis:
          if (c.diagnosis.isNotEmpty) set.add(c.diagnosis.toUpperCase());
          break;
        case MixField.procedure:
          if (c.procedure.isNotEmpty) set.add(c.procedure.toUpperCase());
          break;
        default:
          break;
      }
    }
    // Always seed common values
    if (field == MixField.priority) {
      set.addAll(['ELECTIVE', 'EMERGENCY']);
    }
    final list = set.where((s) => s.isNotEmpty).toList()..sort();
    if (q.isEmpty) return list.take(12).toList();
    return list.where((s) => s.contains(q)).take(12).toList();
  }

  String _opLabelCaps(MixOp o) => _opLabel(o).toUpperCase();

  Future<void> _load() async {
    final cases = await CaseStorage.getAllCases();
    final saved = await CaseMixQueryStorage.getAll();
    if (!mounted) return;
    setState(() {
      _all = cases;
      _saved = saved;
      _loading = false;
    });
    _run();
  }

  List<MixOp> _opsFor(MixField f) {
    switch (f) {
      case MixField.ageYears:
        return [MixOp.under, MixOp.over, MixOp.isEqual];
      case MixField.difficultAirway:
      case MixField.starred:
        return [MixOp.isTrue, MixOp.isFalse];
      case MixField.priority:
      case MixField.role:
        return [MixOp.isEqual, MixOp.contains];
      case MixField.asa:
      // under/over compare numeric grade 1–5 (ASA I…V)
        return [MixOp.isEqual, MixOp.contains, MixOp.under, MixOp.over];
      default:
        return [MixOp.contains, MixOp.isEqual];
    }
  }

  String _opLabel(MixOp op) {
    switch (op) {
      case MixOp.isEqual:
        return 'is';
      case MixOp.contains:
        return 'contains';
      case MixOp.under:
        return 'under';
      case MixOp.over:
        return 'over';
      case MixOp.isTrue:
        return 'yes';
      case MixOp.isFalse:
        return 'no';
    }
  }

  double? _ageYears(CaseRecord c) {
    if (c.patientAge == null) return null;
    switch (c.ageUnit) {
      case 'months':
        return c.patientAge! / 12.0;
      case 'days':
        return c.patientAge! / 365.0;
      default:
        return c.patientAge;
    }
  }

  String _regionalText(CaseRecord c) {
    return c.regionalBlocks
        .map((e) => '${e['name'] ?? ''} ${e['role'] ?? ''}')
        .join(' | ')
        .toLowerCase();
  }

  String _invasiveText(CaseRecord c) {
    return c.invasiveMonitoring
        .map((e) => '${e['name'] ?? ''} ${e['role'] ?? ''}')
        .join(' | ')
        .toLowerCase();
  }

  /// Lowercase, trim, collapse spaces.
  String _fold(String s) =>
      s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Letters+digits only (for soft equality).
  String _alnum(String s) =>
      _fold(s).replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _textEquals(String stored, String query) {
    final a = _fold(stored);
    final b = _fold(query);
    if (b.isEmpty) return false;
    if (a == b) return true;
    final aa = _alnum(stored);
    final bb = _alnum(query);
    return aa.isNotEmpty && aa == bb;
  }

  bool _textContains(String stored, String query) {
    final a = _fold(stored);
    final b = _fold(query);
    if (b.isEmpty) return false;
    if (a.contains(b)) return true;
    final aa = _alnum(stored);
    final bb = _alnum(query);
    return bb.isNotEmpty && aa.contains(bb);
  }

  /// Accepts "ASA III", "ASA 3", "3", "III", "asa-iii", etc. → 1..5
  int? _parseAsaNumber(String raw) {
    final s = _fold(raw);
    if (s.isEmpty) return null;
    // Longest Roman first so "iii" does not become "i"
    if (s.contains('iii') || RegExp(r'\b3\b').hasMatch(s)) return 3;
    if (s.contains('iv') || RegExp(r'\b4\b').hasMatch(s)) return 4;
    if (RegExp(r'\bii\b').hasMatch(s) ||
        s.contains('asa ii') ||
        RegExp(r'\b2\b').hasMatch(s)) {
      return 2;
    }
    if (RegExp(r'\bv\b').hasMatch(s) ||
        s.contains('asa v') ||
        RegExp(r'\b5\b').hasMatch(s)) {
      return 5;
    }
    if (RegExp(r'\bi\b').hasMatch(s) ||
        s.contains('asa i') ||
        RegExp(r'\b1\b').hasMatch(s)) {
      return 1;
    }
    // Bare roman without spaces: "asaiii"
    final compact = _alnum(s).replaceFirst(RegExp(r'^asa'), '');
    const map = {'i': 1, 'ii': 2, 'iii': 3, 'iv': 4, 'v': 5};
    if (map.containsKey(compact)) return map[compact];
    final d = int.tryParse(compact);
    if (d != null && d >= 1 && d <= 5) return d;
    return null;
  }

  bool _matchText(String stored, MixOp op, String query) {
    if (op == MixOp.contains) return _textContains(stored, query);
    // isEqual (and any other): soft equality
    return _textEquals(stored, query);
  }

  bool _match(CaseRecord c, MixCondition cond) {
    final v = cond.value.trim();
    switch (cond.field) {
      case MixField.ageYears:
        final age = _ageYears(c);
        if (age == null) return false;
        final n = double.tryParse(v);
        if (n == null) return false;
        if (cond.op == MixOp.under) return age < n;
        if (cond.op == MixOp.over) return age > n;
        return (age - n).abs() < 0.01;

      case MixField.asa:
        final storedN = _parseAsaNumber(c.asaGrade);
        final queryN = _parseAsaNumber(v);
        if (storedN == null || queryN == null) {
          // Fallback to text if unparseable
          return _matchText(c.asaGrade, cond.op, v);
        }
        if (cond.op == MixOp.contains || cond.op == MixOp.isEqual) {
          return storedN == queryN;
        }
        if (cond.op == MixOp.under) return storedN < queryN;
        if (cond.op == MixOp.over) return storedN > queryN;
        return storedN == queryN;

      case MixField.priority:
        return _matchText(c.priority, cond.op, v);
      case MixField.specialty:
        final s = '${c.specialty} ${c.specialtyOther ?? ''}'.trim();
        // "is" also allows contains when query is a clear substring of specialty
        // so "Obstetrics" matches "Obstetrics and Gynaecology" soft-fail cases.
        if (cond.op == MixOp.isEqual) {
          if (_textEquals(c.specialty, v)) return true;
          if (c.specialtyOther != null && _textEquals(c.specialtyOther!, v)) {
            return true;
          }
          // Soft is: specialty field equals OR starts with query word(s)
          return _textContains(s, v) &&
              (_fold(c.specialty) == _fold(v) ||
                  _fold(c.specialty).startsWith(_fold(v)) ||
                  _alnum(c.specialty) == _alnum(v));
        }
        return _matchText(s, cond.op, v);
      case MixField.technique:
        return _matchText(c.technique, cond.op, v);
      case MixField.role:
        return _matchText(c.role, cond.op, v);
      case MixField.airway:
        return _matchText(c.airwayManagement ?? '', cond.op, v);
      case MixField.intubationType:
        return _matchText(c.typeOfIntubation ?? '', cond.op, v);
      case MixField.intubationMethod:
        return _matchText(c.methodOfIntubation ?? '', cond.op, v);
      case MixField.regional:
        return _textContains(_regionalText(c), v);
      case MixField.invasive:
        return _textContains(_invasiveText(c), v);
      case MixField.difficultAirway:
        return cond.op == MixOp.isTrue ? c.difficultAirway : !c.difficultAirway;
      case MixField.starred:
        return cond.op == MixOp.isTrue ? c.starred : !c.starred;
      case MixField.outcome:
        return _matchText(c.outcome ?? '', cond.op, v);
      case MixField.diagnosis:
        return _matchText(c.diagnosis, cond.op, v);
      case MixField.procedure:
        return _matchText(c.procedure, cond.op, v);
      case MixField.notes:
        return _matchText(c.notes ?? '', cond.op, v);
    }
  }

  void _run() {
    var list = List<CaseRecord>.from(_all);
    for (final cond in _conditions) {
      if (cond.op != MixOp.isTrue &&
          cond.op != MixOp.isFalse &&
          cond.value.trim().isEmpty) {
        continue;
      }
      list = list.where((c) => _match(c, cond)).toList();
    }
    setState(() => _matches = list);
  }

  void _addCondition() {
    setState(() {
      _conditions.add(MixCondition());
    });
    _run();
  }

  void _removeCondition(int i) {
    setState(() {
      if (_conditions.length > 1) {
        _conditions.removeAt(i);
      }
    });
    _run();
  }

  String _summaryLine() {
    final parts = <String>[];
    for (final c in _conditions) {
      final name = _fieldLabels[c.field] ?? '';
      if (c.op == MixOp.isTrue) {
        parts.add('$name: yes');
      } else if (c.op == MixOp.isFalse) {
        parts.add('$name: no');
      } else if (c.value.trim().isEmpty) {
        continue;
      } else {
        parts.add('$name ${_opLabel(c.op)} ${c.value.trim()}');
      }
    }
    return parts.isEmpty ? 'No active filters' : parts.join('  ·  ');
  }

  Future<void> _copySummary() async {
    final text =
        '${_matches.length} cases match\n${_summaryLine()}\n(Etherlog case mix)';
    await Clipboard.setData(ClipboardData(text: text));
    await AppHaptics.selection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied')),
    );
  }


  String _fieldToKey(MixField f) => f.name;
  String _opToKey(MixOp o) => o.name;

  MixField _fieldFromKey(String s) {
    return MixField.values.firstWhere(
          (e) => e.name == s,
      orElse: () => MixField.priority,
    );
  }

  MixOp _opFromKey(String s) {
    return MixOp.values.firstWhere(
          (e) => e.name == s,
      orElse: () => MixOp.isEqual,
    );
  }

  List<Map<String, String>> _serializeConditions() {
    return _conditions
        .map((c) => {
      'field': _fieldToKey(c.field),
      'op': _opToKey(c.op),
      'value': c.value,
    })
        .toList();
  }

  void _applySaved(SavedMixQuery q) {
    setState(() {
      _conditions
        ..clear()
        ..addAll(
          q.conditions.map(
                (m) => MixCondition(
              field: _fieldFromKey(m['field'] ?? ''),
              op: _opFromKey(m['op'] ?? ''),
              value: m['value'] ?? '',
            ),
          ),
        );
      if (_conditions.isEmpty) {
        _conditions.add(MixCondition());
      }
    });
    _run();
  }

  Future<void> _saveQuery() async {
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Save query', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Paeds emergency airway',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name for this query')),
      );
      return;
    }
    final query = SavedMixQuery(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      conditions: _serializeConditions(),
    );
    await CaseMixQueryStorage.save(query);
    await AppHaptics.medium();
    final saved = await CaseMixQueryStorage.getAll();
    if (!mounted) return;
    setState(() => _saved = saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved “$name”'), backgroundColor: AppTheme.success),
    );
  }

  Future<void> _deleteSaved(SavedMixQuery q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete query?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Remove “${q.name}”?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await CaseMixQueryStorage.delete(q.id);
    final saved = await CaseMixQueryStorage.getAll();
    if (!mounted) return;
    setState(() => _saved = saved);
  }



  String _cvBlurb() {
    final n = _matches.length;
    final filter = _summaryLine();
    if (n == 0) {
      return 'No cases currently match these filters in Etherlog.\nFilters: $filter';
    }
    final dates = _matches.map((c) => c.date).toList()..sort();
    final from = dates.first;
    final to = dates.last;
    final fromStr = '${from.day}/${from.month}/${from.year}';
    final toStr = '${to.day}/${to.month}/${to.year}';
    return '$n case${n == 1 ? '' : 's'} matching: $filter '
        '(logbook period $fromStr - $toStr). '
        'Source: Etherlog case mix export.';
  }

  Future<void> _copyCvBlurb() async {
    final text = _cvBlurb();
    await Clipboard.setData(ClipboardData(text: text));
    await AppHaptics.selection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CV blurb copied')),
    );
  }

  Future<void> _exportPdf() async {
    if (_matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching cases to export')),
      );
      return;
    }
    await AppHaptics.medium();
    final doc = pw.Document();
    final filter = _summaryLine();
    final now = DateTime.now();
    final generated =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ETHERLOG - Case mix report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated $generated',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Text(
            'Filters (AND)',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(filter, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text(
            '${_matches.length} matching case${_matches.length == 1 ? '' : 's'}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _cvBlurb(),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
            },
            headers: ['Date', 'Specialty', 'ASA', 'Priority', 'Procedure / Dx'],
            data: _matches.map((c) {
              final title = c.procedure.isNotEmpty ? c.procedure : c.diagnosis;
              return [
                '${c.date.day}/${c.date.month}/${c.date.year}',
                c.specialty,
                c.asaGrade,
                c.priority,
                title,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'This report is generated from locally stored logbook data. '
                'Verify counts against source records before use in formal applications.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await UsageStats.incrementPdfExport();
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'etherlog_case_mix_${now.millisecondsSinceEpoch}',
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.caseMixBuilder),
        actions: [
          IconButton(
            tooltip: l10n.saveQuery,
            onPressed: _saveQuery,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                if (_saved.isNotEmpty) ...[
                  Text(
                    l10n.savedQueries.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _saved.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final q = _saved[i];
                        return InputChip(
                          label: Text(q.name),
                          onPressed: () => _applySaved(q),
                          onDeleted: () => _deleteSaved(q),
                          deleteIconColor: AppTheme.textSecondary,
                          backgroundColor: AppTheme.surface,
                          side: BorderSide(color: AppTheme.surfaceLight),
                          labelStyle: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ...List.generate(_conditions.length, (i) {
                  return _conditionCard(i);
                }),
                TextButton.icon(
                  onPressed: _addCondition,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addCondition),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.matchingCases(_matches.length),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _summaryLine(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                              _matches.isEmpty ? null : _copyCvBlurb,
                              icon: const Icon(Icons.notes_outlined, size: 18),
                              label: const Text('CV blurb'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                              _matches.isEmpty ? null : _exportPdf,
                              icon: const Icon(
                                  Icons.picture_as_pdf_outlined,
                                  size: 18),
                              label: Text(l10n.exportPdf),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.queryResults.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No cases match these conditions.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                else
                  ..._matches.map(_resultTile),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conditionCard(int index) {
    final cond = _conditions[index];
    final ops = _opsFor(cond.field);
    if (!ops.contains(cond.op)) {
      cond.op = ops.first;
    }
    final needsValue = cond.op != MixOp.isTrue && cond.op != MixOp.isFalse;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<MixField>(
                  value: cond.field,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.field.toUpperCase(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: MixField.values
                      .map(
                        (f) => DropdownMenuItem(
                      value: f,
                      child: Text(
                        _getFieldLabel(f),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                      .toList(),
                  selectedItemBuilder: (context) {
                    return MixField.values
                        .map(
                          (f) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _getFieldLabel(f),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                        .toList();
                  },
                  onChanged: (f) {
                    if (f == null) return;
                    setState(() {
                      cond.field = f;
                      cond.op = _opsFor(f).first;
                      if (f == MixField.priority && cond.value.isEmpty) {
                        cond.value = 'Emergency';
                      }
                    });
                    _run();
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => _removeCondition(index),
                icon: Icon(Icons.close, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<MixOp>(
                  value: cond.op,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'OP',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: ops
                      .map(
                        (o) => DropdownMenuItem(
                      value: o,
                      child: Text(_opLabel(o).toUpperCase(), overflow: TextOverflow.ellipsis),
                    ),
                  )
                      .toList(),
                  onChanged: (o) {
                    if (o == null) return;
                    setState(() => cond.op = o);
                    _run();
                  },
                ),
              ),
              if (needsValue) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: cond.value.toUpperCase()),
                    optionsBuilder: (TextEditingValue tev) {
                      return _suggestionsFor(cond.field, tev.text);
                    },
                    onSelected: (s) {
                      setState(() => cond.value = s.toUpperCase());
                      _run();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                      // Keep controller uppercase
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          TextInputFormatter.withFunction((old, neu) {
                            return neu.copyWith(text: neu.text.toUpperCase());
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'VALUE',
                          isDense: true,
                          hintText: 'E.G. EMERGENCY, LAPAROTOMY',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) {
                          cond.value = v.toUpperCase();
                          _run();
                        },
                        onSubmitted: (_) => onSubmit(),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultTile(CaseRecord c) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, __, ___) => CaseDetailScreen(caseRecord: c)),
        );
        await _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.procedure.isNotEmpty ? c.procedure : c.diagnosis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.date.day}/${c.date.month}/${c.date.year} · ${c.asaGrade} · ${c.priority}'
                        '${c.specialty.isNotEmpty ? ' · ${c.specialty}' : ''}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
