import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/case_record.dart';

/// Detailed Anaesthetic Assessment & Plan screen matching the clinical proforma.
/// Page 1: Pre-Op Assessment, History, Vitals, Airway, and System-wise Investigations.
/// Page 2: Surgical Plan, Airway Hardware, Calculators (Dosing, Paediatric, Blood, Fluid), Notes, Post-op Plan.
class DetailedAssessmentScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final CaseRecord? existingCase;
  final bool isReadOnly;

  const DetailedAssessmentScreen({
    super.key,
    this.initialData,
    this.existingCase,
    this.isReadOnly = false,
  });

  @override
  State<DetailedAssessmentScreen> createState() =>
      _DetailedAssessmentScreenState();
}

class _DetailedAssessmentScreenState extends State<DetailedAssessmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Page 1 (Front) Demographics & Case Info ---
  final _caseOrderController = TextEditingController();
  final _hospitalNoController = TextEditingController();
  final _occupationController = TextEditingController();
  final _ageController = TextEditingController();
  String _ageUnit = 'years';
  String _gender = 'Male';
  DateTime _date = DateTime.now();

  // --- Diagnosis & Clinical History ---
  final _dxController = TextEditingController();
  final _sxController = TextEditingController();
  final _hopcController = TextEditingController();
  final _rxHistoryController = TextEditingController();
  final _comorbiditiesController = TextEditingController();
  final _medsLastDoseController = TextEditingController();
  final _cardiacHistoryController = TextEditingController();
  final _pastSurgicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _lriUriController = TextEditingController();
  final _osaHistoryController = TextEditingController();
  final _addictionsController = TextEditingController();
  final _consultsController = TextEditingController();

  // --- General Examination & Vitals ---
  final _hrController = TextEditingController();
  final _bpController = TextEditingController();
  final _tempController = TextEditingController();
  final _rrController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _ivAccessController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double? _bmi;

  // --- Airway Examination ---
  final _anatomicalFeaturesController = TextEditingController();
  final _mouthOpeningController = TextEditingController();
  String _mallampati = 'Class I';
  String _dentition = 'Intact';
  String _mandibularProtrusion = 'Normal';
  String _upperLipBite = 'Class I';
  String _neckExtension = 'Normal (>35°)';
  final _thyromentalController = TextEditingController();
  final _sternomentalController = TextEditingController();
  final _neckCircController = TextEditingController();

  // --- System-Wise Investigations ---
  final _haematController = TextEditingController();
  final _renalController = TextEditingController();
  final _hepaticController = TextEditingController();
  final _infectiousController = TextEditingController();
  final _ecgController = TextEditingController();
  final _echoController = TextEditingController();
  final _cxrController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _tshCortisolController = TextEditingController();
  final _imagingController = TextEditingController();

  // --- Page 2 (Back) Surgical Plan ---
  final _approachController = TextEditingController();
  final _incisionController = TextEditingController();
  final _positionController = TextEditingController();
  final _eblController = TextEditingController();
  final _estTimeController = TextEditingController();
  final _ivPlanController = TextEditingController();
  final _infusionPumpsController = TextEditingController();
  final _bgWarmerController =
      TextEditingController(text: 'Forced Air Blanket (Bair Hugger)');
  final _monitorsController = TextEditingController();

  // --- Intubation & Airway Hardware Plan ---
  final _ivGasController = TextEditingController();
  final _relaxantController = TextEditingController();
  final _bladeController = TextEditingController();
  final _ettPlanController = TextEditingController();
  final _circuitController = TextEditingController();
  final _exchangeCatheterController = TextEditingController();
  final _tappaBlockerController = TextEditingController();
  final _fobCmacController = TextEditingController();
  final _tempProbeController = TextEditingController();

  // --- Blood & Fluids Plan Inputs ---
  final _baselineHbController = TextEditingController(text: '12');
  final _targetHbController = TextEditingController(text: '10');
  final _bloodOrderedController = TextEditingController();
  final _npoHoursController = TextEditingController(text: '6');
  final _thirdSpaceRateController = TextEditingController(text: '4');

  // --- Notes & Postop Plan ---
  final _intraopNotesController = TextEditingController();
  final _dispositionController = TextEditingController(text: 'PACU / Ward');
  final _analgesiaPlanController = TextEditingController();
  double _fluidBloodRatio = 3.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _populateInitialData();
  }

  void _populateInitialData() {
    final src = widget.initialData ?? widget.existingCase?.detailedAssessment;
    final c = widget.existingCase;

    if (src != null) {
      _caseOrderController.text = src['caseOrder']?.toString() ?? '';
      _hospitalNoController.text =
          src['hospitalNo']?.toString() ?? c?.caseNumber ?? '';
      _occupationController.text = src['occupation']?.toString() ?? '';
      _ageController.text =
          src['age']?.toString() ?? c?.patientAge?.toString() ?? '';
      _ageUnit = src['ageUnit']?.toString() ?? c?.ageUnit ?? 'years';
      _gender = src['gender']?.toString() ?? c?.patientGender ?? 'Male';
      if (src['date'] != null) {
        _date = DateTime.tryParse(src['date'].toString()) ?? DateTime.now();
      }

      _dxController.text = src['dx']?.toString() ?? c?.diagnosis ?? '';
      _sxController.text = src['sx']?.toString() ?? c?.procedure ?? '';
      _hopcController.text = src['hopc']?.toString() ?? '';
      _rxHistoryController.text = src['rxHistory']?.toString() ?? '';
      _comorbiditiesController.text = src['comorbidities']?.toString() ??
          (c?.asaGrade != null && c!.asaGrade != 'ASA I' ? c.asaGrade : '');
      _medsLastDoseController.text = src['medsLastDose']?.toString() ?? '';
      _cardiacHistoryController.text = src['cardiacHistory']?.toString() ?? '';
      _pastSurgicalHistoryController.text =
          src['pastSurgicalHistory']?.toString() ?? '';
      _allergiesController.text = src['allergies']?.toString() ?? '';
      _lriUriController.text = src['lriUri']?.toString() ?? '';
      _osaHistoryController.text = src['osaHistory']?.toString() ?? '';
      _addictionsController.text = src['addictions']?.toString() ?? '';
      _consultsController.text = src['consults']?.toString() ??
          (c?.supervisor != null && c!.supervisor!.isNotEmpty
              ? 'Supervisor: ${c.supervisor} (${c.role})'
              : '');

      _hrController.text = src['hr']?.toString() ?? '';
      _bpController.text = src['bp']?.toString() ?? '';
      _tempController.text = src['temp']?.toString() ?? '';
      _rrController.text = src['rr']?.toString() ?? '';
      _spo2Controller.text = src['spo2']?.toString() ?? '';
      _ivAccessController.text = src['ivAccess']?.toString() ?? '';
      _heightController.text =
          src['height']?.toString() ?? c?.patientHeight?.toString() ?? '';
      _weightController.text =
          src['weight']?.toString() ?? c?.patientWeight?.toString() ?? '';

      _anatomicalFeaturesController.text =
          src['anatomicalFeatures']?.toString() ?? '';
      _mouthOpeningController.text = src['mouthOpening']?.toString() ?? '';
      _mallampati = src['mallampati']?.toString() ?? 'Class I';
      _dentition = src['dentition']?.toString() ?? 'Intact';
      _mandibularProtrusion = src['mandibularProtrusion']?.toString() ?? 'Normal';
      _upperLipBite = src['upperLipBite']?.toString() ?? 'Class I';
      _neckExtension = src['neckExtension']?.toString() ?? 'Normal (>35°)';
      _thyromentalController.text = src['thyromental']?.toString() ?? '';
      _sternomentalController.text = src['sternomental']?.toString() ?? '';
      _neckCircController.text = src['neckCirc']?.toString() ?? '';

      _haematController.text = src['haemat']?.toString() ?? '';
      _renalController.text = src['renal']?.toString() ?? '';
      _hepaticController.text = src['hepatic']?.toString() ?? '';
      _infectiousController.text = src['infectious']?.toString() ?? '';
      _ecgController.text = src['ecg']?.toString() ?? '';
      _echoController.text = src['echo']?.toString() ?? '';
      _cxrController.text = src['cxr']?.toString() ?? '';
      _glucoseController.text = src['glucose']?.toString() ?? '';
      _tshCortisolController.text = src['tshCortisol']?.toString() ?? '';
      _imagingController.text = src['imaging']?.toString() ?? '';

      _approachController.text = src['approach']?.toString() ?? '';
      _incisionController.text = src['incision']?.toString() ?? '';
      _positionController.text = src['position']?.toString() ?? '';
      _eblController.text = src['ebl']?.toString() ?? '';
      _estTimeController.text = src['estTime']?.toString() ?? '';
      _ivPlanController.text = src['ivPlan']?.toString() ?? '';
      _infusionPumpsController.text = src['infusionPumps']?.toString() ?? '';
      _bgWarmerController.text = (src['bgWarmer'] != null &&
              src['bgWarmer'].toString().trim().isNotEmpty)
          ? src['bgWarmer'].toString()
          : 'Forced Air Blanket (Bair Hugger)';
      _monitorsController.text = src['monitors']?.toString() ?? '';

      _ivGasController.text = src['ivGas']?.toString() ?? '';
      _relaxantController.text = src['relaxant']?.toString() ?? '';
      _bladeController.text = src['blade']?.toString() ?? '';
      _ettPlanController.text = src['ettPlan']?.toString() ?? '';
      _circuitController.text = src['circuit']?.toString() ?? '';
      _exchangeCatheterController.text =
          src['exchangeCatheter']?.toString() ?? '';
      _tappaBlockerController.text = src['tappaBlocker']?.toString() ?? '';
      _fobCmacController.text = src['fobCmac']?.toString() ?? '';
      _tempProbeController.text = src['tempProbe']?.toString() ?? '';

      _baselineHbController.text = src['baselineHb']?.toString() ?? '12';
      _targetHbController.text = src['targetHb']?.toString() ?? '10';
      _bloodOrderedController.text = src['bloodOrdered']?.toString() ?? '';
      _npoHoursController.text = src['npoHours']?.toString() ?? '6';
      _thirdSpaceRateController.text = src['thirdSpaceRate']?.toString() ?? '4';

      _intraopNotesController.text =
          src['intraopNotes']?.toString() ?? c?.notes ?? '';
      _dispositionController.text =
          src['disposition']?.toString() ?? 'PACU / Ward';
      _analgesiaPlanController.text = src['analgesiaPlan']?.toString() ?? '';
    } else if (c != null) {
      _hospitalNoController.text = c.caseNumber;
      _dxController.text = c.diagnosis;
      _sxController.text = c.procedure;
      _ageController.text = c.patientAge?.toString() ?? '';
      _ageUnit = c.ageUnit;
      _gender = c.patientGender ?? 'Male';
      _heightController.text = c.patientHeight?.toString() ?? '';
      _weightController.text = c.patientWeight?.toString() ?? '';
      _date = c.date;
      _intraopNotesController.text = c.notes ?? '';
      if (c.asaGrade != 'ASA I') {
        _comorbiditiesController.text = c.asaGrade;
      }
      if (c.supervisor != null && c.supervisor!.isNotEmpty) {
        _consultsController.text = 'Supervisor: ${c.supervisor} (${c.role})';
      }
      if (c.airwayManagement != null && c.airwayManagement != 'Not applicable') {
        _ettPlanController.text =
            '${c.ettSize != null ? 'Size ${c.ettSize} ' : ''}${c.airwayManagement}';
      }
      if (c.priority == 'Emergency') {
        _caseOrderController.text = 'Emergency';
      }
      if (c.invasiveMonitoring.isNotEmpty) {
        _ivPlanController.text = c.invasiveMonitoring
            .map((m) => m['line']?.toString() ?? '')
            .where((l) => l.isNotEmpty)
            .join(', ');
      }
      if (c.surgeryDuration != null &&
          c.surgeryDuration!.isNotEmpty &&
          _estTimeController.text.isEmpty) {
        _estTimeController.text = c.surgeryDuration!;
      }
    }

    if (c != null) {
      final regionalItems = <String>[];
      for (final b in c.regionalBlocks) {
        final name = (b['name'] ?? b['block'])?.toString().trim() ?? '';
        if (name.isNotEmpty && name != 'None / Not performed') {
          if (!regionalItems.any((r) => r.toLowerCase() == name.toLowerCase())) {
            regionalItems.add(name);
          }
        }
      }
      final tech = c.technique.trim() ?? '';
      if (tech.toLowerCase().contains('spinal') ||
          tech.toLowerCase().contains('epidural') ||
          tech.toLowerCase().contains('cse') ||
          tech.toLowerCase().contains('block') ||
          tech.toLowerCase().contains('regional')) {
        if (!regionalItems.any((r) => r.toLowerCase() == tech.toLowerCase())) {
          regionalItems.insert(0, tech);
        }
      }
      if (c.catheterPlaced) {
        final catheterBlocks = c.regionalBlocks
            .where((r) =>
                (r['catheterPlaced'] == true || r['hasCatheter'] == true) &&
                r['name'] != null &&
                r['name'] != 'None / Not performed')
            .map((r) => (r['name'] ?? r['block'])?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();

        if (catheterBlocks.isNotEmpty) {
          for (final cb in catheterBlocks) {
            final idx = regionalItems.indexWhere(
                (r) => r.toLowerCase() == cb.toLowerCase());
            if (idx >= 0) {
              if (!regionalItems[idx].toLowerCase().contains('catheter')) {
                regionalItems[idx] = '${regionalItems[idx]} (+ Catheter)';
              }
            } else {
              regionalItems.add('$cb (+ Catheter)');
            }
          }
        } else if (regionalItems.isNotEmpty) {
          final idx = regionalItems.indexWhere((r) =>
              r.toLowerCase().contains('epidural') ||
              r.toLowerCase().contains('cse') ||
              r.toLowerCase().contains('block') ||
              r.toLowerCase().contains('nerve') ||
              r.toLowerCase().contains('catheter'));
          if (idx >= 0) {
            if (!regionalItems[idx].toLowerCase().contains('catheter')) {
              regionalItems[idx] = '${regionalItems[idx]} (+ Catheter)';
            }
          } else {
            regionalItems.add('Catheter placed');
          }
        } else {
          regionalItems.add('Catheter placed');
        }
      }

      if (c.pca) {
        if (!regionalItems.any((r) => r.toLowerCase().contains('pca'))) {
          regionalItems.add('Patient-Controlled Analgesia (PCA)');
        }
      }

      if (regionalItems.isNotEmpty) {
        final existing = _analgesiaPlanController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        for (final r in regionalItems) {
          if (!existing.any((e) => e.toLowerCase() == r.toLowerCase())) {
            existing.add(r);
          }
        }
        _analgesiaPlanController.text = existing.join(', ');
      }
    }

    if (c != null && c.invasiveMonitoring.isNotEmpty) {
      final curMonitors = _monitorsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (!curMonitors.any((m) => m.toLowerCase().contains('standard asa'))) {
        curMonitors.insert(0, 'Standard ASA');
      }
      for (final m in c.invasiveMonitoring) {
        final line = m['line']?.toString() ?? '';
        final lower = line.toLowerCase();
        if (lower.contains('arterial') &&
            !curMonitors.any((s) => s.toLowerCase().contains('arterial'))) {
          curMonitors.add('Arterial line');
        } else if (lower.contains('cvc') &&
            !curMonitors.any((s) => s.toLowerCase().contains('cvc'))) {
          curMonitors.add('CVC line');
        } else if ((lower.contains('bis') || lower.contains('entropy')) &&
            !curMonitors.any((s) =>
                s.toLowerCase().contains('bis') ||
                s.toLowerCase().contains('entropy'))) {
          curMonitors.add('BIS/Entropy');
        }
      }
      _monitorsController.text = curMonitors.join(', ');
    }

    if (_monitorsController.text.trim().isEmpty) {
      _monitorsController.text = 'Standard ASA';
    }

    if (_bgWarmerController.text.trim().isEmpty) {
      _bgWarmerController.text = 'Forced Air Blanket (Bair Hugger)';
    }

    final ageVal = double.tryParse(_ageController.text.trim());
    final isChild = ageVal != null && (_ageUnit != 'years' || ageVal < 17);
    if (isChild && _occupationController.text.trim().isEmpty) {
      _occupationController.text = 'Child';
    }

    _calculateBmi();
  }

  TableRow _tableHeader(List<String> cells) {
    return TableRow(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.6),
      ),
      children: cells
          .map((c) => Padding(
                padding: const EdgeInsets.all(7.0),
                child: Text(
                  c,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ))
          .toList(),
    );
  }

  TableRow _tableRow(String c1, String c2) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(7.0),
          child: Text(
            c1,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(7.0),
          child: Text(
            c2,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _caseOrderController.dispose();
    _hospitalNoController.dispose();
    _occupationController.dispose();
    _ageController.dispose();
    _dxController.dispose();
    _sxController.dispose();
    _hopcController.dispose();
    _rxHistoryController.dispose();
    _comorbiditiesController.dispose();
    _medsLastDoseController.dispose();
    _cardiacHistoryController.dispose();
    _pastSurgicalHistoryController.dispose();
    _allergiesController.dispose();
    _lriUriController.dispose();
    _osaHistoryController.dispose();
    _addictionsController.dispose();
    _consultsController.dispose();
    _hrController.dispose();
    _bpController.dispose();
    _tempController.dispose();
    _rrController.dispose();
    _spo2Controller.dispose();
    _ivAccessController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _anatomicalFeaturesController.dispose();
    _mouthOpeningController.dispose();
    _thyromentalController.dispose();
    _sternomentalController.dispose();
    _neckCircController.dispose();
    _haematController.dispose();
    _renalController.dispose();
    _hepaticController.dispose();
    _infectiousController.dispose();
    _ecgController.dispose();
    _echoController.dispose();
    _cxrController.dispose();
    _glucoseController.dispose();
    _tshCortisolController.dispose();
    _imagingController.dispose();
    _approachController.dispose();
    _incisionController.dispose();
    _positionController.dispose();
    _eblController.dispose();
    _estTimeController.dispose();
    _ivPlanController.dispose();
    _infusionPumpsController.dispose();
    _bgWarmerController.dispose();
    _monitorsController.dispose();
    _ivGasController.dispose();
    _relaxantController.dispose();
    _bladeController.dispose();
    _ettPlanController.dispose();
    _circuitController.dispose();
    _exchangeCatheterController.dispose();
    _tappaBlockerController.dispose();
    _fobCmacController.dispose();
    _tempProbeController.dispose();
    _baselineHbController.dispose();
    _targetHbController.dispose();
    _bloodOrderedController.dispose();
    _npoHoursController.dispose();
    _thirdSpaceRateController.dispose();
    _intraopNotesController.dispose();
    _dispositionController.dispose();
    _analgesiaPlanController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    final w = double.tryParse(_weightController.text.trim());
    final h = double.tryParse(_heightController.text.trim());
    if (w != null && h != null && h > 0) {
      final m = h / 100.0;
      setState(() => _bmi = w / (m * m));
    } else {
      setState(() => _bmi = null);
    }
  }

  Map<String, dynamic> _toMap() {
    return {
      'caseOrder': _caseOrderController.text.trim(),
      'hospitalNo': _hospitalNoController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'age': _ageController.text.trim(),
      'ageUnit': _ageUnit,
      'gender': _gender,
      'date': _date.toIso8601String(),
      'dx': _dxController.text.trim(),
      'sx': _sxController.text.trim(),
      'hopc': _hopcController.text.trim(),
      'rxHistory': _rxHistoryController.text.trim(),
      'comorbidities': _comorbiditiesController.text.trim(),
      'medsLastDose': _medsLastDoseController.text.trim(),
      'cardiacHistory': _cardiacHistoryController.text.trim(),
      'pastSurgicalHistory': _pastSurgicalHistoryController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'lriUri': _lriUriController.text.trim(),
      'osaHistory': _osaHistoryController.text.trim(),
      'addictions': _addictionsController.text.trim(),
      'consults': _consultsController.text.trim(),
      'hr': _hrController.text.trim(),
      'bp': _bpController.text.trim(),
      'temp': _tempController.text.trim(),
      'rr': _rrController.text.trim(),
      'spo2': _spo2Controller.text.trim(),
      'ivAccess': _ivAccessController.text.trim(),
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'bmi': _bmi,
      'anatomicalFeatures': _anatomicalFeaturesController.text.trim(),
      'mouthOpening': _mouthOpeningController.text.trim(),
      'mallampati': _mallampati,
      'dentition': _dentition,
      'mandibularProtrusion': _mandibularProtrusion,
      'upperLipBite': _upperLipBite,
      'neckExtension': _neckExtension,
      'thyromental': _thyromentalController.text.trim(),
      'sternomental': _sternomentalController.text.trim(),
      'neckCirc': _neckCircController.text.trim(),
      'haemat': _haematController.text.trim(),
      'renal': _renalController.text.trim(),
      'hepatic': _hepaticController.text.trim(),
      'infectious': _infectiousController.text.trim(),
      'ecg': _ecgController.text.trim(),
      'echo': _echoController.text.trim(),
      'cxr': _cxrController.text.trim(),
      'glucose': _glucoseController.text.trim(),
      'tshCortisol': _tshCortisolController.text.trim(),
      'imaging': _imagingController.text.trim(),
      'approach': _approachController.text.trim(),
      'incision': _incisionController.text.trim(),
      'position': _positionController.text.trim(),
      'ebl': _eblController.text.trim(),
      'estTime': _estTimeController.text.trim(),
      'ivPlan': _ivPlanController.text.trim(),
      'infusionPumps': _infusionPumpsController.text.trim(),
      'bgWarmer': _bgWarmerController.text.trim(),
      'monitors': _monitorsController.text.trim(),
      'ivGas': _ivGasController.text.trim(),
      'relaxant': _relaxantController.text.trim(),
      'blade': _bladeController.text.trim(),
      'ettPlan': _ettPlanController.text.trim(),
      'circuit': _circuitController.text.trim(),
      'exchangeCatheter': _exchangeCatheterController.text.trim(),
      'tappaBlocker': _tappaBlockerController.text.trim(),
      'fobCmac': _fobCmacController.text.trim(),
      'tempProbe': _tempProbeController.text.trim(),
      'baselineHb': _baselineHbController.text.trim(),
      'targetHb': _targetHbController.text.trim(),
      'bloodOrdered': _bloodOrderedController.text.trim(),
      'npoHours': _npoHoursController.text.trim(),
      'thirdSpaceRate': _thirdSpaceRateController.text.trim(),
      'intraopNotes': _intraopNotesController.text.trim(),
      'disposition': _dispositionController.text.trim(),
      'analgesiaPlan': _analgesiaPlanController.text.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  void _saveAndPop() {
    final data = _toMap();
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withValues(alpha: 0.85),
        elevation: 0,
        title: Text(
          'Anaesthetic Assessment & Plan',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _saveAndPop,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                label: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.85),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Anaesthetic Assessment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _tabController.index == 0
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medical_services_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Surgical & Anaesthetic Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _tabController.index == 1
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.35),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFrontPage(),
            _buildBackPage(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // PAGE 1 (FRONT): PRE-OP ASSESSMENT & INVESTIGATIONS
  // =========================================================================
  Widget _buildFrontPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Demographics
        _sectionCard(
          title: 'Case Identification & Demographics',
          icon: Icons.badge_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: _presetField(
                    controller: _caseOrderController,
                    label: 'Case Order',
                    hint: 'e.g. 1st, 2nd',
                    options: const ['1st', '2nd', '3rd', '4th', 'Emergency'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _textField(
                    controller: _hospitalNoController,
                    label: 'Hospital No. / MRN',
                    hint: 'e.g. MRN-123456',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _occupationController,
              label: 'Occupation',
              hint: 'e.g. Child, Student, Teacher',
              options: const [
                'Child',
                'Student',
                'Desk / Sedentary',
                'Manual Labor',
                'Homemaker',
                'Retired',
                'Healthcare',
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _textField(
                    controller: _ageController,
                    label: 'Age',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final a = double.tryParse(val.trim());
                      if (a != null && (_ageUnit != 'years' || a < 17)) {
                        if (_occupationController.text.isEmpty) {
                          _occupationController.text = 'Child';
                        }
                      } else if (a != null && _ageUnit == 'years' && a >= 17) {
                        if (_occupationController.text.toLowerCase() == 'child') {
                          _occupationController.clear();
                        }
                      }
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _dropdownField(
                    label: 'Unit',
                    value: _ageUnit,
                    items: const ['years', 'months', 'days'],
                    onChanged: (v) {
                      setState(() {
                        _ageUnit = v ?? 'years';
                        final a = double.tryParse(_ageController.text.trim());
                        if (a != null && (_ageUnit != 'years' || a < 17)) {
                          if (_occupationController.text.isEmpty) {
                            _occupationController.text = 'Child';
                          }
                        } else if (a != null && _ageUnit == 'years' && a >= 17) {
                          if (_occupationController.text.toLowerCase() == 'child') {
                            _occupationController.clear();
                          }
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _dropdownField(
                    label: 'Gender',
                    value: _gender,
                    items: const ['Male', 'Female', 'Other'],
                    onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSolid.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Assessment Date:',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 2. Diagnosis & History
        _sectionCard(
          title: 'Diagnosis & Clinical History',
          icon: Icons.history_edu_outlined,
          children: [
            _presetField(
              controller: _dxController,
              label: 'DX (Diagnosis)',
              hint: 'e.g. Cholelithiasis / Inguinal Hernia',
              options: const [
                'Cholelithiasis',
                'Acute Appendicitis',
                'Osteoarthritis Knee',
                'Inguinal Hernia',
                'Full Term Pregnancy',
                'Renal Calculus',
                'Subdural Hematoma',
                'Femur Fracture',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _sxController,
              label: 'SX (Proposed Surgery / Procedure)',
              hint: 'e.g. Lap Cholecystectomy',
              options: const [
                'Lap Cholecystectomy',
                'Appendectomy',
                'Total Knee Arthroplasty',
                'Hernia Repair (TAPP/TEP)',
                'LSCS (Cesarean)',
                'PCNL / URS',
                'Craniotomy & Evacuation',
                'ORIF Femur',
              ],
            ),
            const SizedBox(height: 18),
            _textField(
              controller: _hopcController,
              label: 'HOPC (History of Present Complaint)',
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _comorbiditiesController,
              label: 'Comorbidities & Medical History',
              hint: 'Tap presets to append multiple',
              multiSelect: true,
              maxLines: 2,
              options: const [
                'None',
                'HTN',
                'DM Type 2',
                'Asthma',
                'COPD',
                'Hypothyroid',
                'IHD',
                'CKD',
                'GERD',
                'Seizure Disorder',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _rxHistoryController,
              label: 'RX History (Past & Current Treatments)',
              hint: 'Tap presets to append',
              multiSelect: true,
              maxLines: 2,
              options: const [
                'Nil Significant',
                'Antihypertensives',
                'OHAs',
                'Insulin',
                'Thyroxine',
                'Inhalers',
                'Statins',
                'Antiepileptics',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _medsLastDoseController,
              label: 'Significant Meds & Last Dose',
              hint: 'Anticoagulants, antiplatelets, morning doses',
              multiSelect: true,
              maxLines: 2,
              options: const [
                'Aspirin held 5d',
                'Clopidogrel held 7d',
                'NOAC held 48h',
                'Warfarin held',
                'Morning ACE-I held',
                'Morning Beta-blocker taken',
                'Morning Insulin held',
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Specific System Enquiries:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _cardiacHistoryController,
              label: 'Cardiac History (IHD, HTN, Pacemaker, METS)',
              multiSelect: true,
              options: const [
                'None / METS >4',
                'HTN Controlled',
                'IHD / Prior PCI',
                'Pacemaker Insitu',
                'Arrhythmia / AF',
                'Heart Failure',
                'METS <4',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _pastSurgicalHistoryController,
              label: 'Past Surgical & Anaesthetic History',
              multiSelect: true,
              options: const [
                'Uneventful GA',
                'Uneventful Spinal',
                'History of PONV',
                'Difficult Airway',
                'Delayed Emergence',
                'First Surgery',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _allergiesController,
              label: 'Allergies (Drugs, Latex, Food)',
              multiSelect: true,
              options: const [
                'NKDA',
                'Penicillin',
                'NSAIDs / Paracetamol',
                'Sulfa Drugs',
                'Latex Allergy',
                'Opioids',
                'Egg / Soy (Propofol)',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _lriUriController,
              label: 'Recent Respiratory Infections (LRI / URI)',
              multiSelect: true,
              options: const [
                'Nil',
                'Recent URI (<2 wks)',
                'Active Cough & Cold',
                'Productive Sputum',
                'Wheezing / Bronchospasm',
                'Resolved URI',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _osaHistoryController,
              label: 'OSA History (Snoring, STOP-BANG, CPAP)',
              multiSelect: true,
              options: const [
                'Low Risk (STOP-BANG <3)',
                'Intermediate Risk (3-4)',
                'High Risk (>=5)',
                'Loud Snoring',
                'Daytime Somnolence',
                'CPAP Compliant',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _addictionsController,
              label: 'Addictions (Tobacco, Alcohol, Substances)',
              multiSelect: true,
              options: const [
                'Nil',
                'Smoker (Cigarettes)',
                'Ex-smoker (>6 wks)',
                'Alcohol (Social)',
                'Alcohol (Dependent)',
                'Tobacco / Gutkha Chewing',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _consultsController,
              label: 'Specialist Consultations & Clearances',
              multiSelect: true,
              options: const [
                'Cardiology Cleared',
                'Pulmonology Cleared',
                'Endocrinology Cleared',
                'Nephrology Cleared',
                'High Risk Consent Documented',
              ],
            ),
          ],
        ),

        // 3. Physical Examination & Vitals
        _sectionCard(
          title: 'Examination & Anthropometrics',
          icon: Icons.monitor_heart_outlined,
          children: [
            _vitalSlider(
              label: 'Heart Rate',
              icon: Icons.favorite_rounded,
              controller: _hrController,
              fallbackDefault: 72,
              min: 40,
              max: 180,
              divisions: 140,
              unit: 'bpm',
              accentColor: const Color(0xFFEF5350),
              quickPresets: const ['60', '72', '80', '90', '100', '110'],
            ),
            const SizedBox(height: 2),
            _presetField(
              controller: _bpController,
              label: 'Blood Pressure (mmHg)',
              hint: '120/80',
              options: const [
                '120/80',
                '130/85',
                '140/90',
                '110/70',
                '100/60',
                '150/95',
              ],
            ),
            const SizedBox(height: 18),
            _vitalSlider(
              label: 'Respiratory Rate',
              icon: Icons.air_rounded,
              controller: _rrController,
              fallbackDefault: 16,
              min: 8,
              max: 40,
              divisions: 32,
              unit: '/min',
              accentColor: const Color(0xFF26A69A),
              quickPresets: const ['12', '14', '16', '18', '20'],
            ),
            const SizedBox(height: 2),
            _vitalSlider(
              label: 'SpO₂ Oxygen Saturation',
              icon: Icons.water_drop_rounded,
              controller: _spo2Controller,
              fallbackDefault: 99,
              min: 80,
              max: 100,
              divisions: 20,
              unit: '%',
              accentColor: const Color(0xFF42A5F5),
              quickPresets: const ['95%', '97%', '98%', '99%', '100%'],
            ),
            const SizedBox(height: 2),
            _vitalSlider(
              label: 'Body Temperature',
              icon: Icons.thermostat_rounded,
              controller: _tempController,
              fallbackDefault: 36.8,
              min: 35.0,
              max: 41.0,
              divisions: 60,
              unit: '°C',
              isDecimal: true,
              accentColor: const Color(0xFFFFA726),
              quickPresets: const ['36.5', '36.8', '37.0', '37.5', '38.0'],
            ),
            const SizedBox(height: 2),
            _presetField(
              controller: _ivAccessController,
              label: 'IV Access / Cannulation',
              hint: '18G R Forearm',
              options: const [
                '18G R Forearm',
                '18G L Forearm',
                '16G R Forearm',
                '20G R Dorsum',
                '2x 16G Bore',
                'Radial A-Line',
                'Triple Lumen CVC',
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateBmi(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _calculateBmi();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _bmi != null && _bmi! > 30
                            ? AppTheme.warning.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'BMI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _bmi != null ? _bmi!.toStringAsFixed(1) : '--',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _bmi != null && _bmi! > 30
                                ? AppTheme.warning
                                : AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 4. Airway Examination
        _sectionCard(
          title: 'Airway Examination (Difficult Airway Risk)',
          icon: Icons.air_outlined,
          children: [
            _presetField(
              controller: _anatomicalFeaturesController,
              label: 'Anatomical Features',
              hint: 'Micrognathia, Short Neck, Beards',
              multiSelect: true,
              options: const [
                'Normal / Adequate',
                'Short Neck',
                'Micrognathia',
                'Macroglossia',
                'Full Beard',
                'Obese Neck',
                'High Arched Palate',
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _presetField(
                    controller: _mouthOpeningController,
                    label: 'Mouth Opening',
                    hint: '> 3 fingers (> 4 cm)',
                    options: const [
                      '> 3 fingers (> 4 cm)',
                      '2.5 - 3 fingers',
                      '< 2 fingers (< 3 cm)',
                      'Trismus',
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdownField(
                    label: 'Mallampati',
                    value: _mallampati,
                    items: const [
                      'Class I',
                      'Class II',
                      'Class III',
                      'Class IV',
                    ],
                    onChanged: (v) => setState(() => _mallampati = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _dropdownField(
                    label: 'Dentition',
                    value: _dentition,
                    items: const [
                      'Intact',
                      'Loose teeth',
                      'Edentulous',
                      'Capped/Crowns',
                      'Dentures',
                      'Prominent Incisors',
                    ],
                    onChanged: (v) => setState(() => _dentition = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdownField(
                    label: 'Mandibular Protrusion',
                    value: _mandibularProtrusion,
                    items: const [
                      'Normal',
                      'Class A',
                      'Class B',
                      'Class C',
                    ],
                    onChanged: (v) =>
                        setState(() => _mandibularProtrusion = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _dropdownField(
              label: 'Upper Lip Bite Test',
              value: _upperLipBite,
              items: const [
                'Class I',
                'Class II',
                'Class III',
              ],
              onChanged: (v) => setState(() => _upperLipBite = v!),
            ),
            const SizedBox(height: 18),
            _dropdownField(
              label: 'Neck Extension',
              value: _neckExtension,
              items: const [
                'Normal (>35°)',
                'Mildly limited',
                'Severely limited (<15°)',
              ],
              onChanged: (v) => setState(() => _neckExtension = v!),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _presetField(
                    controller: _thyromentalController,
                    label: 'Thyromental (cm)',
                    hint: '> 6.5 cm',
                    options: const [
                      '> 6.5 cm (Normal)',
                      '< 6.5 cm (Short)',
                      '6.0 cm',
                      '7.0 cm',
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _presetField(
                    controller: _sternomentalController,
                    label: 'Sternomental (cm)',
                    hint: '> 12.5 cm',
                    options: const [
                      '> 12.5 cm (Normal)',
                      '< 12.5 cm (Short)',
                      '12.0 cm',
                      '14.0 cm',
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _neckCircController,
              label: 'Neck Circumference (cm)',
              hint: '< 40 cm (Increased risk if > 40 cm)',
              options: const [
                '< 40 cm (Normal)',
                '> 40 cm (High Risk)',
                '38 cm',
                '42 cm',
                '46 cm',
              ],
            ),
          ],
        ),

        // 5. System-Wise Investigations
        _sectionCard(
          title: 'Investigations — System-Wise',
          icon: Icons.biotech_outlined,
          children: [
            _presetField(
              controller: _haematController,
              label: 'Haematology (Hb / Plt / PT / INR / aPTT)',
              hint: 'Hb 13.5, Plt 2.4L, INR 1.0',
              options: const [
                'Hb 13.5, Plt 2.4L, INR 1.0',
                'Normal CBC & Coag',
                'Hb 10.2, Plt 1.8L',
                'Thrombocytopenia (Plt <100k)',
                'Deranged INR (1.6)',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _renalController,
              label: 'Renal (Creatinine / Urea / Electrolytes)',
              hint: 'Creat 0.8, Urea 22, Na 138, K 4.2',
              options: const [
                'Normal (Creat 0.8, Urea 22)',
                'Creat 1.2, K+ 4.2',
                'K+ 3.4 (Mild Hypokalemia)',
                'Creat 2.1, Urea 54 (CKD)',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _hepaticController,
              label: 'Hepatic / LFT (Bilirubin / Enzymes / Albumin)',
              options: const [
                'Normal LFTs (Bili 0.7, SGOT 24, SGPT 28, Alb 4.1)',
                'Mild Transaminitis',
                'Bilirubin 2.4 Elevated',
                'Hypoalbuminemia (Alb 2.8)',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _infectiousController,
              label: 'Infectious / Blood (Viral Markers / TC / DC)',
              options: const [
                'HIV / HBsAg / HCV Non-Reactive',
                'Negative',
                'TC 7,200 Normal',
                'Leukocytosis (TC 14,500)',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _ecgController,
              label: 'ECG (Rate, Rhythm, ST/T changes, Axis)',
              options: const [
                'Normal Sinus Rhythm',
                'Sinus Bradycardia (HR 52)',
                'Sinus Tachycardia (HR 108)',
                'T-Wave Inversion V1-V4',
                'LBBB / RBBB',
                'Atrial Fibrillation',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _echoController,
              label: 'ECHO (LVEF %, RWMA, Valves, PASP)',
              options: const [
                'LVEF >60%, No RWMA, Normal Valves',
                'LVEF 50-55%, Grade 1 Diastolic Dysf.',
                'LVEF 35-40% LV Systolic Dysf.',
                'Severe Aortic Stenosis',
                'Mild MR / TR',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _cxrController,
              label: 'CXR (Infiltrates, Cardiomegaly, Trachea)',
              options: const [
                'Normal Lung Fields & CTR',
                'Clear Lung Fields',
                'Mild Cardiomegaly',
                'Bilateral Basal Infiltrates',
                'Hyperinflated / COPD',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _glucoseController,
              label: 'Metabolic (AC / PC / HbA1c)',
              options: const [
                'RBS Normal (105 mg/dL)',
                'FBS 112, HbA1c 6.4%',
                'HbA1c 7.8% (Suboptimal)',
                'RBS 240 mg/dL',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _tshCortisolController,
              label: 'Endocrine (TSH / Cortisol)',
              options: const [
                'Euthyroid (TSH 2.1 mIU/L)',
                'Hypothyroid on Eltroxin (TSH 4.8)',
                'TSH Elevated (8.4)',
                'Cortisol Normal',
              ],
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _imagingController,
              label: 'Imaging (CT / MRI / Ultrasound)',
              options: const [
                'Not Indicated',
                'CT / MRI Normal',
                'USG Abdomen: Gallstones, no cholecystitis',
                'CT Brain: Intact, no midline shift',
                'Reviewed & Documented',
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // =========================================================================
  // PAGE 2 (BACK): SURGICAL & ANAESTHETIC PLAN & CALCULATORS
  // =========================================================================
  Widget _buildBackPage() {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final age = double.tryParse(_ageController.text.trim()) ?? 0;
    final isOver15 = _ageUnit == 'years' && age > 15;

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Surgical Plan
        _sectionCard(
          title: 'Surgical Plan',
          icon: Icons.healing_outlined,
          children: [
            _presetField(
              controller: _approachController,
              label: 'Approach',
              hint: 'Open / Lap / Robotic',
              options: const [
                'Open',
                'Laparoscopic',
                'Robotic',
                'Endoscopic',
                'Microscopic',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _incisionController,
              label: 'Incision',
              hint: 'Midline / Pfannenstiel',
              options: const [
                'Midline',
                'Pfannenstiel',
                'Subcostal',
                'Lap Ports',
                'Paramedian',
                'Flank',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _positionController,
              label: 'Position',
              hint: 'Supine / Prone',
              options: const [
                'Supine',
                'Prone',
                'Lithotomy',
                'Lateral (L)',
                'Lateral (R)',
                'Trendelenburg',
                'Beach Chair',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _eblController,
              label: 'Est. Blood Loss (EBL)',
              hint: 'e.g. 200 mL',
              options: const [
                'Nil / Minimal',
                '< 100 mL',
                '100 - 300 mL',
                '300 - 500 mL',
                '500 - 1000 mL',
                '> 1000 mL',
              ],
              onOptionSelected: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _estTimeController,
              label: 'Estimated Duration',
              hint: 'e.g. 2 hours',
              options: const [
                '1 hour',
                '1.5 hours',
                '2 hours',
                '3 hours',
                '4+ hours',
              ],
              onOptionSelected: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _ivPlanController,
              label: 'IV Access Plan',
              hint: '2x 16G, Arterial Line',
              options: const [
                '18G Peripheral',
                '2x 16G Large Bore',
                '16G + Arterial Line',
                'CVC + A-Line',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _infusionPumpsController,
              label: 'Infusion Pumps (Vasopressor / TIVA / Insulin)',
              multiSelect: true,
              options: const [
                'None',
                'Noradrenaline',
                'Propofol TIVA',
                'Fentanyl',
                'Dexmedetomidine',
                'Insulin',
                'Vasopressin',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _bgWarmerController,
              label: 'Blood Gas Set + Fluid Warmer / Blanket',
              options: const [
                'Forced Air Blanket (Bair Hugger)',
                'Blood Gas + Fluid Warmer',
                'Bair Hugger + Fluid Warmer',
                'Routine Blankets',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _monitorsController,
              label: 'Monitors',
              multiSelect: true,
              options: const [
                'Standard ASA',
                'Arterial line',
                'CVC line',
                'BIS/Entropy',
                'TOF Monitor',
                'TEE',
                'Temp Probe',
              ],
            ),
          ],
        ),

        // 2. Intubation & Airway Hardware Plan
        _sectionCard(
          title: 'Intubation & Airway Hardware Plan',
          icon: Icons.masks_outlined,
          children: [
            _presetField(
              controller: _ivGasController,
              label: 'Induction Agent',
              hint: 'Propofol / Ketamine',
              options: const [
                'Propofol',
                'Etomidate',
                'Ketamine',
                'Thiopentone',
                'Sevoflurane',
                'Ketofol',
                'Midazolam',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _relaxantController,
              label: 'Muscle Relaxant',
              hint: 'Rocuronium / Atracurium',
              options: const [
                'Rocuronium',
                'Atracurium',
                'Vecuronium',
                'Succinycholine',
                'Cisatracurium',
                'None',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _bladeController,
              label: 'Laryngoscope Blade',
              hint: 'Mac 3 / McCoy / Miller',
              options: const [
                'Macintosh #3',
                'Macintosh #4',
                'McCoy #3 (Levering)',
                'Miller #2 (Straight)',
                'Miller #1 (Paed)',
                'Macintosh #2',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _ettPlanController,
              label: 'Endotracheal Tube (ETT Size & Type)',
              hint: '7.5 Cuffed at 21cm, Reinforced / RAE / Microcuff',
              options: const [
                '7.0 Cuffed (Female)',
                '7.5 Cuffed (Female/Male)',
                '8.0 Cuffed (Male)',
                '8.5 Cuffed (Male)',
                'Reinforced / Armoured',
                'Nasal RAE',
                'Oral RAE',
                'Microcuff Paediatric',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _fobCmacController,
              label: 'Video Laryngoscope / FOB',
              hint: 'C-MAC / GlideScope / FOB',
              options: const [
                'Standard Direct (No VL)',
                'C-MAC (D-Blade)',
                'C-MAC (Mac 3/4)',
                'GlideScope',
                'King Vision',
                'McGrath MAC',
                'Flexible FOB',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _circuitController,
              label: 'Breathing Circuit',
              hint: 'Circle / Bain / Jackson-Rees',
              options: const [
                'Circle System',
                'Bain Circuit',
                'Jackson-Rees / Ayre',
                'Pediatric Bain',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _exchangeCatheterController,
              label: 'Airway Exch. Catheter',
              hint: 'Frova / Cook / Bougie',
              options: const [
                'None',
                'Eschmann Bougie (15F)',
                'Frova Catheter',
                'Cook AEC',
                'Aintree Catheter',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _tappaBlockerController,
              label: 'Bronchial Blocker / DLT',
              hint: 'Tappa / Arndt / Univent',
              options: const [
                'None',
                'Arndt Blocker 9F',
                'Cohen Blocker',
                'EZ-Blocker',
                'Left DLT (35F/37F)',
                'Univent',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _tempProbeController,
              label: 'Temperature Probe Location',
              hint: 'Esophageal / Nasopharyngeal / Tympanic',
              options: const [
                'Esophageal',
                'Nasopharyngeal',
                'Tympanic',
                'Skin / Axillary',
                'Foley / Bladder',
                'Rectal',
                'None',
              ],
            ),
          ],
        ),

                if (!isOver15)
          _sectionCard(
            title: 'Paediatric Medication Doses',
            icon: Icons.medical_services_outlined,
            children: [
              if (weight <= 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Enter patient weight to calculate doses.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                  },
                  border: TableBorder.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  children: [
                    _tableHeader(['Medication (Dose/kg)', 'Calculated Dose']),
                    _tableRow('Propofol (2-3 mg/kg)', '${(weight * 2).toStringAsFixed(1)} - ${(weight * 3).toStringAsFixed(1)} mg'),
                    _tableRow('Fentanyl (1-2 mcg/kg)', '${(weight * 1).toStringAsFixed(1)} - ${(weight * 2).toStringAsFixed(1)} mcg'),
                    _tableRow('Suxamethonium (1-2 mg/kg)', '${(weight * 1).toStringAsFixed(1)} - ${(weight * 2).toStringAsFixed(1)} mg'),
                    _tableRow('Rocuronium (0.6-1.2 mg/kg)', '${(weight * 0.6).toStringAsFixed(1)} - ${(weight * 1.2).toStringAsFixed(1)} mg'),
                    _tableRow('Atracurium (0.5 mg/kg)', '${(weight * 0.5).toStringAsFixed(1)} mg'),
                    _tableRow('Paracetamol (15 mg/kg)', '${(weight * 15).toStringAsFixed(1)} mg'),
                    _tableRow('Ondansetron (0.1 mg/kg)', '${(weight * 0.1 > 4.0 ? 4.0 : weight * 0.1).toStringAsFixed(1)} mg'),
                    _tableRow('Dexamethasone (0.15 mg/kg)', '${(weight * 0.15 > 8.0 ? 8.0 : weight * 0.15).toStringAsFixed(1)} mg'),
                    _tableRow('Glycopyrrolate (10 mcg/kg)', '${(weight * 10).toStringAsFixed(1)} mcg'),
                    _tableRow('Neostigmine (50 mcg/kg)', '${(weight * 50).toStringAsFixed(1)} mcg'),
                    _tableRow('Sugammadex (2-4 mg/kg)', '${(weight * 2).toStringAsFixed(1)} - ${(weight * 4).toStringAsFixed(1)} mg'),
                  ],
                ),
            ],
          ),
          
        // 3. Paediatric Tube Sizing & Ventilation Formulas (Hidden for patients > 15 years)
        if (!isOver15)
          _sectionCard(
            title: 'Paediatric Ventilation & Tube Sizing',
            icon: Icons.child_care_outlined,
          children: [
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(2),
              },
              border: TableBorder.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.6),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text('Parameter',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text('Formula',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text('Calculated',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                _calcRow(
                  'Tidal Volume',
                  '8 - 12 mL/kg',
                  weight > 0
                      ? '${(weight * 8).round()} - ${(weight * 12).round()} mL'
                      : '--',
                ),
                _calcRow(
                  'Cuffed ID (Duracher)',
                  'Age/4 + 3.5',
                  age > 0 ? (age / 4 + 3.5).toStringAsFixed(1) : '--',
                ),
                _calcRow(
                  'Penlington (<6.5 yr)',
                  'Age/4 + 4.5',
                  age > 0 ? (age / 4 + 4.5).toStringAsFixed(1) : '--',
                ),
                _calcRow(
                  'Penlington (>6.5 yr)',
                  'Age/3 + 3.5',
                  age > 0 ? (age / 3 + 3.5).toStringAsFixed(1) : '--',
                ),
                _calcRow(
                  'Depth of Insertion',
                  'Age/2 + 12 cm',
                  age > 0 ? '${(age / 2 + 12).toStringAsFixed(1)} cm' : '--',
                ),
              ],
            ),
          ],
        ),

        // 4. Blood Loss Plan
        _sectionCard(
          title: 'Blood Loss & Transfusion Plan',
          icon: Icons.water_drop_outlined,
          children: [
            _presetField(
              controller: _baselineHbController,
              label: 'Baseline Hb (Hb₀)',
              hint: '12 g/dL',
              keyboardType: TextInputType.number,
              options: const ['10', '11', '12', '13', '14'],
              onOptionSelected: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _targetHbController,
              label: 'Target Min Hb',
              hint: '10 g/dL',
              keyboardType: TextInputType.number,
              options: const ['7', '8', '9', '10'],
              onOptionSelected: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _bloodOrderedController,
              label: 'Blood Ordered / Cross-Matched',
              hint: 'e.g. 2 Units PRBC, 2 Units FFP',
              options: const [
                'Type & Screen (T&S)',
                'Cross-match 2 Units PRBC',
                '2 Units PRBC + 2 FFP',
                '4 PRBC + 4 FFP + 1 Plt',
                'Nil / Hold',
              ],
            ),
            const SizedBox(height: 24),
            _buildBloodCalculations(weight),
          ],
        ),

        // 5. Fluid Balance Plan (4-2-1 rule & deficit replacement)
        _sectionCard(
          title: 'Fluid Balance Plan (4-2-1 Rule)',
          icon: Icons.opacity_outlined,
          children: [
            _presetField(
              controller: _npoHoursController,
              label: 'Fasting (NPO Hours)',
              keyboardType: TextInputType.number,
              options: const [
                '2 hrs (Clear)',
                '6 hrs (Light)',
                '8 hrs (Solid)',
                '10 hrs',
                '12 hrs',
              ],
              onOptionSelected: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _thirdSpaceRateController,
              label: 'Third-Space (mL/kg/hr)',
              hint: '2 - 6 mL/kg/hr',
              keyboardType: TextInputType.number,
              options: const [
                '2 (Minimal)',
                '4 (Moderate)',
                '6 (Severe)',
                '8 (Major)',
              ],
              onOptionSelected: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _estTimeController,
              label: 'Estimated Duration of Surgery',
              hint: 'e.g. 1 hr 30 mins, 2 hours',
              options: const [
                '1 hour',
                '1 hr 30 mins',
                '2 hours',
                '2 hr 30 mins',
                '3 hours',
                '4+ hours',
              ],
              onOptionSelected: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            _presetField(
              controller: _eblController,
              label: 'Estimated Blood Loss (EBL)',
              hint: 'e.g. 200 mL',
              options: const [
                'Nil / Minimal',
                '< 100 mL',
                '100 - 300 mL',
                '300 - 500 mL',
                '500 - 1000 mL',
                '> 1000 mL',
              ],
              onOptionSelected: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  'Blood Replacement:',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ChoiceChip(
                  label: const Text('3:1 Crystalloid',
                      style: TextStyle(fontSize: 11)),
                  selected: _fluidBloodRatio == 3.0,
                  onSelected: (sel) {
                    if (sel) setState(() => _fluidBloodRatio = 3.0);
                  },
                  visualDensity: VisualDensity.compact,
                ),
                ChoiceChip(
                  label: const Text('1:1 Colloid/Blood',
                      style: TextStyle(fontSize: 11)),
                  selected: _fluidBloodRatio == 1.0,
                  onSelected: (sel) {
                    if (sel) setState(() => _fluidBloodRatio = 1.0);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFluidGrid(weight),
          ],
        ),

        // 6. Postoperative Disposition & Analgesia
        _sectionCard(
          title: 'Postoperative Stay & Analgesia Plan',
          icon: Icons.hotel_outlined,
          children: [
            _presetField(
              controller: _dispositionController,
              label: 'Disposition / Stay',
              options: const [
                'PACU -> Daycare / Ward',
                'PACU -> Inpatient Ward',
                'HDU Monitoring (24 hrs)',
                'Surgical ICU (Extubated)',
                'Surgical ICU (Intubated)',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _analgesiaPlanController,
              label: 'Analgesia Plan (PCA / Epidural / Blocks)',
              hint: 'Tap presets to append multimodal components',
              multiSelect: true,
              maxLines: 2,
              options: const [
                'Multimodal (IV Paracetamol + NSAID + Tramadol)',
                'Patient-Controlled Analgesia (PCA)',
                'Epidural (+ Catheter)',
                'Epidural Infusion (Bupi + Fent)',
                'Regional Block (+ Catheter)',
                'Regional / Plane Block (TAP / ESP / PENG)',
                'IV PCA (Morphine / Fentanyl)',
                'Local Infiltration (LIA)',
              ],
            ),
            const SizedBox(height: 24),
            _presetField(
              controller: _intraopNotesController,
              label: 'Intraoperative & Clinical Notes',
              hint: 'Tap presets to append notes or type freely',
              multiSelect: true,
              maxLines: 4,
              options: const [
                'Induction uneventful',
                'Grade 1 view on laryngoscopy',
                'Hemodynamically stable throughout',
                'Reversal given (Neostigmine + Glyco)',
                'Smooth extubation on table',
                'Transferred safely to PACU',
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // =========================================================================
  // HELPER WIDGETS & CALCULATIONS (GLASSMORPHISM & PRESETS)
  // =========================================================================

  double _parseLeadingNumber(String text, double fallback) {
    if (text.trim().isEmpty) return fallback;
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(text.trim());
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? fallback;
    }
    return fallback;
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            Divider(
              height: 28,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            ...children,
          ],
        ),
      ),
    ),
    ),
    ),
    );
  }

  Widget _vitalSlider({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required double fallbackDefault,
    required double min,
    required double max,
    int? divisions,
    required String unit,
    required Color accentColor,
    List<String> quickPresets = const [],
    bool isDecimal = false,
  }) {
    final hasExplicitValue = controller.text.trim().isNotEmpty;
    final currentVal =
        _parseLeadingNumber(controller.text, fallbackDefault).clamp(min, max);
    final displayStr = hasExplicitValue
        ? (isDecimal
            ? '${currentVal.toStringAsFixed(1)} $unit'
            : (unit == '%'
                ? '${currentVal.toInt()}%'
                : '${currentVal.toInt()} $unit'))
        : (isDecimal
            ? '${fallbackDefault.toStringAsFixed(1)} $unit'
            : (unit == '%'
                ? '${fallbackDefault.toInt()}%'
                : '${fallbackDefault.toInt()} $unit'));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSolid.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasExplicitValue
              ? accentColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasExplicitValue
                      ? accentColor.withValues(alpha: 0.20)
                      : AppTheme.surfaceLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasExplicitValue
                        ? accentColor.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  displayStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        hasExplicitValue ? accentColor : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppTheme.textSecondary,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: widget.isReadOnly
                    ? null
                    : () {
                        final step = isDecimal ? 0.1 : 1.0;
                        final newVal = (currentVal - step).clamp(min, max);
                        setState(() {
                          controller.text = isDecimal
                              ? newVal.toStringAsFixed(1)
                              : (unit == '%'
                                  ? '${newVal.toInt()}%'
                                  : newVal.toInt().toString());
                        });
                      },
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    inactiveTrackColor:
                        Colors.white.withValues(alpha: 0.15),
                    thumbColor: accentColor,
                    overlayColor: accentColor.withValues(alpha: 0.20),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: currentVal,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: widget.isReadOnly
                        ? null
                        : (v) {
                            setState(() {
                              controller.text = isDecimal
                                  ? v.toStringAsFixed(1)
                                  : (unit == '%'
                                      ? '${v.toInt()}%'
                                      : v.toInt().toString());
                            });
                          },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppTheme.textSecondary,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: widget.isReadOnly
                    ? null
                    : () {
                        final step = isDecimal ? 0.1 : 1.0;
                        final newVal = (currentVal + step).clamp(min, max);
                        setState(() {
                          controller.text = isDecimal
                              ? newVal.toStringAsFixed(1)
                              : (unit == '%'
                                  ? '${newVal.toInt()}%'
                                  : newVal.toInt().toString());
                        });
                      },
              ),
            ],
          ),
          if (quickPresets.isNotEmpty && !widget.isReadOnly) ...[
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: quickPresets.map((opt) {
                  final isSelected = controller.text.trim().toLowerCase() ==
                          opt.toLowerCase() ||
                      _parseLeadingNumber(controller.text, -1) ==
                          _parseLeadingNumber(opt, -2);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          controller.text = opt;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.25)
                              : AppTheme.surfaceSolid.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? accentColor
                                : Colors.white.withValues(alpha: 0.10),
                            width: isSelected ? 1.0 : 0.6,
                          ),
                        ),
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? accentColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: !widget.isReadOnly,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        hintStyle: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 12),
        filled: true,
        fillColor: AppTheme.surfaceSolid.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isExpanded = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSolid.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: isExpanded,
              dropdownColor: AppTheme.surfaceSolid,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              icon: Icon(Icons.arrow_drop_down,
                  color: AppTheme.textSecondary, size: 20),
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: widget.isReadOnly ? null : onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipOptions({
    required TextEditingController controller,
    required List<String> options,
    bool multiSelect = false,
    VoidCallback? onSelectionChanged,
  }) {
    if (widget.isReadOnly) return const SizedBox.shrink();
    final currentText = controller.text;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: options.map((opt) {
            final isSelected = multiSelect
                ? currentText
                    .split(',')
                    .map((e) => e.trim().toLowerCase())
                    .any((e) {
                      final o = opt.toLowerCase();
                      if (e == o) return true;
                      if (o == 'standard asa' && e.contains('standard asa')) return true;
                      if (o == 'arterial line' && (e.contains('arterial') || e.contains('a-line'))) return true;
                      if (o == 'cvc line' && (e.contains('cvc') || e.contains('central'))) return true;
                      if (o == 'bis/entropy' && (e.contains('bis') || e.contains('entropy'))) return true;
                      return false;
                    })
                : currentText.trim().toLowerCase() == opt.toLowerCase();

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (multiSelect) {
                      final list = currentText
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      final idx = list.indexWhere(
                          (e) => e.toLowerCase() == opt.toLowerCase());
                      if (idx >= 0) {
                        list.removeAt(idx);
                      } else {
                        list.add(opt);
                      }
                      controller.text = list.join(', ');
                    } else {
                      if (isSelected) {
                        controller.clear();
                      } else {
                        controller.text = opt;
                      }
                    }
                    onSelectionChanged?.call();
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.25)
                        : AppTheme.surfaceSolid.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.10),
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(Icons.check, size: 11, color: AppTheme.primary),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _presetField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    String? hint,
    bool multiSelect = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    VoidCallback? onOptionSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField(
          controller: controller,
          label: label,
          hint: hint,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
        _chipOptions(
          controller: controller,
          options: options,
          multiSelect: multiSelect,
          onSelectionChanged: () {
            onChanged?.call(controller.text);
            onOptionSelected?.call();
          },
        ),
      ],
    );
  }


  TableRow _calcRow(String label, String formula, String calc) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
          child: Text(label,
              style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
          child: Text(formula,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
          child: Text(
            calc,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  String _fmtVal(double v) {
    if (v >= 100) return v.round().toString();
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  Widget _buildBloodCalculations(double weight) {
    if (weight <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: AppTheme.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enter patient weight on Tab 1 to calculate Estimated Blood Volume (EBV) and Maximum Allowable Blood Loss.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final double ebvFactor = _gender == 'Female' ? 65 : 70;
    final double ebv = weight * ebvFactor;
    final double hb0 = double.tryParse(_baselineHbController.text.trim()) ?? 12;
    final double hbTarget =
        double.tryParse(_targetHbController.text.trim()) ?? 10;
    final double hbAv = (hb0 + hbTarget) / 2;

    double mabl = 0;
    if (hbAv > 0 && hb0 > hbTarget) {
      mabl = (ebv * (hb0 - hbTarget)) / hbAv;
    }

    final double twentyPercentEbv = ebv * 0.2;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bloodStatRow(
            label: 'Estimated Blood Volume (EBV)',
            value: '${ebv.round()} mL',
            detail: '${ebvFactor.round()} mL/kg for $_gender ($weight kg)',
            valueColor: Colors.white,
          ),
          Divider(
            height: 14,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _bloodStatRow(
            label: '20% EBV Loss Limit',
            value: '${twentyPercentEbv.round()} mL',
            detail: 'Initial fluid resuscitation threshold',
            valueColor: Colors.white,
          ),
          Divider(
            height: 14,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _bloodStatRow(
            label: 'Allowable Blood Loss (MABL)',
            value: '${mabl.round()} mL',
            detail: 'Target minimum Hb: $hbTarget g/dL',
            valueColor: AppTheme.primary,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _bloodStatRow({
    required String label,
    required String value,
    String? detail,
    required Color valueColor,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isHighlight
                ? AppTheme.primary.withValues(alpha: 0.2)
                : AppTheme.surfaceSolid.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlight
                  ? AppTheme.primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  double _parseBloodLoss(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty || t.contains('nil') || t.contains('none') || t == '0') {
      return 0.0;
    }
    if (t.contains('100 - 300') || t.contains('100-300')) return 200.0;
    if (t.contains('300 - 500') || t.contains('300-500')) return 400.0;
    if (t.contains('500 - 1000') || t.contains('500-1000')) return 750.0;
    if (t.contains('< 100') || t.contains('<100')) return 50.0;
    if (t.contains('> 1000') || t.contains('>1000')) return 1000.0;

    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(t);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  double _parseDuration(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return 2.0;

    // 1. Combined hours and minutes: e.g. "1 hr and 30mins", "1 hr 30 mins", "1h 30m", "1 hour 30 min"
    final hrMinMatch = RegExp(
            r'(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b[^\d]*(\d+(?:\.\d+)?)\s*(?:minutes?|mins?|m)\b')
        .firstMatch(t);
    if (hrMinMatch != null) {
      final h = double.tryParse(hrMinMatch.group(1)!) ?? 0.0;
      final m = double.tryParse(hrMinMatch.group(2)!) ?? 0.0;
      final total = h + (m / 60.0);
      if (total > 0) return total.clamp(0.25, 24.0);
    }

    // 2. Colon format: e.g. "1:30", "02:15"
    final colonMatch = RegExp(r'(\d+):(\d{2})').firstMatch(t);
    if (colonMatch != null) {
      final h = double.tryParse(colonMatch.group(1)!) ?? 0.0;
      final m = double.tryParse(colonMatch.group(2)!) ?? 0.0;
      final total = h + (m / 60.0);
      if (total > 0) return total.clamp(0.25, 24.0);
    }

    // 3. Spoken fractions: e.g. "1 and a half", "2 1/2"
    if (t.contains('half') || t.contains('1/2')) {
      final leadMatch = RegExp(r'(\d+)').firstMatch(t);
      final lead = leadMatch != null
          ? double.tryParse(leadMatch.group(1)!) ?? 0.0
          : 0.0;
      return (lead + 0.5).clamp(0.25, 24.0);
    }

    // 4. Quick decimal checks
    if (t.contains('1.5')) return 1.5;
    if (t.contains('2.5')) return 2.5;
    if (t.contains('3.5')) return 3.5;
    if (t.contains('4+') || t.contains('4.5')) return 4.0;

    // 5. Minutes only without hours: e.g. "90 mins", "45 min", "30 min"
    if ((t.contains('min') || t.endsWith('m')) &&
        !t.contains('hr') &&
        !t.contains('hour') &&
        !t.contains('h')) {
      final minMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(t);
      if (minMatch != null) {
        final m = double.tryParse(minMatch.group(1)!) ?? 0.0;
        if (m > 0) return (m / 60.0).clamp(0.25, 24.0);
      }
    }

    // 6. Decimal or simple number: e.g. "1 hour", "2 hrs", "3"
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(t);
    if (match != null) {
      final val = double.tryParse(match.group(1)!) ?? 2.0;
      if (t.contains('min') && !t.contains('hr') && !t.contains('hour')) {
        return (val / 60.0).clamp(0.25, 24.0);
      }
      return val > 0 ? val.clamp(0.25, 24.0) : 2.0;
    }

    return 2.0;
  }

  String _ordinal(int i) {
    switch (i) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${i}th';
    }
  }

  Widget _buildFluidGrid(double weight) {
    if (weight <= 0) {
      return Text(
        'Enter patient weight to calculate hourly maintenance and fasting deficit replacement.',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      );
    }

    // 4-2-1 Rule
    double maintPerHour = 0;
    if (weight <= 10) {
      maintPerHour = weight * 4;
    } else if (weight <= 20) {
      maintPerHour = 40 + (weight - 10) * 2;
    } else {
      maintPerHour = 60 + (weight - 20) * 1;
    }

    final double npoHours = _parseLeadingNumber(_npoHoursController.text, 6.0);
    final double totalDeficit = maintPerHour * npoHours;
    final double thirdSpaceRate =
        _parseLeadingNumber(_thirdSpaceRateController.text, 4.0);
    final double thirdSpacePerHour = weight * thirdSpaceRate;

    final double duration = _parseDuration(_estTimeController.text);
    final double ebl = _parseBloodLoss(_eblController.text);
    final double totalBloodRepl = ebl * _fluidBloodRatio;
    final double bloodReplPerHour =
        duration > 0 ? (totalBloodRepl / duration) : 0.0;

    final int numRows = duration.ceil().clamp(1, 8);
    final List<TableRow> tableRows = [];

    // Header row
    tableRows.add(
      TableRow(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withValues(alpha: 0.6),
        ),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Hr',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Deficit',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Maint',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('3rd Sp.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Blood',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Total',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Cumul.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ],
      ),
    );

    double runningCumul = 0;
    double totalIntraopDeficit = 0;
    double totalIntraopMaint = 0;
    double totalIntraopThirdSpace = 0;
    double totalIntraopBlood = 0;

    for (int i = 1; i <= numRows; i++) {
      final double fraction;
      if (i < duration.ceil()) {
        fraction = 1.0;
      } else {
        final remainder = duration - (i - 1);
        fraction = remainder > 0 ? remainder.clamp(0.1, 1.0) : 1.0;
      }

      final double dPct = i == 1 ? 0.50 : (i == 2 || i == 3 ? 0.25 : 0.0);
      final double dHr = totalDeficit * dPct * fraction;
      final double mHr = maintPerHour * fraction;
      final double tHr = thirdSpacePerHour * fraction;
      final double bHr = bloodReplPerHour * fraction;
      final double totHr = dHr + mHr + tHr + bHr;
      runningCumul += totHr;

      totalIntraopDeficit += dHr;
      totalIntraopMaint += mHr;
      totalIntraopThirdSpace += tHr;
      totalIntraopBlood += bHr;

      final String hrLabel;
      if (fraction < 1.0) {
        final mins = (fraction * 60).round();
        hrLabel = '${_ordinal(i)} (${mins}m)';
      } else {
        hrLabel = _ordinal(i);
      }

      tableRows.add(_fluidRow(
        hrLabel,
        dHr,
        mHr,
        tHr,
        bHr,
        totHr,
        runningCumul,
      ));
    }

    final minUrine = (weight * 0.5).toStringAsFixed(0);
    final maxUrine = (weight * 1.0).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                'Fasting: ${npoHours.toStringAsFixed(0)}h (${totalDeficit.round()} mL def.)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                'Maint: ${maintPerHour.round()} mL/hr',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '3rd Sp: ${thirdSpacePerHour.round()} mL/hr',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'Duration: ${duration % 1 == 0 ? duration.toInt() : duration}h',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              if (ebl > 0)
                Text(
                  'EBL: ${ebl.round()} mL (${totalBloodRepl.round()} mL repl.)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Target Urine: $minUrine - $maxUrine mL/hr (0.5 - 1.0 mL/kg/hr)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                '(Values in mL)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(0.9),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.1),
            3: FlexColumnWidth(1.1),
            4: FlexColumnWidth(1.1),
            5: FlexColumnWidth(1.2),
            6: FlexColumnWidth(1.3),
          },
          border: TableBorder.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
          children: tableRows,
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total Intraop Fluid (${duration % 1 == 0 ? duration.toInt() : duration.toStringAsFixed(1)}h surgery):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${runningCumul.round()} mL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text('• Maint: ${totalIntraopMaint.round()} mL',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  Text('• Deficit: ${totalIntraopDeficit.round()} mL',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  Text('• 3rd Space: ${totalIntraopThirdSpace.round()} mL',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  if (totalIntraopBlood > 0)
                    Text(
                        '• Blood Repl (${_fluidBloodRatio.toInt()}:1): ${totalIntraopBlood.round()} mL',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.warning)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _fluidRow(String hr, double deficit, double maint, double thirdSpace,
      double blood, double total, double cumul) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(hr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${deficit.round()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${maint.round()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${thirdSpace.round()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${blood.round()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color:
                        blood > 0 ? AppTheme.warning : AppTheme.textSecondary)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${total.round()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${cumul.round()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}



