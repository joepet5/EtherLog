import 'package:shared_preferences/shared_preferences.dart';

class PdfPreferences {
  final bool includeHospitalNumbers;
  final bool includePatientDetails;
  final bool includeTimes;
  final bool includeRegional;
  final bool includeAirway;
  final bool includeInvasive;
  final bool includeComplications;
  final bool includeSummaryTables;
  final bool includeSignatureBlock;

  /// When true, full logbook PDF only includes cases between [fromDate] and [toDate].
  final bool useDateRange;
  final DateTime? fromDate;
  final DateTime? toDate;

  const PdfPreferences({
    this.includeHospitalNumbers = true,
    this.includePatientDetails = true,
    this.includeTimes = true,
    this.includeRegional = true,
    this.includeAirway = true,
    this.includeInvasive = true,
    this.includeComplications = true,
    this.includeSummaryTables = true,
    this.includeSignatureBlock = true,
    this.useDateRange = false,
    this.fromDate,
    this.toDate,
  });

  PdfPreferences copyWith({
    bool? includeHospitalNumbers,
    bool? includePatientDetails,
    bool? includeTimes,
    bool? includeRegional,
    bool? includeAirway,
    bool? includeInvasive,
    bool? includeComplications,
    bool? includeSummaryTables,
    bool? includeSignatureBlock,
    bool? useDateRange,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return PdfPreferences(
      includeHospitalNumbers: includeHospitalNumbers ?? this.includeHospitalNumbers,
      includePatientDetails: includePatientDetails ?? this.includePatientDetails,
      includeTimes: includeTimes ?? this.includeTimes,
      includeRegional: includeRegional ?? this.includeRegional,
      includeAirway: includeAirway ?? this.includeAirway,
      includeInvasive: includeInvasive ?? this.includeInvasive,
      includeComplications: includeComplications ?? this.includeComplications,
      includeSummaryTables: includeSummaryTables ?? this.includeSummaryTables,
      includeSignatureBlock: includeSignatureBlock ?? this.includeSignatureBlock,
      useDateRange: useDateRange ?? this.useDateRange,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }

  static const _kHospital = 'pdf_include_hospital_numbers';
  static const _kPatient = 'pdf_include_patient_details';
  static const _kTimes = 'pdf_include_times';
  static const _kRegional = 'pdf_include_regional';
  static const _kAirway = 'pdf_include_airway';
  static const _kInvasive = 'pdf_include_invasive';
  static const _kComplications = 'pdf_include_complications';
  static const _kSummary = 'pdf_include_summary_tables';
  static const _kSignature = 'pdf_include_signature_block';
  static const _kUseRange = 'pdf_use_date_range';
  static const _kFrom = 'pdf_from_date';
  static const _kTo = 'pdf_to_date';

  static Future<PdfPreferences> load() async {
    final p = await SharedPreferences.getInstance();
    DateTime? parse(String? iso) {
      if (iso == null || iso.isEmpty) return null;
      return DateTime.tryParse(iso);
    }

    return PdfPreferences(
      includeHospitalNumbers: p.getBool(_kHospital) ?? true,
      includePatientDetails: p.getBool(_kPatient) ?? true,
      includeTimes: p.getBool(_kTimes) ?? true,
      includeRegional: p.getBool(_kRegional) ?? true,
      includeAirway: p.getBool(_kAirway) ?? true,
      includeInvasive: p.getBool(_kInvasive) ?? true,
      includeComplications: p.getBool(_kComplications) ?? true,
      includeSummaryTables: p.getBool(_kSummary) ?? true,
      includeSignatureBlock: p.getBool(_kSignature) ?? true,
      useDateRange: p.getBool(_kUseRange) ?? false,
      fromDate: parse(p.getString(_kFrom)),
      toDate: parse(p.getString(_kTo)),
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kHospital, includeHospitalNumbers);
    await p.setBool(_kPatient, includePatientDetails);
    await p.setBool(_kTimes, includeTimes);
    await p.setBool(_kRegional, includeRegional);
    await p.setBool(_kAirway, includeAirway);
    await p.setBool(_kInvasive, includeInvasive);
    await p.setBool(_kComplications, includeComplications);
    await p.setBool(_kSummary, includeSummaryTables);
    await p.setBool(_kSignature, includeSignatureBlock);
    await p.setBool(_kUseRange, useDateRange);
    if (fromDate != null) {
      await p.setString(_kFrom, fromDate!.toIso8601String());
    } else {
      await p.remove(_kFrom);
    }
    if (toDate != null) {
      await p.setString(_kTo, toDate!.toIso8601String());
    } else {
      await p.remove(_kTo);
    }
  }

  /// Filter a case list using these preferences. No-op if date range is off.
  List<T> filterCasesByDate<T>(
      List<T> cases,
      DateTime Function(T item) dateOf,
      ) {
    if (!useDateRange) return cases;
    final from = fromDate;
    final to = toDate;
    if (from == null && to == null) return cases;

    final start = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final end = to == null
        ? null
        : DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    return cases.where((c) {
      final d = dateOf(c);
      if (start != null && d.isBefore(start)) return false;
      if (end != null && d.isAfter(end)) return false;
      return true;
    }).toList();
  }
}