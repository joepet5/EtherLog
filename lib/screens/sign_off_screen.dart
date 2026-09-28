import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/case_record.dart';
import '../models/doctor_profile.dart';
import '../services/case_storage.dart';
import '../services/pdf_service.dart';
import '../services/profile_storage.dart';
import '../services/signature_storage.dart';
import '../theme/app_theme.dart';
import '../utils/app_haptics.dart';
import '../widgets/signature_pad.dart';
import 'case_detail_screen.dart';

class SignOffScreen extends StatefulWidget {
  final List<CaseRecord>? preselectedCases;

  const SignOffScreen({super.key, this.preselectedCases});

  @override
  State<SignOffScreen> createState() => _SignOffScreenState();
}

class _SignOffScreenState extends State<SignOffScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _loading = true;

  DoctorProfile _profile = const DoctorProfile();
  List<CaseRecord> _allCases = [];
  List<SignOffRecord> _history = [];
  Uint8List? _doctorPersonalSignature;

  // Trainee mode state
  final _supervisorNameController = TextEditingController();
  final _supervisorDesignationController =
      TextEditingController(text: 'Consultant Anaesthetist');
  final _supervisorHospitalController = TextEditingController();
  final _supervisorRegController = TextEditingController();

  final Set<String> _selectedCaseIds = {};
  String _dateFilter = 'all'; // all, 30d, 90d, 1y, custom
  DateTimeRange? _customDateRange;
  bool _unverifiedOnlyFilter = true;

  // Consultant mode state
  bool _useSavedDoctorSignature = true;
  Uint8List? _consultantFreshSignature;
  bool _includeAppraiserCounterSignature = false;
  final _appraiserNameController = TextEditingController();
  final _appraiserDesignationController =
      TextEditingController(text: 'Lead Appraiser / Clinical Director');
  Uint8List? _appraiserSignature;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _supervisorNameController.dispose();
    _supervisorDesignationController.dispose();
    _supervisorHospitalController.dispose();
    _supervisorRegController.dispose();
    _appraiserNameController.dispose();
    _appraiserDesignationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final profile = await ProfileStorage.getProfile();
    final cases = await CaseStorage.getAllCases();
    final history = await SignatureStorage.getSignOffHistory();
    final docSig = await SignatureStorage.getDoctorSignature();

    if (_supervisorHospitalController.text.isEmpty &&
        profile.hospital.isNotEmpty) {
      _supervisorHospitalController.text = profile.hospital;
    }

    _profile = profile;
    _allCases = cases;
    _history = history;
    _doctorPersonalSignature = docSig;

    // Smart default tab: if designation contains consultant or specialist, open consultant tab
    final des = profile.designation.toLowerCase();
    final isConsultant = des.contains('consultant') ||
        des.contains('specialist') ||
        des.contains('attending') ||
        des.contains('director');

    if (widget.preselectedCases != null && widget.preselectedCases!.isNotEmpty) {
      final isCaseConsultant = widget.preselectedCases!.every(
          (c) => c.role.toLowerCase().contains('consultant'));
      _selectedCaseIds.addAll(widget.preselectedCases!.map((c) => c.id));
      if (isCaseConsultant) {
        _tabController.index = 1; // Consultant self-attestation tab
        _selectedTabIndex = 1;
      } else {
        _tabController.index = 0; // Trainee supervisor sign-off tab
        _selectedTabIndex = 0;
      }
    } else if (isConsultant && _tabController.index == 0) {
      _tabController.index = 1; // Consultant self-attestation tab
      _selectedTabIndex = 1;
    }

    // Default selection for trainee tab: all unverified cases
    if (_selectedCaseIds.isEmpty) {
      for (final c in _filteredCases) {
        if (!c.verified) {
          _selectedCaseIds.add(c.id);
        }
      }
    }

    setState(() => _loading = false);
  }

  List<CaseRecord> get _filteredCases {
    final now = DateTime.now();
    return _allCases.where((c) {
      if (_unverifiedOnlyFilter && c.verified) return false;
      if (c.role.toLowerCase().contains('consultant')) return false;

      if (_dateFilter == '30d') {
        if (c.date.isBefore(now.subtract(const Duration(days: 30)))) {
          return false;
        }
      } else if (_dateFilter == '90d') {
        if (c.date.isBefore(now.subtract(const Duration(days: 90)))) {
          return false;
        }
      } else if (_dateFilter == '1y') {
        if (c.date.isBefore(now.subtract(const Duration(days: 365)))) {
          return false;
        }
      } else if (_dateFilter == 'custom' && _customDateRange != null) {
        if (c.date.isBefore(_customDateRange!.start) ||
            c.date.isAfter(_customDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<CaseRecord> get _selectedCases {
    return _allCases.where((c) => _selectedCaseIds.contains(c.id)).toList();
  }

  // ========== TRAINEE SIGN-OFF ACTION ==========
  Future<void> _startSupervisorSignOff() async {
    if (_selectedCaseIds.isEmpty) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one case to verify.')),
      );
      return;
    }

    final supName = _supervisorNameController.text.trim();
    if (supName.isEmpty) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the supervisor\'s name.')),
      );
      return;
    }

    await AppHaptics.medium();
    if (!mounted) return;

    const declaration =
        'I confirm that I have reviewed the clinical logs recorded above and verify that they represent an authentic account of the trainee\'s clinical exposure, procedural competencies, and supervision levels.';

    final signatureBytes = await SignaturePadDialog.show(
      context,
      title: 'Supervisor Clinical Verification',
      subtitle: 'Please hand the device to your supervisor to sign',
      declaration: declaration,
      signerName: supName.startsWith('Dr') ? supName : 'Dr. $supName',
      signerRole: _supervisorDesignationController.text.trim().isNotEmpty
          ? _supervisorDesignationController.text.trim()
          : 'Consultant Anaesthetist',
      confirmButtonText: 'Verify & Sign ${selectedCaseCountText()}',
    );

    if (signatureBytes == null || !mounted) return;

    final selectedCases = _selectedCases;
    final signDate = DateTime.now();

    DateTime? minDate;
    DateTime? maxDate;
    for (final c in selectedCases) {
      if (minDate == null || c.date.isBefore(minDate)) minDate = c.date;
      if (maxDate == null || c.date.isAfter(maxDate)) maxDate = c.date;
    }

    final signOff = SignOffRecord(
      id: signDate.millisecondsSinceEpoch.toString(),
      date: signDate,
      isConsultantAttestation: false,
      doctorName: _profile.name,
      supervisorName: supName,
      supervisorDesignation:
          _supervisorDesignationController.text.trim().isNotEmpty
              ? _supervisorDesignationController.text.trim()
              : 'Consultant Anaesthetist',
      supervisorHospital: _supervisorHospitalController.text.trim(),
      supervisorRegistration: _supervisorRegController.text.trim().isNotEmpty
          ? _supervisorRegController.text.trim()
          : null,
      declarationText: declaration,
      caseIds: selectedCases.map((c) => c.id).toList(),
      casesCount: selectedCases.length,
      dateRangeStart: minDate,
      dateRangeEnd: maxDate,
      signatureBase64: base64Encode(signatureBytes),
    );

    await SignatureStorage.saveSignOff(signOff);
    await CaseStorage.verifyCases(
      selectedCases.map((c) => c.id).toList(),
      verifiedBy: supName,
      verifiedAt: signDate,
    );

    await AppHaptics.medium();
    await _loadData();

    if (!mounted) return;
    _showSignOffSuccessDialog(signOff, selectedCases, signatureBytes);
  }

  String selectedCaseCountText() {
    final count = _selectedCaseIds.length;
    return '$count Case${count == 1 ? '' : 's'}';
  }

  // ========== CONSULTANT SELF-ATTESTATION ACTION ==========
  Future<void> _startConsultantAttestation() async {
    final docName = _profile.name.trim();
    if (docName.isEmpty) {
      await AppHaptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in your doctor name in Profile first.'),
        ),
      );
      return;
    }

    Uint8List? signatureToUse;
    if (_useSavedDoctorSignature && _doctorPersonalSignature != null) {
      signatureToUse = _doctorPersonalSignature;
    } else if (_consultantFreshSignature != null) {
      signatureToUse = _consultantFreshSignature;
    } else {
      // Draw signature now
      final declaration =
          'I, Dr. $docName, declare that this clinical logbook is a true, accurate, and complete record of my clinical anaesthetic practice for the specified period in accordance with professional appraisal and revalidation standards.';

      signatureToUse = await SignaturePadDialog.show(
        context,
        title: 'Consultant Clinical Self-Attestation',
        subtitle: 'Sign your clinical appraisal logbook declaration',
        declaration: declaration,
        signerName: docName.startsWith('Dr') ? docName : 'Dr. $docName',
        signerRole: _profile.designation.isNotEmpty
            ? _profile.designation
            : 'Consultant Anaesthetist',
        confirmButtonText: 'Attest & Sign',
      );

      if (signatureToUse == null || !mounted) return;
      // Prompt to save to profile as default personal signature
      await SignatureStorage.saveDoctorSignature(signatureToUse);
      _doctorPersonalSignature = signatureToUse;
    }

    if (signatureToUse == null || !mounted) return;

    final signDate = DateTime.now();
    DateTime? minDate;
    DateTime? maxDate;
    for (final c in _allCases) {
      if (minDate == null || c.date.isBefore(minDate)) minDate = c.date;
      if (maxDate == null || c.date.isAfter(maxDate)) maxDate = c.date;
    }

    final declaration =
        'I, Dr. $docName, declare that this clinical logbook is a true, accurate, and complete record of my clinical anaesthetic practice for the specified period in accordance with professional appraisal and revalidation standards.';

    final signOff = SignOffRecord(
      id: signDate.millisecondsSinceEpoch.toString(),
      date: signDate,
      isConsultantAttestation: true,
      doctorName: docName,
      supervisorName: docName, // Self
      supervisorDesignation: _profile.designation.isNotEmpty
          ? _profile.designation
          : 'Consultant Anaesthetist',
      supervisorHospital: _profile.hospital,
      supervisorRegistration: _profile.registrationNumber,
      appraiserName: _includeAppraiserCounterSignature
          ? _appraiserNameController.text.trim()
          : null,
      appraiserDesignation: _includeAppraiserCounterSignature
          ? _appraiserDesignationController.text.trim()
          : null,
      declarationText: declaration,
      caseIds: _allCases.map((c) => c.id).toList(),
      casesCount: _allCases.length,
      dateRangeStart: minDate,
      dateRangeEnd: maxDate,
      signatureBase64: base64Encode(signatureToUse),
      counterSignatureBase64: (_includeAppraiserCounterSignature &&
              _appraiserSignature != null)
          ? base64Encode(_appraiserSignature!)
          : null,
    );

    await SignatureStorage.saveSignOff(signOff);
    await CaseStorage.verifyCases(
      _allCases.map((c) => c.id).toList(),
      verifiedBy: docName,
      verifiedAt: signDate,
    );
    await AppHaptics.medium();
    await _loadData();

    if (!mounted) return;
    _showSignOffSuccessDialog(
      signOff,
      _allCases,
      signatureToUse,
      isConsultant: true,
      counterSignatureBytes: _appraiserSignature,
    );
  }

  void _showSignOffSuccessDialog(
    SignOffRecord signOff,
    List<CaseRecord> cases,
    Uint8List signatureBytes, {
    bool isConsultant = false,
    Uint8List? counterSignatureBytes,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceSolid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_rounded,
                  color: AppTheme.success, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isConsultant ? 'Appraisal Logbook Attested' : 'Cases Verified!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isConsultant
                  ? 'Your logbook has been officially attested with your digital signature and stored for appraisal.'
                  : 'Successfully verified ${signOff.casesCount} case(s) with Dr. ${signOff.supervisorName}\'s digital signature.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
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
                          isConsultant ? 'Signer / Consultant' : 'Supervisor',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.textSecondary),
                        ),
                        Text(
                          isConsultant
                              ? 'Dr. ${signOff.doctorName}'
                              : 'Dr. ${signOff.supervisorName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          signOff.supervisorDesignation,
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 70,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Image.memory(signatureBytes, fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await PdfService.generateSignOffReportPdf(
                signOff,
                cases,
                signatureBytes,
                counterSignatureBytes: counterSignatureBytes,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Export Official PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sign-Off & Verification'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            Tab(
              icon: const Icon(Icons.verified_user_rounded, size: 18),
              child: _MarqueeTabLabel(
                text: 'Trainee Sign-Off',
                isSelected: _selectedTabIndex == 0,
                style: TextStyle(
                  fontWeight: _selectedTabIndex == 0
                      ? FontWeight.w700
                      : FontWeight.w600,
                  fontSize: 11.5,
                  color: _selectedTabIndex == 0
                      ? AppTheme.primary
                      : cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
            Tab(
              icon: const Icon(Icons.military_tech_rounded, size: 18),
              child: _MarqueeTabLabel(
                text: 'Consultant Appraisal',
                isSelected: _selectedTabIndex == 1,
                style: TextStyle(
                  fontWeight: _selectedTabIndex == 1
                      ? FontWeight.w700
                      : FontWeight.w600,
                  fontSize: 11.5,
                  color: _selectedTabIndex == 1
                      ? AppTheme.primary
                      : cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
            Tab(
              icon: const Icon(Icons.history_rounded, size: 18),
              child: _MarqueeTabLabel(
                text: 'History (${_history.length})',
                isSelected: _selectedTabIndex == 2,
                style: TextStyle(
                  fontWeight: _selectedTabIndex == 2
                      ? FontWeight.w700
                      : FontWeight.w600,
                  fontSize: 11.5,
                  color: _selectedTabIndex == 2
                      ? AppTheme.primary
                      : cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTraineeSignOffTab(isDark),
                _buildConsultantAppraisalTab(isDark),
                _buildHistoryTab(isDark),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: TRAINEE / RESIDENT SUPERVISOR SIGN-OFF
  // ==========================================
  Widget _buildTraineeSignOffTab(bool isDark) {
    final filtered = _filteredCases;
    final totalSelected = _selectedCaseIds.length;

    // Selected statistics
    final selectedCases = _selectedCases;
    final electiveCount =
        selectedCases.where((c) => c.priority == 'Elective').length;
    final emergencyCount =
        selectedCases.where((c) => c.priority == 'Emergency').length;
    final difficultAirwayCount =
        selectedCases.where((c) => c.difficultAirway).length;
    final regionalCount = selectedCases
        .where((c) => c.regionalBlocks
            .any((b) => b['name'] != 'None / Not performed'))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Top Info Alert
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.touch_app_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trainee & Resident Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select the clinical cases you wish to verify, enter supervisor details, and hand the device to your consultant to sign on-screen.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Supervisor Details Form Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_pin_circle_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SUPERVISOR / CONSULTANT DETAILS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _supervisorNameController,
                decoration: const InputDecoration(
                  labelText: 'Supervisor Full Name *',
                  hintText: 'e.g. Dr. Sarah Jenkins',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _supervisorDesignationController,
                decoration: const InputDecoration(
                  labelText: 'Designation / Title',
                  hintText: 'e.g. Consultant Anaesthetist, College Tutor',
                  prefixIcon: Icon(Icons.work_outline, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _supervisorHospitalController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital / Trust',
                        hintText: 'e.g. St Thomas\' Hospital',
                        prefixIcon: Icon(Icons.local_hospital_outlined, size: 18),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _supervisorRegController,
                      decoration: const InputDecoration(
                        labelText: 'Reg / GMC No (Optional)',
                        hintText: 'e.g. 1234567',
                        prefixIcon: Icon(Icons.badge_outlined, size: 18),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Case Selection & Filter Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SELECT CASES TO VERIFY ($totalSelected)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppTheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      AppHaptics.selection();
                      setState(() {
                        for (final c in filtered) {
                          _selectedCaseIds.add(c.id);
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Select All',
                        style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      AppHaptics.selection();
                      setState(() {
                        _selectedCaseIds.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Clear',
                        style: TextStyle(fontSize: 11, color: AppTheme.danger)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Unverified Only',
                          style: TextStyle(fontSize: 11)),
                      selected: _unverifiedOnlyFilter,
                      onSelected: (val) {
                        setState(() => _unverifiedOnlyFilter = val);
                      },
                    ),
                    const SizedBox(width: 6),
                    _dateFilterChip('All Time', 'all'),
                    const SizedBox(width: 6),
                    _dateFilterChip('Last 30 Days', '30d'),
                    const SizedBox(width: 6),
                    _dateFilterChip('Last 90 Days', '90d'),
                    const SizedBox(width: 6),
                    _dateFilterChip('Last 1 Year', '1y'),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.date_range, size: 14),
                      label: Text(
                        _customDateRange != null
                            ? '${_fmtD(_customDateRange!.start)} - ${_fmtD(_customDateRange!.end)}'
                            : 'Custom Range',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateFilter = 'custom';
                            _customDateRange = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Summary Stats of Selected Cases
              if (selectedCases.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('Elective', '$electiveCount'),
                      _miniStat('Emergency', '$emergencyCount'),
                      _miniStat('Diff Airway', '$difficultAirwayCount'),
                      _miniStat('Regional', '$regionalCount'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Case List Items
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Text(
              'No cases match the selected filters.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          )
        else
          ...filtered.map((c) {
            final isSelected = _selectedCaseIds.contains(c.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: AppTheme.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.surfaceLight,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                activeColor: AppTheme.primary,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                onChanged: (val) {
                  AppHaptics.selection();
                  setState(() {
                    if (val == true) {
                      _selectedCaseIds.add(c.id);
                    } else {
                      _selectedCaseIds.remove(c.id);
                    }
                  });
                },
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.procedure,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (c.verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                size: 12, color: AppTheme.success),
                            const SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      '${c.specialty} • ${c.technique} • ${c.role}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${_fmtD(c.date)} • ASA ${c.asaGrade} • ${c.priority}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (c.verified && c.verifiedBy != null)
                      Text(
                        'Verified by: Dr. ${c.verifiedBy}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.success,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 20),

        // Big Primary Action Button
        ElevatedButton.icon(
          onPressed: _startSupervisorSignOff,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.draw_rounded, size: 22),
          label: Text(
            'Hand Phone to Supervisor to Sign ($totalSelected)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _dateFilterChip(String label, String key) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _dateFilter == key,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _dateFilter = key;
          });
        }
      },
    );
  }

  Widget _miniStat(String label, String val) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.primary)),
        Text(label,
            style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }

  // ==========================================
  // TAB 2: CONSULTANT / SPECIALIST SELF-ATTESTATION & APPRAISAL
  // ==========================================
  Widget _buildConsultantAppraisalTab(bool isDark) {
    final totalCases = _allCases.length;
    final electiveCount =
        _allCases.where((c) => c.priority == 'Elective').length;
    final emergencyCount =
        _allCases.where((c) => c.priority == 'Emergency').length;

    final docName = _profile.name.isNotEmpty ? _profile.name : 'Doctor';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Top Info Alert
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                  size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultant Self-Attestation & Annual Appraisal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark
                            ? Colors.amber.shade300
                            : Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'For consultants and specialists. Formal clinical practice attestation with your vector digital signature, with optional Head of Department / Lead Appraiser counter-signature.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Practice Scope & Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'CLINICAL PRACTICE SUMMARY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      'Total Clinical Cases',
                      '$totalCases',
                      AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statTile(
                      'Elective Practice',
                      '$electiveCount',
                      AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statTile(
                      'Emergency Practice',
                      '$emergencyCount',
                      AppTheme.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Doctor: Dr. $docName (${_profile.qualifications.isNotEmpty ? _profile.qualifications : 'Consultant'})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_profile.hospital.isNotEmpty)
                Text(
                  'Hospital / Trust: ${_profile.hospital}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              if (_profile.registrationNumber != null &&
                  _profile.registrationNumber!.isNotEmpty)
                Text(
                  'Medical Registration / GMC: ${_profile.registrationNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Legal / Clinical Declaration Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'FORMAL DECLARATION OF CLINICAL PRACTICE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '"I, Dr. $docName, confirm that this clinical logbook is a true, accurate, and complete record of my clinical anaesthetic practice for the specified period. It reflects my ongoing professional commitment, case-mix competency, and adherence to professional standards for annual appraisal and revalidation."',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Doctor Signature Preview & Selection Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.draw_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CONSULTANT SIGNATURE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      AppHaptics.light();
                      final fresh = await SignaturePadDialog.show(
                        context,
                        title: 'Draw Personal Signature',
                        signerName: 'Dr. $docName',
                        signerRole: _profile.designation.isNotEmpty
                            ? _profile.designation
                            : 'Consultant Anaesthetist',
                        confirmButtonText: 'Save Signature',
                      );
                      if (fresh != null && mounted) {
                        await SignatureStorage.saveDoctorSignature(fresh);
                        setState(() {
                          _doctorPersonalSignature = fresh;
                          _useSavedDoctorSignature = true;
                        });
                      }
                    },
                    child: Text(
                      _doctorPersonalSignature == null ? 'Draw' : 'Redraw',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_doctorPersonalSignature != null) ...[
                Container(
                  height: 90,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Image.memory(_doctorPersonalSignature!,
                      fit: BoxFit.contain),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Configured personal signature ready to embed on PDF',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  height: 80,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.surfaceLight,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      AppHaptics.light();
                      final fresh = await SignaturePadDialog.show(
                        context,
                        title: 'Draw Personal Signature',
                        signerName: 'Dr. $docName',
                        signerRole: _profile.designation.isNotEmpty
                            ? _profile.designation
                            : 'Consultant Anaesthetist',
                        confirmButtonText: 'Save Signature',
                      );
                      if (fresh != null && mounted) {
                        await SignatureStorage.saveDoctorSignature(fresh);
                        setState(() {
                          _doctorPersonalSignature = fresh;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Tap to draw and configure your signature'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Optional HoD / Appraiser Counter-Signature Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.primary,
                title: Text(
                  'Clinical Director / Appraiser Counter-Signature',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Include secondary counter-signature from Head of Department or Lead Appraiser',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                value: _includeAppraiserCounterSignature,
                onChanged: (val) {
                  setState(() => _includeAppraiserCounterSignature = val);
                },
              ),
              if (_includeAppraiserCounterSignature) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _appraiserNameController,
                  decoration: const InputDecoration(
                    labelText: 'Appraiser / HoD Name *',
                    hintText: 'e.g. Dr. Arthur Pendelton',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _appraiserDesignationController,
                  decoration: const InputDecoration(
                    labelText: 'Appraiser Title',
                    hintText: 'e.g. Clinical Director, Lead Appraiser',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (_appraiserSignature != null) ...[
                  Container(
                    height: 80,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Image.memory(_appraiserSignature!,
                        fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () async {
                      final fresh = await SignaturePadDialog.show(
                        context,
                        title: 'Appraiser Counter-Signature',
                        signerName: _appraiserNameController.text.trim().isNotEmpty
                            ? _appraiserNameController.text.trim()
                            : 'Lead Appraiser',
                        signerRole: _appraiserDesignationController.text.trim(),
                        confirmButtonText: 'Confirm Counter-Signature',
                      );
                      if (fresh != null && mounted) {
                        setState(() => _appraiserSignature = fresh);
                      }
                    },
                    child: const Text('Redraw Counter-Signature'),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      AppHaptics.light();
                      final fresh = await SignaturePadDialog.show(
                        context,
                        title: 'Appraiser Counter-Signature',
                        signerName:
                            _appraiserNameController.text.trim().isNotEmpty
                                ? _appraiserNameController.text.trim()
                                : 'Lead Appraiser',
                        signerRole: _appraiserDesignationController.text.trim(),
                        confirmButtonText: 'Confirm Counter-Signature',
                      );
                      if (fresh != null && mounted) {
                        setState(() => _appraiserSignature = fresh);
                      }
                    },
                    icon: const Icon(Icons.draw_rounded, size: 18),
                    label: const Text('Capture Appraiser Counter-Signature'),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Big Primary Action Button
        ElevatedButton.icon(
          onPressed: _startConsultantAttestation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.verified_rounded, size: 22),
          label: const Text(
            'Attest & Generate Signed Appraisal Portfolio',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: SIGN-OFF HISTORY & VERIFICATION STATUS
  // ==========================================
  Widget _buildHistoryTab(bool isDark) {
    final verifiedCases = _allCases.where((c) => c.verified).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final totalCases = _allCases.length;
    final verifiedCount = verifiedCases.length;
    final pct = totalCases > 0 ? (verifiedCount / totalCases) : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1. TOP AUDIT & VERIFICATION STATUS CARD
        _buildVerificationStatusCard(
          isDark: isDark,
          totalCases: totalCases,
          verifiedCount: verifiedCount,
          pct: pct,
          verifiedCases: verifiedCases,
        ),
        const SizedBox(height: 20),

        // 2. OFFICIAL SIGNED CERTIFICATES SECTION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.military_tech_rounded,
                    size: 20,
                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade800),
                const SizedBox(width: 8),
                Text(
                  'Signed Certificates (${_history.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_history.isEmpty)
          _buildNoCertificatesCard(isDark)
        else
          ..._history.map((r) => _buildCertificateCard(r, isDark)),

        const SizedBox(height: 24),

        // 3. CLINICALLY VERIFIED CASES LOG SECTION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt_rounded,
                    size: 20, color: AppTheme.success),
                const SizedBox(width: 8),
                Text(
                  'Clinically Verified Cases ($verifiedCount)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            if (verifiedCases.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  await PdfService.generateAllCasesPdf(verifiedCases);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (verifiedCases.isEmpty)
          _buildNoVerifiedCasesCard(isDark, totalCases)
        else
          _buildVerifiedCasesList(verifiedCases, isDark),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildVerificationStatusCard({
    required bool isDark,
    required int totalCases,
    required int verifiedCount,
    required double pct,
    required List<CaseRecord> verifiedCases,
  }) {
    final pctInt = (pct * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppTheme.surface,
                  AppTheme.surfaceLight.withValues(alpha: 0.6),
                ]
              : [
                  Colors.teal.shade50,
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.primary.withValues(alpha: 0.25)
              : AppTheme.primary.withValues(alpha: 0.2),
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
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.analytics_rounded,
                    size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logbook Verification Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'ARCP & revalidation appraisal readiness',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: verifiedCount > 0
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pctInt% Verified',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: verifiedCount > 0 ? AppTheme.success : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalCases == 0 ? 0 : pct,
              minHeight: 7,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                pctInt == 100 ? AppTheme.success : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Metric Counters
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  label: 'Total Cases',
                  value: '$totalCases',
                  icon: Icons.folder_open_rounded,
                  color: AppTheme.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusMetric(
                  label: 'Verified Cases',
                  value: '$verifiedCount',
                  icon: Icons.verified_rounded,
                  color: AppTheme.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusMetric(
                  label: 'Certificates',
                  value: '${_history.length}',
                  icon: Icons.military_tech_rounded,
                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          if (verifiedCases.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await PdfService.generateAllCasesPdf(verifiedCases);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: Text(
                  'Export Verified Cases Logbook ($verifiedCount Cases PDF)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNoCertificatesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(Icons.history_edu_rounded,
              size: 40,
              color: AppTheme.textSecondary.withValues(alpha: 0.45)),
          const SizedBox(height: 8),
          Text(
            'No Formal Signed Certificates Yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate formal signed certificate PDF records with digital signatures from either the Trainee Sign-Off or Consultant Appraisal tabs.',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                  icon: const Icon(Icons.verified_user_rounded, size: 15),
                  label: const Text('Trainee Sign-Off',
                      style: TextStyle(fontSize: 11.5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                        color: isDark ? Colors.amber.shade400 : Colors.amber.shade800),
                  ),
                  icon: const Icon(Icons.military_tech_rounded, size: 15),
                  label: const Text('Consultant Appraisal',
                      style: TextStyle(fontSize: 11.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoVerifiedCasesCard(bool isDark, int totalCases) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(Icons.playlist_add_check_circle_outlined,
              size: 40,
              color: AppTheme.textSecondary.withValues(alpha: 0.45)),
          const SizedBox(height: 8),
          Text(
            totalCases == 0 ? 'No Cases in Logbook Yet' : 'No Verified Cases Yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            totalCases == 0
                ? 'Record your clinical cases in EtherLog, then come back here for consultant review and digital verification.'
                : 'Select cases from your logbook in the Trainee Sign-Off tab to have your supervisor sign and clinically verify them.',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (totalCases > 0) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Select Cases to Verify',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerifiedCasesList(List<CaseRecord> verifiedCases, bool isDark) {
    final displayCases = verifiedCases.take(25).toList();

    return Column(
      children: [
        ...displayCases.map((c) {
          final isEmergency = c.priority == 'Emergency';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppTheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.surfaceLight),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaseDetailScreen(caseRecord: c),
                  ),
                );
                await _loadData();
              },
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 20),
              ),
              title: Text(
                c.procedure,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    '${c.specialty} · ${c.technique}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _fmtD(c.date),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isEmergency
                              ? Colors.red.withValues(alpha: 0.12)
                              : Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.priority,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isEmergency ? Colors.red : Colors.blue,
                          ),
                        ),
                      ),
                      if (c.verifiedBy != null && c.verifiedBy!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'By: ${c.verifiedBy}',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                ],
              ),
            ),
          );
        }),
        if (verifiedCases.length > 25)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '+ ${verifiedCases.length - 25} more verified cases in logbook',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCertificateCard(SignOffRecord r, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.surfaceLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: r.isConsultantAttestation
                        ? Colors.amber.withValues(alpha: 0.15)
                        : AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.isConsultantAttestation
                        ? 'Consultant Attestation'
                        : 'Trainee Supervisor Sign-Off',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: r.isConsultantAttestation
                          ? (isDark ? Colors.amber.shade300 : Colors.amber.shade900)
                          : AppTheme.primary,
                    ),
                  ),
                ),
                Text(
                  _fmtD(r.date),
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.isConsultantAttestation
                            ? 'Dr. ${r.doctorName}'
                            : 'Supervisor: Dr. ${r.supervisorName}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        r.supervisorDesignation,
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      if (r.supervisorHospital.isNotEmpty)
                        Text(
                          r.supervisorHospital,
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '${r.casesCount} cases verified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
                // Signature thumbnail preview
                Container(
                  height: 48,
                  width: 80,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Image.memory(r.signatureBytes, fit: BoxFit.contain),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete Sign-Off Record?'),
                        content: const Text(
                            'This will delete the saved record from history. Verified case flags will remain intact.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppTheme.danger),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await SignatureStorage.deleteSignOff(r.id);
                      await _loadData();
                    }
                  },
                  icon: Icon(Icons.delete_outline,
                      size: 16, color: AppTheme.danger),
                  label: Text('Delete',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.danger)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Find matching cases
                    final matched = _allCases
                        .where((c) => r.caseIds.contains(c.id))
                        .toList();
                    await PdfService.generateSignOffReportPdf(
                      r,
                      matched.isNotEmpty ? matched : _allCases,
                      r.signatureBytes,
                      counterSignatureBytes: r.counterSignatureBytes,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('Export PDF',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtD(DateTime d) {
    const m = [
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
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

/// Marquee tab label widget that gently auto-scrolls horizontally from right to left
/// when selected if the title overflows available tab width.
class _MarqueeTabLabel extends StatefulWidget {
  final String text;
  final bool isSelected;
  final TextStyle style;

  const _MarqueeTabLabel({
    required this.text,
    required this.isSelected,
    required this.style,
  });

  @override
  State<_MarqueeTabLabel> createState() => _MarqueeTabLabelState();
}

class _MarqueeTabLabelState extends State<_MarqueeTabLabel> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _disposed = false;
  int _cycleId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
    }
  }

  @override
  void didUpdateWidget(covariant _MarqueeTabLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _stopAnimation();
    }
  }

  void _stopAnimation() {
    _cycleId++;
    _timer?.cancel();
    _timer = null;
    if (_scrollController.hasClients && _scrollController.offset != 0) {
      _scrollController.jumpTo(0);
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = null;
    final currentCycle = ++_cycleId;

    _timer = Timer(const Duration(milliseconds: 700), () async {
      if (_disposed || !widget.isSelected || currentCycle != _cycleId) return;

      while (mounted &&
          widget.isSelected &&
          currentCycle == _cycleId &&
          _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) break;

        // Scroll from right to left smoothly
        final scrollDuration = Duration(
            milliseconds: (maxScroll * 45).toInt().clamp(1500, 4000));
        await _scrollController.animateTo(
          maxScroll,
          duration: scrollDuration,
          curve: Curves.easeInOut,
        );

        if (_disposed || !widget.isSelected || currentCycle != _cycleId) break;
        final c1 = Completer<void>();
        _timer = Timer(const Duration(milliseconds: 1400), () {
          if (!c1.isCompleted) c1.complete();
        });
        await c1.future;

        if (_disposed || !widget.isSelected || currentCycle != _cycleId) break;
        // Scroll back to the beginning
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
        );

        if (_disposed || !widget.isSelected || currentCycle != _cycleId) break;
        final c2 = Completer<void>();
        _timer = Timer(const Duration(milliseconds: 1600), () {
          if (!c2.isCompleted) c2.complete();
        });
        await c2.future;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          style: widget.style,
        ),
      ),
    );
  }
}
