import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/case_record.dart';
import '../services/case_storage.dart';
import '../services/follow_up_service.dart';
import '../services/profile_storage.dart';
import '../services/achievement_service.dart';
import '../services/achievement_notification_service.dart';
import '../services/template_storage.dart';
import '../data/medical_suggestions.dart';
import 'templates_screen.dart';
import '../widgets/animated_gradient_background.dart';

class NewCaseScreen extends StatefulWidget {
  final CaseRecord? existingCase;
  const NewCaseScreen({super.key, this.existingCase});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _caseNumberController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _procedureController = TextEditingController();
  final _notesController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _specialtyOtherController = TextEditingController();
  final _airwayAttemptsController = TextEditingController();
  final _ettSizeController = TextEditingController();
  final _lmaSizeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _anaesthesiaStart;
  TimeOfDay? _anaesthesiaEnd;
  String? _anaesthesiaDuration;
  TimeOfDay? _surgeryStart;
  TimeOfDay? _surgeryEnd;
  String? _surgeryDuration;

  String _priority = 'Elective';
  String _asaGrade = 'ASA I';
  String _specialty = 'General Surgery';
  String _technique = 'General Anaesthesia (VA)';
  String _role = 'Consultant';
  String _gender = 'Male';
  String _airway = 'Not applicable';
  String _cormack = 'Not graded';
  String _ageUnit = 'years';
  bool _difficultAirway = false;
  String? _imagePath;
  String? _hospitalFromProfile;
  double? _bmi;

  String? _typeOfIntubation;
  String? _methodOfIntubation;
  String? _methodOfIntubationRole;
  String? _ettType;
  String? _lmaType;
  String? _lmaRole;

  final List<Map<String, dynamic>> _invasiveList = [];
  final List<Map<String, dynamic>> _regionalList = [];
  bool _flagForFollowUp = false;
  bool _catheterPlaced = false;

  final List<String> _selectedComplications = [];
  String? _selectedOutcome;

  List<String> _diagnosisSuggestions = [];
  List<String> _procedureSuggestions = [];

  final List<String> _priorities = ['Elective', 'Emergency'];
  final List<String> _asaGrades = ['ASA I', 'ASA II', 'ASA III', 'ASA IV', 'ASA V'];
  final List<String> _ageUnits = ['years', 'months', 'days'];
  final List<String> _specialties = [
    'General Surgery',
    'Orthopaedics',
    'Paediatric Ortho',
    'Spine Surgery',
    'Obstetrics',
    'Gynaecology',
    'Reproductive Medicine Unit (RMU)',
    'Gynae-oncology',
    'ENT',
    'Urology',
    'Neurosurgery',
    'Cardiology',
    'Cardiothoracic',
    'Paediatric cardiac surgery',
    'Plastic Surgery',
    'Hand and reconstructive surgery',
    'Paediatric Surgery',
    'Trauma Surgery',
    'Vascular surgery',
    'Head and Neck Surgery',
    'Dental/Maxillofacial surgery',
    'HPB Surgery',
    'Upper GI Surgery',
    'Colorectal Surgery',
    'Endocrine Surgery',
    'Bariatric surgery',
    'Ophthalmology',
    'MRI/DSA/NORA',
    'Interventional Radiology',
    'Radiotherapy',
    'Acute/Chronic Pain Intervention',
    'Transplant surgery',
    'Other',
  ];
  final List<String> _techniques = [
    'General Anaesthesia (VA)',
    'General Anaesthesia (TIVA)',
    'Spinal (SAB)',
    'Epidural',
    'Combined Spinal-Epidural (CSE)',
    'Peripheral Nerve Block',
    'Sedation / MAC',
    'Local Only',
  ];
  final List<String> _roles = [
    'Consultant',
    'Senior Registrar / Fellow',
    'Registrar',
    'SHO / Junior Resident',
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _airways = [
    'Not applicable',
    'Endotracheal Tube (ETT)',
    'Double lumen tube (DLT)',
    'Bronchial blocker',
    'Laryngeal Mask Airway (LMA)',
    'Jet ventilation',
    'Facemask only',
    'Tracheostomy',
    'Other',
  ];
  final List<String> _cormackGrades = [
    'Not graded',
    'Grade 1',
    'Grade 2a',
    'Grade 2b',
    'Grade 3',
    'Grade 4',
  ];
  final List<String> _intubationTypes = [
    'Oral intubation',
    'Nasal intubation',
    'Submental intubation',
  ];
  final List<String> _intubationMethods = [
    'Direct Laryngoscopy',
    'Video laryngoscopy',
    'Awake fiberoptic intubation',
    'Asleep fiberoptic intubation',
  ];
  final List<String> _intubationRoles = ['Performed', 'Assisted', 'Observed'];
  final List<String> _ettTypesAll = [
    'Regular cuffed ETT',
    'Regular uncuffed ETT',
    'Microcuff ETT',
    'Nasal ETT',
    'RAE tube',
    'Flexometallic tube',
  ];
  final List<String> _ettTypesNasalOnly = ['Nasal ETT', 'RAE tube'];
  final List<String> _lmaTypes = [
    'Classic LMA',
    'ProSeal LMA',
    'i-gel LMA',
    'Ambu LMA',
    'Supreme LMA',
    'C-Trach LMA',
    'Flexible LMA',
    'Fastrach LMA',
  ];
  final List<String> _invasiveOptions = [
    'Arterial line',
    'CVC line',
    'PA catheter',
    'Lumbar Subarachnoid drain',
    'BIS/Entropy',
    'Masimo SedLine',
    'NIRS',
    'TEE',
    'PiCCO monitor',
    'TCI pump',
  ];
  final List<String> _lineRoles = ['Performed', 'Assisted', 'Observed'];
  final List<String> _monitorRoles = [
    'Used independently',
    'Used with assistance',
    'Observed',
  ];
  final Set<String> _monitorDevices = {
    'BIS/Entropy',
    'Masimo SedLine',
    'NIRS',
    'PiCCO monitor',
    'TCI pump',
  };
  final List<String> _complicationOptions = [
    'Multiple intubation attempts',
    'Failed intubation',
    'Difficult mask ventilation',
    'Aspiration',
    'Hypotension',
    'Hypertension',
    'Arrhythmia',
    'Bronchospasm',
    'Laryngospasm',
    'Desaturation',
    'Pneumothorax',
    'Venous air embolism',
    'Bleeding',
    'Massive blood loss',
    'Transfusion reaction',
    'Hypothermia',
    'Shivering',
    'Position related complications',
    'Cardiac arrest',
    'Death on table',
    'Post-op nausea and vomiting (PONV)',
    'High spinal/Bradycardia',
    'None/uneventful',
  ];
  final List<String> _outcomeOptions = [
    'Uneventful PACU discharge',
    'PACU extended monitoring',
    'ICU transfer intubated',
    'HDU transfer',
    'Other/Unspecified',
  ];
  final List<String> _regionalOptions = [
    'None / Not performed',
    'Spinal (SAB)',
    'Epidural',
    'Interscalene block',
    'Supraclavicular block',
    'Infraclavicular block',
    'Axillary block',
    'Femoral nerve block',
    'Fascia Iliaca plane block',
    'Adductor canal block',
    'Sciatic nerve block (transgluteal)',
    'Sciatic nerve block (popliteal)',
    'Sciatic nerve block (anterior)',
    'Psoas subfascial plane block',
    'Ankle block',
    'TAP block (Transversus Abdominis Plane)',
    'Rectus sheath block',
    'QL block (Quadratus Lumborum)',
    'ESP block (Erector Spinae Plane)',
    'PECS I / PECS II block',
    'Serratus anterior plane block',
    'Paravertebral block',
    'Cervical plexus block',
    'Scalp block',
    'Bier block (IVRA)',
    'Caudal block',
    'Lumbar plexus block',
    'Sacral plexus block',
    'Other peripheral nerve block',
  ];
  final Set<String> _noUsgBlocks = {'Spinal (SAB)', 'Epidural', 'None / Not performed'};

  bool get _isSpinalTechnique =>
      _technique == 'Spinal (SAB)' ||
          _technique == 'Epidural' ||
          _technique == 'Combined Spinal-Epidural (CSE)';

  bool get _showCatheterOption {
    if (_regionalList.isEmpty) return false;
    if (_regionalList.length == 1 &&
        _regionalList.first['name'] == 'None / Not performed') {
      return false;
    }
    return true;
  }

  bool get _isOtherSpecialty => _specialty == 'Other';
  bool get _isDLT => _airway == 'Double lumen tube (DLT)';
  bool get _isTubeAirway =>
      _airway == 'Endotracheal Tube (ETT)' ||
          _airway == 'Double lumen tube (DLT)' ||
          _airway == 'Bronchial blocker';
  bool get _isLma => _airway == 'Laryngeal Mask Airway (LMA)';
  bool get _isETT => _airway == 'Endotracheal Tube (ETT)';
  bool get _isNasalIntubation => _typeOfIntubation == 'Nasal intubation';
  bool get _showEttType => _isETT || _airway == 'Bronchial blocker';

  List<String> get _availableIntubationTypes {
    if (_isDLT) return ['Oral intubation'];
    return _intubationTypes;
  }

  List<String> get _availableEttTypes {
    if (_isNasalIntubation) return _ettTypesNasalOnly;
    // Oral / Submental: Nasal ETT cannot be chosen
    return _ettTypesAll.where((e) => e != 'Nasal ETT').toList();
  }

  List<String> _rolesForInvasive(String name) =>
      _monitorDevices.contains(name) ? _monitorRoles : _lineRoles;

  @override
  void initState() {
    super.initState();
    _loadProfileHospital();
    _loadSuggestions();
    _loadExistingCase();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraftIfAny());
  }

  Future<void> _loadProfileHospital() async {
    final profile = await ProfileStorage.getProfile();
    setState(() {
      _hospitalFromProfile = profile.hospital.isNotEmpty ? profile.hospital : null;
    });
  }

  Future<void> _loadSuggestions() async {
    final cases = await CaseStorage.getAllCases();
    final customDiagnoses = cases.map((c) => c.diagnosis).where((d) => d.trim().isNotEmpty);
    final customProcedures = cases.map((c) => c.procedure).where((p) => p.trim().isNotEmpty);

    final allDiagnoses = {...customDiagnoses, ...CommonMedicalSuggestions.diagnoses}.toList();
    final allProcedures = {...customProcedures, ...CommonMedicalSuggestions.procedures}.toList();

    setState(() {
      _diagnosisSuggestions = allDiagnoses;
      _procedureSuggestions = allProcedures;
    });
  }

  void _loadExistingCase() {
    final c = widget.existingCase;
    if (c == null) return;
    _flagForFollowUp = c.flagForFollowUp;

    _caseNumberController.text = c.caseNumber;
    _diagnosisController.text = c.diagnosis;
    _procedureController.text = c.procedure;
    _notesController.text = c.notes ?? '';
    _ageController.text = c.patientAge?.toString() ?? '';
    _weightController.text = c.patientWeight?.toString() ?? '';
    _heightController.text = c.patientHeight?.toString() ?? '';
    _supervisorController.text = c.supervisor ?? '';
    _specialtyOtherController.text = c.specialtyOther ?? '';
    _airwayAttemptsController.text = c.difficultAirwayAttempts?.toString() ?? '';
    _ettSizeController.text = c.ettSize?.toString() ?? '';
    _lmaSizeController.text = c.lmaSize?.toString() ?? '';
    _selectedDate = c.date;
    _priority = c.priority;
    _asaGrade = c.asaGrade;
    _specialty = _specialties.contains(c.specialty) ? c.specialty : 'Other';
    if (!_specialties.contains(c.specialty) && c.specialty.isNotEmpty) {
      _specialtyOtherController.text = c.specialty;
    }
    if (c.specialty.contains('Hand and Leprosy') || c.specialty.contains('HLRS')) {
      _specialty = 'Hand and reconstructive surgery';
    }
    _technique = c.technique;
    if (_technique == 'General Anaesthesia (GA)' ||
        _technique == 'General Anaesthesia (Volatile Anaesthesia)') {
      _technique = 'General Anaesthesia (VA)';
    }
    if (_technique == 'Regional Anaesthesia') {
      _technique = 'Peripheral Nerve Block';
    }
    if (!_techniques.contains(_technique)) {
      _technique = 'General Anaesthesia (VA)';
    }
    _role = c.role;
    _gender = c.patientGender ?? 'Male';
    _airway = c.airwayManagement ?? 'Not applicable';
    _cormack = c.cormackLehane ?? 'Not graded';
    _ageUnit = c.ageUnit;
    _difficultAirway = c.difficultAirway;
    _imagePath = c.caseSheetImagePath;
    _bmi = c.bmi;
    _typeOfIntubation = c.typeOfIntubation;
    _methodOfIntubation = c.methodOfIntubation;
    _methodOfIntubationRole = c.methodOfIntubationRole;
    _ettType = c.ettType;
    _lmaType = c.lmaType;
    _lmaRole = c.lmaRole;
    _invasiveList.addAll(c.invasiveMonitoring.map((e) => Map<String, dynamic>.from(e)));
    _regionalList.addAll(c.regionalBlocks.map((e) => Map<String, dynamic>.from(e)));
    _selectedComplications.addAll(c.complications);
    _catheterPlaced = c.catheterPlaced;
    _selectedOutcome = c.outcome;
    _anaesthesiaDuration = c.anaesthesiaDuration;
    _surgeryDuration = c.surgeryDuration;
    _anaesthesiaStart = _parseTime(c.anaesthesiaStartTime);
    _anaesthesiaEnd = _parseTime(c.anaesthesiaEndTime);
    _surgeryStart = _parseTime(c.surgeryStartTime);
    _surgeryEnd = _parseTime(c.surgeryEndTime);

    if (_isDLT) {
      _typeOfIntubation = 'Oral intubation';
      _ettType = null;
    }
    if (_isNasalIntubation &&
        (_ettType == null || !_ettTypesNasalOnly.contains(_ettType))) {
      _ettType = 'Nasal ETT';
    }
  }

  TimeOfDay? _parseTime(String? t) {
    if (t == null) return null;
    final parts = t.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    _diagnosisController.dispose();
    _procedureController.dispose();
    _notesController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _supervisorController.dispose();
    _specialtyOtherController.dispose();
    _airwayAttemptsController.dispose();
    _ettSizeController.dispose();
    _lmaSizeController.dispose();
    // Fire-and-forget draft save when leaving the screen
    // ignore: unawaited_futures
    _autosaveDraft();
    super.dispose();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _recalculateBmi() {
    final w = double.tryParse(_weightController.text.trim());
    final h = double.tryParse(_heightController.text.trim());
    if (w != null && h != null && h > 0) {
      final m = h / 100.0;
      setState(() => _bmi = w / (m * m));
    } else {
      setState(() => _bmi = null);
    }
  }

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  int _rel(TimeOfDay t, TimeOfDay origin) {
    var m = _mins(t);
    final o = _mins(origin);
    if (m < o) m += 24 * 60;
    return m;
  }

  String? _calcDuration(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return null;
    final a = _mins(start);
    var e = _mins(end);
    if (e < a) e += 24 * 60;
    final d = e - a;
    final hours = d ~/ 60;
    final minutes = d % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }


  /// Ages over 12 years are whole numbers only (no decimals).
  void _normalizeAgeInput() {
    if (_ageUnit != 'years') return;
    final raw = _ageController.text.trim();
    if (raw.isEmpty) return;
    final n = double.tryParse(raw);
    if (n == null) return;
    if (n > 12) {
      final whole = n.round().toString();
      if (raw != whole) {
        _ageController.value = TextEditingValue(
          text: whole,
          selection: TextSelection.collapsed(offset: whole.length),
        );
      }
    }
  }

  double? _parsedPatientAge() {
    _normalizeAgeInput();
    final n = double.tryParse(_ageController.text.trim());
    if (n == null) return null;
    if (_ageUnit == 'years' && n > 12) return n.roundToDouble();
    return n;
  }

  void _ensureRegionalBlock(String name) {
    final exists = _regionalList.any((e) => e['name'] == name);
    if (exists) return;
    _regionalList.removeWhere((e) => e['name'] == 'None / Not performed');
    _regionalList.add({
      'name': name,
      'role': 'Performed',
      'usgGuided': false,
      'nerveStimulator': false,
      if (name == 'Other peripheral nerve block') 'isOther': true,
    });
  }

  void _syncRegionalFromTechnique() {
    if (_technique == 'Spinal (SAB)') {
      _ensureRegionalBlock('Spinal (SAB)');
    } else if (_technique == 'Epidural') {
      _ensureRegionalBlock('Epidural');
    } else if (_technique == 'Combined Spinal-Epidural (CSE)') {
      _ensureRegionalBlock('Spinal (SAB)');
      _ensureRegionalBlock('Epidural');
    }
  }

  Future<void> _pickTime({required bool isAnaesthesia, required bool isStart}) async {
    TimeOfDay? initial;
    if (isAnaesthesia) {
      initial = isStart ? (_anaesthesiaStart ?? TimeOfDay.now()) : (_anaesthesiaEnd ?? TimeOfDay.now());
    } else {
      initial = isStart ? (_surgeryStart ?? TimeOfDay.now()) : (_surgeryEnd ?? TimeOfDay.now());
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    setState(() {
      if (isAnaesthesia) {
        if (isStart) {
          _anaesthesiaStart = picked;
        } else {
          _anaesthesiaEnd = picked;
        }
        _anaesthesiaDuration = _calcDuration(_anaesthesiaStart, _anaesthesiaEnd);
        _validateSurgeryTimes();
      } else {
        if (isStart) {
          if (_anaesthesiaStart != null) {
            final aS = _mins(_anaesthesiaStart!);
            var sS = _mins(picked);
            if (sS < aS) sS += 24 * 60;
            if (sS < aS) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Surgical time cannot start prior to anaesthesia time'),
                  backgroundColor: AppTheme.danger,
                ),
              );
              return;
            }
          }
          _surgeryStart = picked;
        } else {
          if (_anaesthesiaStart != null && _anaesthesiaEnd != null) {
            final aS = _anaesthesiaStart!;
            final aEndRel = _rel(_anaesthesiaEnd!, aS);
            final sEndRel = _rel(picked, aS);
            if (sEndRel > aEndRel) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Surgical time cannot end after anaesthesia time'),
                  backgroundColor: AppTheme.danger,
                ),
              );
              return;
            }
          }
          _surgeryEnd = picked;
        }
        _surgeryDuration = _calcDuration(_surgeryStart, _surgeryEnd);
      }
    });
  }

  void _validateSurgeryTimes() {
    if (_anaesthesiaStart == null) return;

    if (_surgeryStart != null) {
      if (_mins(_surgeryStart!) < _mins(_anaesthesiaStart!)) {
        _surgeryStart = null;
        _surgeryDuration = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Surgery time cannot start before anaesthesia time'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }

    if (_surgeryEnd != null && _anaesthesiaEnd != null) {
      final aS = _anaesthesiaStart!;
      final aEndRel = _rel(_anaesthesiaEnd!, aS);
      final sEndRel = _rel(_surgeryEnd!, aS);
      if (sEndRel > aEndRel) {
        _surgeryEnd = null;
        _surgeryDuration = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Surgical time cannot end after anaesthesia time'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }

    _surgeryDuration = _calcDuration(_surgeryStart, _surgeryEnd);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image =
      await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1200);
      if (image == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(directory.path, fileName);
      final File newImage = await File(image.path).copy(savedPath);
      setState(() => _imagePath = newImage.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.primary),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primary),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppTheme.danger),
                title: Text(l10n.removePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _imagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showComplicationDialog() {
    final available = _complicationOptions.where((o) {
      if (o == 'High spinal/Bradycardia') return _isSpinalTechnique;
      return true;
    }).toList();
    if (!_isSpinalTechnique) _selectedComplications.remove('High spinal/Bradycardia');

    final temp = List<String>.from(_selectedComplications);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l10n.complications, style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: available.map((option) {
                final selected = temp.contains(option);
                return CheckboxListTile(
                  title: Text(l10n.term(option), style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                  value: selected,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        if (option == 'None/uneventful') {
                          temp.clear();
                          temp.add(option);
                        } else {
                          temp.remove('None/uneventful');
                          temp.add(option);
                        }
                      } else {
                        temp.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedComplications
                    ..clear()
                    ..addAll(temp);
                });
                Navigator.pop(ctx);
              },
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegionalDialog() {
    final temp = _regionalList.map((e) => Map<String, dynamic>.from(e)).toList();
    final otherCtrl = TextEditingController(
      text: temp
          .firstWhere(
            (e) => e['isOther'] == true,
        orElse: () => <String, dynamic>{},
      )['customName']
          ?.toString() ??
          '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(l10n.regionalAnaesthesia, style: TextStyle(color: AppTheme.textPrimary)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _regionalOptions.map((option) {
                    final idx = temp.indexWhere((e) =>
                    e['name'] == option ||
                        (option == 'Other peripheral nerve block' && e['isOther'] == true));
                    final isSelected = idx >= 0;
                    final entry = isSelected ? temp[idx] : null;
                    final showUsg = !_noUsgBlocks.contains(option);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.term(option), style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                          value: isSelected,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                if (option == 'None / Not performed') {
                                  temp.clear();
                                  temp.add({
                                    'name': option,
                                    'role': 'Performed',
                                    'usgGuided': false,
                                    'nerveStimulator': false,
                                  });
                                } else {
                                  temp.removeWhere((e) => e['name'] == 'None / Not performed');
                                  temp.add({
                                    'name': option,
                                    'role': 'Performed',
                                    'usgGuided': false,
                                    'nerveStimulator': false,
                                    'isOther': option == 'Other peripheral nerve block',
                                    'customName': '',
                                  });
                                }
                              } else {
                                temp.removeWhere((e) =>
                                e['name'] == option ||
                                    (option == 'Other peripheral nerve block' && e['isOther'] == true));
                              }
                            });
                          },
                        ),
                        if (isSelected && option != 'None / Not performed') ...[
                          if (option == 'Other peripheral nerve block')
                            Padding(
                              padding: const EdgeInsets.only(left: 12, bottom: 8),
                              child: TextField(
                                controller: otherCtrl,
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: l10n.enterBlockName,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (v) {
                                  entry!['customName'] = v;
                                  entry['name'] = v.trim().isEmpty ? 'Other peripheral nerve block' : v.trim();
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 4),
                            child: DropdownButtonFormField<String>(
                              value: entry!['role'] as String? ?? 'Performed',
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _lineRoles
                                  .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(l10n.term(r), style: const TextStyle(fontSize: 13)),
                              ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setDialogState(() => entry['role'] = v);
                              },
                            ),
                          ),
                          if (showUsg) ...[
                            CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(left: 12),
                              title: Text(l10n.usgGuided,
                                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                              value: entry['usgGuided'] == true,
                              activeColor: AppTheme.primary,
                              onChanged: (v) => setDialogState(() => entry['usgGuided'] = v ?? false),
                            ),
                            CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(left: 12),
                              title: Text(l10n.nerveStimulatorUsed,
                                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                              value: entry['nerveStimulator'] == true,
                              activeColor: AppTheme.primary,
                              onChanged: (v) =>
                                  setDialogState(() => entry['nerveStimulator'] = v ?? false),
                            ),
                          ],
                        ],
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _regionalList
                      ..clear()
                      ..addAll(temp);
                    if (!_showCatheterOption) _catheterPlaced = false;
                  });
                  Navigator.pop(ctx);
                },
                child: Text(l10n.done),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInvasiveDialog() {
    final temp = _invasiveList.map((e) => Map<String, dynamic>.from(e)).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(l10n.invasiveLines, style: TextStyle(color: AppTheme.textPrimary)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _invasiveOptions.map((option) {
                    final idx = temp.indexWhere((e) => e['name'] == option);
                    final isSelected = idx >= 0;
                    final entry = isSelected ? temp[idx] : null;
                    final needsUsg = option == 'Arterial line' || option == 'CVC line';
                    final roles = _rolesForInvasive(option);
                    final currentRole = entry?['role'] as String?;
                    final safeRole = (currentRole != null && roles.contains(currentRole))
                        ? currentRole
                        : roles.first;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.term(option), style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                          value: isSelected,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                temp.add({
                                  'name': option,
                                  'role': roles.first,
                                  'usgGuided': false,
                                });
                              } else {
                                temp.removeWhere((e) => e['name'] == option);
                              }
                            });
                          },
                        ),
                        if (isSelected) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 4),
                            child: DropdownButtonFormField<String>(
                              value: safeRole,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: roles
                                  .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(l10n.term(r), style: const TextStyle(fontSize: 13)),
                              ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setDialogState(() => entry!['role'] = v);
                              },
                            ),
                          ),
                          if (needsUsg)
                            CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(left: 12),
                              title: Text(l10n.usgGuided,
                                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                              value: entry!['usgGuided'] == true,
                              activeColor: AppTheme.primary,
                              onChanged: (v) => setDialogState(() => entry['usgGuided'] = v ?? false),
                            ),
                        ],
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _invasiveList
                      ..clear()
                      ..addAll(temp);
                  });
                  Navigator.pop(ctx);
                },
                child: Text(l10n.done),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onAirwayChanged(String v) {
    setState(() {
      _airway = v;
      if (!_isETT) _cormack = 'Not graded';
      if (!_isTubeAirway) {
        _typeOfIntubation = null;
        _methodOfIntubation = null;
        _methodOfIntubationRole = null;
        _ettType = null;
        _ettSizeController.clear();
      }
      if (_isDLT) {
        _typeOfIntubation = 'Oral intubation';
        _ettType = null;
      }
      if (!_isLma) {
        _lmaType = null;
        _lmaRole = null;
        _lmaSizeController.clear();
      }
    });
  }

  void _onTypeOfIntubationChanged(String? v) {
    setState(() {
      _typeOfIntubation = v;
      if (v == 'Nasal intubation') {
        if (_ettType == null || !_ettTypesNasalOnly.contains(_ettType)) {
          _ettType = 'Nasal ETT';
        }
      } else {
        // Oral / Submental: Nasal ETT cannot be selected
        if (_ettType == 'Nasal ETT') {
          _ettType = null;
        }
      }
    });
  }


  void _applyTemplate(CaseTemplate t) {
    setState(() {
      _specialty = _specialties.contains(t.specialty) ? t.specialty! : 'Other';
      if (_specialty == 'Other') {
        _specialtyOtherController.text = t.specialtyOther ?? t.specialty ?? '';
      } else {
        _specialtyOtherController.text = '';
      }
      _technique = _techniques.contains(t.technique) ? t.technique : _technique;
      _priority = _priorities.contains(t.priority) ? t.priority! : _priority;
      _asaGrade = _asaGrades.contains(t.asaGrade) ? t.asaGrade! : _asaGrade;
      _role = _roles.contains(t.role) ? t.role : _role;
      _supervisorController.text = t.supervisor ?? '';
      _airway = _airways.contains(t.airwayManagement) ? t.airwayManagement! : _airway;
      _cormack = t.cormackLehane ?? 'Not graded';
      _typeOfIntubation = t.typeOfIntubation;
      _methodOfIntubation = t.methodOfIntubation;
      _methodOfIntubationRole = t.methodOfIntubationRole;
      _ettType = t.ettType;
      _lmaType = t.lmaType;
      _lmaRole = t.lmaRole;
      _difficultAirway = t.difficultAirway;
      _invasiveList
        ..clear()
        ..addAll(t.invasiveMonitoring.map((e) => Map<String, dynamic>.from(e)));
      _regionalList
        ..clear()
        ..addAll(t.regionalBlocks.map((e) => Map<String, dynamic>.from(e)));
      _catheterPlaced = t.catheterPlaced;
      if (t.diagnosis != null && t.diagnosis!.isNotEmpty) {
        _diagnosisController.text = t.diagnosis!;
      }
      if (t.procedure != null && t.procedure!.isNotEmpty) {
        _procedureController.text = t.procedure!;
      }
      if (t.outcome != null) _selectedOutcome = t.outcome;
      // Never copy case number / patient demographics from templates
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.templateAppliedMsg(t.name)),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _pickTemplate() async {
    final t = await Navigator.push<CaseTemplate>(
      context,
      MaterialPageRoute(builder: (_) => const TemplatesScreen()),
    );
    if (t != null && mounted) _applyTemplate(t);
  }

  Future<void> _fromLastCase() async {
    final t = await TemplateStorage.lastCaseAsTemplate();
    if (t == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPreviousCasesToCopy)),
      );
      return;
    }
    _applyTemplate(t);
  }

  Future<void> _saveAsTemplate() async {
    final ctrl = TextEditingController(
      text: [
        _specialty,
        if (_procedureController.text.trim().isNotEmpty) _procedureController.text.trim(),
      ].join(' · '),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.saveAsTemplate, style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.storesTemplateExplanation,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.templateName),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.saveAction),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final resolvedSpecialty = _isOtherSpecialty
        ? (_specialtyOtherController.text.trim().isEmpty
        ? 'Other'
        : _specialtyOtherController.text.trim())
        : _specialty;

    final template = CaseTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      specialty: resolvedSpecialty,
      specialtyOther: _isOtherSpecialty ? _specialtyOtherController.text.trim() : null,
      technique: _technique,
      priority: _priority,
      asaGrade: _asaGrade,
      role: _role,
      supervisor: _supervisorController.text.trim().isEmpty
          ? null
          : _supervisorController.text.trim(),
      airwayManagement: _airway,
      cormackLehane: _cormack,
      typeOfIntubation: _typeOfIntubation,
      methodOfIntubation: _methodOfIntubation,
      methodOfIntubationRole: _methodOfIntubationRole,
      ettType: _ettType,
      lmaType: _lmaType,
      lmaRole: _lmaRole,
      difficultAirway: _difficultAirway,
      regionalBlocks: _regionalList.map((e) => Map<String, dynamic>.from(e)).toList(),
      invasiveMonitoring: _invasiveList.map((e) => Map<String, dynamic>.from(e)).toList(),
      catheterPlaced: _catheterPlaced,
      diagnosis: _diagnosisController.text.trim().isEmpty
          ? null
          : _diagnosisController.text.trim(),
      procedure: _procedureController.text.trim().isEmpty
          ? null
          : _procedureController.text.trim(),
      outcome: _selectedOutcome,
    );
    await TemplateStorage.save(template);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.templateSavedMsg(name)),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Map<String, dynamic> _draftMap() {
    return {
      'specialty': _specialty,
      'specialtyOther': _specialtyOtherController.text,
      'technique': _technique,
      'priority': _priority,
      'asaGrade': _asaGrade,
      'role': _role,
      'supervisor': _supervisorController.text,
      'airway': _airway,
      'cormack': _cormack,
      'typeOfIntubation': _typeOfIntubation,
      'methodOfIntubation': _methodOfIntubation,
      'methodOfIntubationRole': _methodOfIntubationRole,
      'ettType': _ettType,
      'lmaType': _lmaType,
      'lmaRole': _lmaRole,
      'difficultAirway': _difficultAirway,
      'regionalBlocks': _regionalList,
      'invasiveMonitoring': _invasiveList,
      'catheterPlaced': _catheterPlaced,
      'diagnosis': _diagnosisController.text,
      'procedure': _procedureController.text,
      'notes': _notesController.text,
      'outcome': _selectedOutcome,
      'caseNumber': _caseNumberController.text,
      'age': _ageController.text,
      'ageUnit': _ageUnit,
      'weight': _weightController.text,
      'height': _heightController.text,
      'gender': _gender,
    };
  }

  Future<void> _autosaveDraft() async {
    if (widget.existingCase != null) return; // don't draft over edits
    // Only if user has entered something meaningful
    final hasContent = _procedureController.text.trim().isNotEmpty ||
        _diagnosisController.text.trim().isNotEmpty ||
        _caseNumberController.text.trim().isNotEmpty ||
        _regionalList.isNotEmpty ||
        _invasiveList.isNotEmpty;
    if (!hasContent) return;
    await TemplateStorage.saveDraft(_draftMap());
  }

  Future<void> _restoreDraftIfAny() async {
    if (widget.existingCase != null) return;
    final draft = await TemplateStorage.getDraft();
    if (draft == null || !mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.resumeIncompleteCase, style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          l10n.unsavedDraftRestore,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await TemplateStorage.clearDraft();
              if (ctx.mounted) Navigator.pop(ctx, false);
            },
            child: Text(l10n.discardAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restoreAction),
          ),
        ],
      ),
    );
    if (resume != true || !mounted) return;
    setState(() {
      _specialty = draft['specialty']?.toString() ?? _specialty;
      _specialtyOtherController.text = draft['specialtyOther']?.toString() ?? '';
      _technique = draft['technique']?.toString() ?? _technique;
      _priority = draft['priority']?.toString() ?? _priority;
      _asaGrade = draft['asaGrade']?.toString() ?? _asaGrade;
      _role = draft['role']?.toString() ?? _role;
      _supervisorController.text = draft['supervisor']?.toString() ?? '';
      _airway = draft['airway']?.toString() ?? _airway;
      _cormack = draft['cormack']?.toString() ?? _cormack;
      _typeOfIntubation = draft['typeOfIntubation']?.toString();
      _methodOfIntubation = draft['methodOfIntubation']?.toString();
      _methodOfIntubationRole = draft['methodOfIntubationRole']?.toString();
      _ettType = draft['ettType']?.toString();
      _lmaType = draft['lmaType']?.toString();
      _lmaRole = draft['lmaRole']?.toString();
      _difficultAirway = draft['difficultAirway'] == true;
      _catheterPlaced = draft['catheterPlaced'] == true;
      _diagnosisController.text = draft['diagnosis']?.toString() ?? '';
      _procedureController.text = draft['procedure']?.toString() ?? '';
      _notesController.text = draft['notes']?.toString() ?? '';
      _selectedOutcome = draft['outcome']?.toString();
      _caseNumberController.text = draft['caseNumber']?.toString() ?? '';
      _ageController.text = draft['age']?.toString() ?? '';
      _ageUnit = draft['ageUnit']?.toString() ?? _ageUnit;
      _weightController.text = draft['weight']?.toString() ?? '';
      _heightController.text = draft['height']?.toString() ?? '';
      _gender = draft['gender']?.toString() ?? _gender;
      if (draft['regionalBlocks'] is List) {
        _regionalList
          ..clear()
          ..addAll((draft['regionalBlocks'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)));
      }
      if (draft['invasiveMonitoring'] is List) {
        _invasiveList
          ..clear()
          ..addAll((draft['invasiveMonitoring'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)));
      }
      _recalculateBmi();
    });
  }


  void _saveCase() async {
    if (!_formKey.currentState!.validate()) return;

    _validateSurgeryTimes();

    final resolvedSpecialty = _isOtherSpecialty
        ? (_specialtyOtherController.text.trim().isEmpty
        ? 'Other'
        : _specialtyOtherController.text.trim())
        : _specialty;

    final celebrate = _selectedComplications.contains('None/uneventful');

    var newCase = CaseRecord(
      id: widget.existingCase?.id,
      caseNumber: _caseNumberController.text.trim(),
      date: _selectedDate,
      anaesthesiaStartTime: _formatTime(_anaesthesiaStart),
      anaesthesiaEndTime: _formatTime(_anaesthesiaEnd),
      anaesthesiaDuration: _anaesthesiaDuration,
      surgeryStartTime: _formatTime(_surgeryStart),
      surgeryEndTime: _formatTime(_surgeryEnd),
      surgeryDuration: _surgeryDuration,
      specialty: resolvedSpecialty,
      specialtyOther: _isOtherSpecialty ? _specialtyOtherController.text.trim() : null,
      diagnosis: _capitalizeFirst(_diagnosisController.text.trim()),
      procedure: _capitalizeFirst(_procedureController.text.trim()),
      priority: _priority,
      asaGrade: _asaGrade,
      technique: _technique,
      role: _role,
      difficultAirway: _difficultAirway,
      difficultAirwayAttempts:
      _difficultAirway ? int.tryParse(_airwayAttemptsController.text.trim()) : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      patientAge: _parsedPatientAge(),
      ageUnit: _ageUnit,
      patientGender: _gender,
      patientWeight: double.tryParse(_weightController.text.trim()),
      patientHeight: double.tryParse(_heightController.text.trim()),
      bmi: _bmi,
      hospital: _hospitalFromProfile,
      supervisor: _role == 'Consultant'
          ? null
          : (_supervisorController.text.trim().isEmpty
          ? null
          : _supervisorController.text.trim()),
      airwayManagement: _airway,
      cormackLehane: _isETT ? _cormack : 'Not graded',
      typeOfIntubation: _isTubeAirway
          ? (_isDLT ? 'Oral intubation' : _typeOfIntubation)
          : null,
      methodOfIntubation: _isTubeAirway ? _methodOfIntubation : null,
      methodOfIntubationRole: _isTubeAirway ? _methodOfIntubationRole : null,
      ettType: _showEttType ? _ettType : null,
      ettSize: _isTubeAirway && !_isDLT ? double.tryParse(_ettSizeController.text.trim()) : null,
      lmaType: _isLma ? _lmaType : null,
      lmaSize: _isLma ? double.tryParse(_lmaSizeController.text.trim()) : null,
      lmaRole: _isLma ? _lmaRole : null,
      invasiveMonitoring: _invasiveList.map((e) => Map<String, dynamic>.from(e)).toList(),
      complications: List.from(_selectedComplications),
      outcome: _selectedOutcome,
      caseSheetImagePath: _imagePath,
      regionalBlocks: _regionalList.map((e) => Map<String, dynamic>.from(e)).toList(),
      catheterPlaced: _showCatheterOption ? _catheterPlaced : false,
      starred: widget.existingCase?.starred ?? false,
      flagForFollowUp: _flagForFollowUp,
      followUpStatus: 'pending', // set properly next line
    );
    newCase = newCase.copyWith(
      followUpStatus: FollowUpService.initialStatus(newCase),
    );

    // 1. Fetch achievements *before* saving the new case
    final existingCases = await CaseStorage.getAllCases();
    final previousAchievements = await AchievementService.getAllAchievements(existingCases);
    final previouslyUnlockedIds = previousAchievements
        .where((a) => a.isUnlocked)
        .map((a) => a.id)
        .toSet();

    // 2. Save/update case in storage
    if (widget.existingCase != null) {
      await CaseStorage.deleteCase(widget.existingCase!.id);
    }
    await CaseStorage.saveCase(newCase);
    await TemplateStorage.clearDraft();
    final updatedCases = await CaseStorage.getAllCases();

    // 3. Fetch achievements *after* saving to detect newly unlocked ones
    final currentAchievements = await AchievementService.getAllAchievements(updatedCases);

    if (!mounted) return;

    // 4. Queue ALL newly unlocked achievements — shown one after another
    final newlyUnlocked = currentAchievements
        .where((a) => a.isUnlocked && !previouslyUnlockedIds.contains(a.id))
        .toList();
    if (mounted && newlyUnlocked.isNotEmpty) {
      AchievementNotificationService.showAll(context, newlyUnlocked);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingCase != null ? 'Case updated' : 'Case saved successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.pop(context, celebrate ? 'celebrate' : true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final isConsultant = _role == 'Consultant';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(widget.existingCase != null ? l10n.edit : l10n.newCase),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.term('Templates'),
            onSelected: (v) {
              if (v == 'template') _pickTemplate();
              if (v == 'last') _fromLastCase();
              if (v == 'save_template') _saveAsTemplate();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'template', child: Text(l10n.useTemplate)),
              PopupMenuItem(value: 'last', child: Text(l10n.copyLastCasePattern)),
              PopupMenuItem(value: 'save_template', child: Text(l10n.saveAsTemplate)),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(l10n.caseSheetPhotoHeader),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceLight),
                ),
                child: _imagePath != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity, height: 160),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 36, color: AppTheme.textSecondary),
                    const SizedBox(height: 8),
                    Text(l10n.tapToAddCaseSheetPhoto, style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            if (_imagePath != null)
              TextButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(l10n.changePhoto),
              ),

            _sectionHeader(l10n.basicInformationHeader),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: l10n.dateLabel,
                    child: InkWell(
                      onTap: _pickDate,
                      child: _box(Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(color: AppTheme.textPrimary),
                      )),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: l10n.caseHospitalNo,
                    child: TextFormField(
                      controller: _caseNumberController,
                      maxLength: 10,
                      decoration: InputDecoration(
                        hintText: l10n.max10Characters,
                        counterText: '',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            _sectionHeader(l10n.anaesthesiaTimeHeader),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: l10n.anaesthesiaStart,
                    child: InkWell(
                      onTap: () => _pickTime(isAnaesthesia: true, isStart: true),
                      child: _box(Text(
                        _anaesthesiaStart != null ? _formatTime(_anaesthesiaStart)! : l10n.selectLabel,
                        style: TextStyle(color: AppTheme.textPrimary),
                      )),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: l10n.anaesthesiaEnd,
                    child: InkWell(
                      onTap: () => _pickTime(isAnaesthesia: true, isStart: false),
                      child: _box(Text(
                        _anaesthesiaEnd != null ? _formatTime(_anaesthesiaEnd)! : l10n.selectLabel,
                        style: TextStyle(color: AppTheme.textPrimary),
                      )),
                    ),
                  ),
                ),
              ],
            ),
            if (_anaesthesiaDuration != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${l10n.anaesthesiaDurationLabel}: $_anaesthesiaDuration',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),

            _sectionHeader(l10n.surgicalTimeHeader),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: l10n.surgeryStart,
                    child: InkWell(
                      onTap: () => _pickTime(isAnaesthesia: false, isStart: true),
                      child: _box(Text(
                        _surgeryStart != null ? _formatTime(_surgeryStart)! : l10n.selectLabel,
                        style: TextStyle(color: AppTheme.textPrimary),
                      )),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: l10n.surgeryEnd,
                    child: InkWell(
                      onTap: () => _pickTime(isAnaesthesia: false, isStart: false),
                      child: _box(Text(
                        _surgeryEnd != null ? _formatTime(_surgeryEnd)! : l10n.selectLabel,
                        style: TextStyle(color: AppTheme.textPrimary),
                      )),
                    ),
                  ),
                ),
              ],
            ),
            if (_surgeryDuration != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${l10n.surgicalDurationLabel}: $_surgeryDuration',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),

            _sectionHeader(l10n.patientHeader),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    label: l10n.age,
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: const InputDecoration(hintText: 'e.g. 0.5'),
                      onChanged: (_) => _normalizeAgeInput(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildField(
                    label: l10n.unitLabel,
                    child: DropdownButtonFormField<String>(
                      value: _ageUnit,
                      items: _ageUnits.map((u) => DropdownMenuItem(value: u, child: Text(l10n.term(u)))).toList(),
                      onChanged: (v) {
                        setState(() => _ageUnit = v!);
                        _normalizeAgeInput();
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: l10n.genderLabel,
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(l10n.term(g)))).toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: '${l10n.weight} (kg)',
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(hintText: 'kg'),
                      onChanged: (_) => _recalculateBmi(),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: '${l10n.height} (cm)',
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(hintText: 'cm'),
                      onChanged: (_) => _recalculateBmi(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: l10n.bmiLabel,
                    child: _box(Text(
                      _bmi != null ? _bmi!.toStringAsFixed(1) : '—',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    )),
                  ),
                ),
              ],
            ),

            _sectionHeader(l10n.surgeryAndAnaesthesiaHeader),
            _buildField(
              label: l10n.specialty,
              child: DropdownButtonFormField<String>(
                value: _specialty,
                items: _specialties
                    .map((s) => DropdownMenuItem(value: s, child: Text(l10n.term(s), overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _specialty = v!),
              ),
            ),
            if (_isOtherSpecialty)
              _buildField(
                label: l10n.specifySpecialty,
                child: TextFormField(
                  controller: _specialtyOtherController,
                  decoration: InputDecoration(hintText: l10n.enterSpecialty),
                  validator: (v) {
                    if (_isOtherSpecialty && (v == null || v.trim().isEmpty)) {
                      return l10n.pleaseEnterSpecialty;
                    }
                    return null;
                  },
                ),
              ),
            _buildField(
              label: l10n.diagnosis,
              child: Autocomplete<String>(
                optionsBuilder: (tev) {
                  if (tev.text.isEmpty) return const Iterable<String>.empty();
                  return _diagnosisSuggestions
                      .where((o) => o.toLowerCase().contains(tev.text.toLowerCase()));
                },
                onSelected: (s) => _diagnosisController.text = s,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.text = _diagnosisController.text;
                  controller.addListener(() => _diagnosisController.text = controller.text);
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(hintText: l10n.primaryDiagnosis),
                  );
                },
              ),
            ),
            _buildField(
              label: l10n.procedure,
              child: Autocomplete<String>(
                optionsBuilder: (tev) {
                  if (tev.text.isEmpty) return const Iterable<String>.empty();
                  return _procedureSuggestions
                      .where((o) => o.toLowerCase().contains(tev.text.toLowerCase()));
                },
                onSelected: (s) => _procedureController.text = s,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.text = _procedureController.text;
                  controller.addListener(() => _procedureController.text = controller.text);
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(hintText: l10n.procedurePerformed),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.pleaseEnterProcedure : null,
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: l10n.priority,
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(l10n.term(p)))).toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: l10n.asaGrade,
                    child: DropdownButtonFormField<String>(
                      value: _asaGrade,
                      items: _asaGrades.map((a) => DropdownMenuItem(value: a, child: Text(l10n.term(a)))).toList(),
                      onChanged: (v) => setState(() => _asaGrade = v!),
                    ),
                  ),
                ),
              ],
            ),
            _buildField(
              label: l10n.primaryTechnique,
              child: DropdownButtonFormField<String>(
                value: _technique,
                items: _techniques
                    .map((t) => DropdownMenuItem(value: t, child: Text(l10n.term(t), overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _technique = v!;
                    if (!_isSpinalTechnique) {
                      _selectedComplications.remove('High spinal/Bradycardia');
                    }
                    _syncRegionalFromTechnique();
                  });
                },
              ),
            ),

            _sectionHeader(l10n.regionalAnaesthesiaHeader),
            _buildDetailTile(
              title: l10n.regionalAnaesthesia,
              chips: _regionalList.map<String>((e) {
                final name = e['name']?.toString() ?? '';
                if (name == 'None / Not performed') return l10n.term(name);
                final roleStr = e['role']?.toString() ?? '';
                final parts = <String>[l10n.term(name), l10n.term(roleStr)];
                if (e['usgGuided'] == true) parts.add('USG');
                if (e['nerveStimulator'] == true) parts.add('NS');
                return parts.join(' · ');
              }).toList(),
              onTap: _showRegionalDialog,
            ),
            if (_showCatheterOption)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceLight),
                ),
                child: CheckboxListTile(
                  title: Text(
                    l10n.catheterPlacedInfo,
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  value: _catheterPlaced,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _catheterPlaced = v ?? false),
                ),
              ),

            _buildField(
              label: l10n.yourRole,
              child: DropdownButtonFormField<String>(
                value: _role,
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(l10n.term(r)))).toList(),
                onChanged: (v) {
                  setState(() {
                    _role = v!;
                    if (_role == 'Consultant') _supervisorController.clear();
                  });
                },
              ),
            ),
            if (!isConsultant)
              _buildField(
                label: l10n.supervisorName,
                child: TextFormField(
                  controller: _supervisorController,
                  decoration: InputDecoration(hintText: l10n.ifSupervised),
                ),
              ),

            _sectionHeader(l10n.airwayHeader),
            _buildField(
              label: l10n.airwayManagement,
              child: DropdownButtonFormField<String>(
                value: _airway,
                items: _airways.map((a) => DropdownMenuItem(value: a, child: Text(l10n.term(a)))).toList(),
                onChanged: (v) {
                  if (v != null) _onAirwayChanged(v);
                },
              ),
            ),
            if (_isTubeAirway) ...[
              _buildField(
                label: l10n.typeOfIntubationLabel,
                child: DropdownButtonFormField<String>(
                  value: _isDLT
                      ? 'Oral intubation'
                      : (_availableIntubationTypes.contains(_typeOfIntubation)
                      ? _typeOfIntubation
                      : null),
                  hint: Text(l10n.selectLabel),
                  items: _availableIntubationTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(l10n.term(t))))
                      .toList(),
                  onChanged: _isDLT ? null : _onTypeOfIntubationChanged,
                ),
              ),
              _buildField(
                label: l10n.methodOfIntubationLabel,
                child: DropdownButtonFormField<String>(
                  value: _methodOfIntubation,
                  hint: Text(l10n.selectLabel),
                  items: _intubationMethods
                      .map((t) => DropdownMenuItem(value: t, child: Text(l10n.term(t), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _methodOfIntubation = v),
                ),
              ),
              _buildField(
                label: l10n.intubationRoleLabel,
                child: DropdownButtonFormField<String>(
                  value: _methodOfIntubationRole,
                  hint: Text(l10n.selectLabel),
                  items: _intubationRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(l10n.term(r))))
                      .toList(),
                  onChanged: (v) => setState(() => _methodOfIntubationRole = v),
                ),
              ),
              if (_showEttType) ...[
                _buildField(
                  label: l10n.ettTypeLabel,
                  child: DropdownButtonFormField<String>(
                    value: _availableEttTypes.contains(_ettType) ? _ettType : null,
                    hint: Text(l10n.selectLabel),
                    items: _availableEttTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(l10n.term(t), overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _ettType = v),
                  ),
                ),
                _buildField(
                  label: '${l10n.ettSizeLabel} (2.0 – 9.0)',
                  child: TextFormField(
                    controller: _ettSizeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))],
                    decoration: const InputDecoration(hintText: 'e.g. 7.5'),
                  ),
                ),
              ],
            ],
            if (_isETT)
              _buildField(
                label: l10n.cormackLehaneGrade,
                child: DropdownButtonFormField<String>(
                  value: _cormack,
                  items: _cormackGrades.map((c) => DropdownMenuItem(value: c, child: Text(l10n.term(c)))).toList(),
                  onChanged: (v) => setState(() => _cormack = v!),
                ),
              ),
            if (_isLma) ...[
              _buildField(
                label: l10n.lmaTypeLabel,
                child: DropdownButtonFormField<String>(
                  value: _lmaType,
                  hint: Text(l10n.selectLabel),
                  items: _lmaTypes.map((t) => DropdownMenuItem(value: t, child: Text(l10n.term(t)))).toList(),
                  onChanged: (v) => setState(() => _lmaType = v),
                ),
              ),
              _buildField(
                label: l10n.lmaRoleLabel,
                child: DropdownButtonFormField<String>(
                  value: _lmaRole,
                  hint: Text(l10n.selectLabel),
                  items: _intubationRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(l10n.term(r))))
                      .toList(),
                  onChanged: (v) => setState(() => _lmaRole = v),
                ),
              ),
              _buildField(
                label: '${l10n.lmaSizeLabel} (1.0 – 7.0)',
                child: TextFormField(
                  controller: _lmaSizeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))],
                  decoration: const InputDecoration(hintText: 'e.g. 4.0'),
                ),
              ),
            ],
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: SwitchListTile(
                title: Text(l10n.difficultAirwayLabel, style: TextStyle(color: AppTheme.textPrimary)),
                value: _difficultAirway,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() {
                  _difficultAirway = v;
                  if (!v) _airwayAttemptsController.clear();
                }),
              ),
            ),
            if (_difficultAirway)
              _buildField(
                label: l10n.numberOfAttempts,
                child: TextFormField(
                  controller: _airwayAttemptsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(hintText: 'e.g. 2'),
                ),
              ),

            _sectionHeader(l10n.invasiveLinesHeader),
            _buildDetailTile(
              title: l10n.invasiveLinesAndEquipmentUsed,
              chips: _invasiveList.map<String>((e) {
                final name = e['name']?.toString() ?? '';
                final roleStr = e['role']?.toString() ?? '';
                final parts = <String>[l10n.term(name), l10n.term(roleStr)];
                if (e['usgGuided'] == true) parts.add('USG');
                return parts.join(' · ');
              }).toList(),
              onTap: _showInvasiveDialog,
            ),

            _sectionHeader(l10n.complicationsHeader),
            _buildDetailTile(
              title: l10n.intraOpPostOpComplications,
              chips: _selectedComplications.map<String>((c) => l10n.term(c)).toList(),
              onTap: _showComplicationDialog,
            ),

            _sectionHeader(l10n.outcomeHeader),
            _buildField(
              label: l10n.outcome,
              child: DropdownButtonFormField<String>(
                value: _selectedOutcome,
                hint: Text(l10n.selectOutcome),
                items: _outcomeOptions
                    .map((o) => DropdownMenuItem(value: o, child: Text(l10n.term(o), overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedOutcome = v),
              ),
            ),


            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.flagForPostOpFollowUp,
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                l10n.flagForFollowUpSubtitle,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              value: _flagForFollowUp,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _flagForFollowUp = v),
            ),
            const SizedBox(height: 8),
            _sectionHeader(l10n.notesHeader),
            _buildField(
              label: l10n.additionalNotes,
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(hintText: l10n.additionalClinicalNotes),
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton(onPressed: _saveCase, child: Text(l10n.saveCase)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _box(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required String title,
    required List<String> chips,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                ],
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: chips
                      .map((s) => Chip(
                    label: Text(s, style: TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    labelStyle: TextStyle(color: AppTheme.primary),
                    visualDensity: VisualDensity.compact,
                  ))
                      .toList(),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l10n.tapToSelect, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
