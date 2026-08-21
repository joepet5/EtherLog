import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/case_record.dart';
import '../models/doctor_profile.dart';
import '../services/profile_storage.dart';
import '../services/pdf_preferences.dart';

class PdfService {
  static String _fmtRegional(Map<String, dynamic> e) {
    final name = e['name']?.toString() ?? '';
    if (name == 'None / Not performed') return name;
    final parts = <String>[name, e['role']?.toString() ?? ''];
    if (e['usgGuided'] == true) parts.add('USG');
    if (e['nerveStimulator'] == true) parts.add('NS');
    return parts.join(' · ');
  }

  static String _fmtInvasive(Map<String, dynamic> e) {
    final parts = <String>[e['name']?.toString() ?? '', e['role']?.toString() ?? ''];
    if (e['usgGuided'] == true) parts.add('USG');
    return parts.join(' · ');
  }

  // ========== SINGLE CASE PDF ==========
  static Future<void> generateCasePdf(
      CaseRecord caseRecord, {
        PdfPreferences? prefs,
      }) async {
    final options = prefs ?? await PdfPreferences.load();
    final profile = await ProfileStorage.getProfile();
    final pdf = pw.Document();

    pw.MemoryImage? caseSheetImage;
    if (caseRecord.caseSheetImagePath != null) {
      try {
        final file = File(caseRecord.caseSheetImagePath!);
        if (await file.exists()) {
          caseSheetImage = pw.MemoryImage(await file.readAsBytes());
        }
      } catch (_) {}
    }

    final realRegional = caseRecord.regionalBlocks
        .where((e) => e['name'] != 'None / Not performed')
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            _buildOfficialHeader(profile),
            pw.SizedBox(height: 12),
            pw.Text(
              caseRecord.procedure,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              caseRecord.specialty,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),

            if (caseSheetImage != null) ...[
              _sectionTitle('CASE SHEET PHOTO'),
              pw.SizedBox(height: 6),
              pw.Image(caseSheetImage, height: 150, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 12),
            ],

            _sectionTitle('CASE INFORMATION'),
            _row('Date', _fmtDate(caseRecord.date)),
            if (options.includeTimes) ...[
              _row(
                'Anaesthesia',
                '${caseRecord.anaesthesiaStartTime ?? '-'} - ${caseRecord.anaesthesiaEndTime ?? '-'}',
              ),
              _row('Anaesthesia Duration', caseRecord.anaesthesiaDuration ?? '-'),
              _row(
                'Surgery',
                '${caseRecord.surgeryStartTime ?? '-'} - ${caseRecord.surgeryEndTime ?? '-'}',
              ),
              _row('Surgical Duration', caseRecord.surgeryDuration ?? '-'),
            ],
            if (options.includeHospitalNumbers)
              _row(
                'Case / Hospital No.',
                caseRecord.caseNumber.isEmpty ? '-' : caseRecord.caseNumber,
              ),
            _row('Hospital', caseRecord.hospital ?? '-'),
            _row('Priority', caseRecord.priority),
            _row('ASA Grade', caseRecord.asaGrade),
            pw.SizedBox(height: 10),

            if (options.includePatientDetails) ...[
              _sectionTitle('PATIENT'),
              _row(
                'Age / Gender',
                '${caseRecord.patientAge ?? '-'} ${caseRecord.ageUnit} / ${caseRecord.patientGender ?? '-'}',
              ),
              _row(
                'Weight',
                caseRecord.patientWeight != null ? '${caseRecord.patientWeight} kg' : '-',
              ),
              _row(
                'Height',
                caseRecord.patientHeight != null ? '${caseRecord.patientHeight} cm' : '-',
              ),
              _row(
                'BMI',
                caseRecord.bmi != null ? caseRecord.bmi!.toStringAsFixed(1) : '-',
              ),
              pw.SizedBox(height: 10),
            ],

            _sectionTitle('PROCEDURE & ANAESTHESIA'),
            _row('Diagnosis', caseRecord.diagnosis.isEmpty ? '-' : caseRecord.diagnosis),
            _row('Procedure', caseRecord.procedure),
            _row('Specialty', caseRecord.specialty),
            _row('Technique', caseRecord.technique),
            _row('Role', caseRecord.role),
            if (caseRecord.role != 'Consultant')
              _row('Supervisor', caseRecord.supervisor ?? '-'),
            pw.SizedBox(height: 10),

            if (options.includeRegional && realRegional.isNotEmpty) ...[
              _sectionTitle('REGIONAL ANAESTHESIA'),
              _row('Blocks', realRegional.map(_fmtRegional).join(', ')),
              if (caseRecord.catheterPlaced)
                _row('Catheter', 'Placed (continuous infusion / post-op boluses)'),
              pw.SizedBox(height: 10),
            ],

            if (options.includeAirway) ...[
              _sectionTitle('AIRWAY'),
              _row('Airway Management', caseRecord.airwayManagement ?? '-'),
              if (caseRecord.typeOfIntubation != null)
                _row('Type of intubation', caseRecord.typeOfIntubation!),
              if (caseRecord.methodOfIntubation != null)
                _row('Method of intubation', caseRecord.methodOfIntubation!),
              if (caseRecord.methodOfIntubationRole != null)
                _row('Intubation role', caseRecord.methodOfIntubationRole!),
              if (caseRecord.ettType != null) _row('ETT type', caseRecord.ettType!),
              if (caseRecord.ettSize != null) _row('ETT size', caseRecord.ettSize!.toString()),
              if (caseRecord.lmaType != null) _row('LMA type', caseRecord.lmaType!),
              if (caseRecord.lmaRole != null) _row('LMA role', caseRecord.lmaRole!),
              if (caseRecord.lmaSize != null) _row('LMA size', caseRecord.lmaSize!.toString()),
              _row('Cormack-Lehane', caseRecord.cormackLehane ?? '-'),
              _row('Difficult Airway', caseRecord.difficultAirway ? 'Yes' : 'No'),
              if (caseRecord.difficultAirway && caseRecord.difficultAirwayAttempts != null)
                _row('Attempts', '${caseRecord.difficultAirwayAttempts}'),
              pw.SizedBox(height: 10),
            ],

            if (options.includeInvasive && caseRecord.invasiveMonitoring.isNotEmpty) ...[
              _sectionTitle('INVASIVE LINES & MONITORING'),
              pw.Text(
                caseRecord.invasiveMonitoring.map(_fmtInvasive).join(', '),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 10),
            ],

            if (options.includeComplications && caseRecord.complications.isNotEmpty) ...[
              _sectionTitle('COMPLICATIONS'),
              pw.Text(
                caseRecord.complications.join(', '),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 10),
            ],

            if (caseRecord.outcome != null && caseRecord.outcome!.isNotEmpty) ...[
              _sectionTitle('OUTCOME'),
              pw.Text(caseRecord.outcome!, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 10),
            ],

            if (caseRecord.notes != null && caseRecord.notes!.isNotEmpty) ...[
              _sectionTitle('NOTES'),
              pw.Text(caseRecord.notes!, style: const pw.TextStyle(fontSize: 9)),
            ],

            if (options.includeSignatureBlock) ...[
              pw.SizedBox(height: 24),
              _signatureBlock(profile),
            ],
          ];
        },
        footer: (context) => _footer(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'ETHERLOG_${caseRecord.procedure.replaceAll(' ', '_')}',
    );
  }

  // ========== FULL LOGBOOK REPORT ==========
  static Future<void> generateAllCasesPdf(
      List<CaseRecord> cases, {
        PdfPreferences? prefs,
        bool includeHospitalNumbers = true, // kept for older call sites
      }) async {
    if (cases.isEmpty) return;

    final options = prefs ??
        (await PdfPreferences.load()).copyWith(
          includeHospitalNumbers: includeHospitalNumbers,
        );
    // If caller only passed the old flag without prefs object:
    if (prefs == null && includeHospitalNumbers == false) {
      // already applied via copyWith above when defaults load
    }

    final profile = await ProfileStorage.getProfile();
    final pdf = pw.Document();

    final total = cases.length;
    final elective = cases.where((c) => c.priority == 'Elective').length;
    final emergency = cases.where((c) => c.priority == 'Emergency').length;
    final difficult = cases.where((c) => c.difficultAirway).length;

    final specialtyMap = <String, int>{};
    for (final c in cases) {
      specialtyMap[c.specialty] = (specialtyMap[c.specialty] ?? 0) + 1;
    }
    final specialtyEntries = specialtyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final techniqueMap = <String, int>{};
    for (final c in cases) {
      techniqueMap[c.technique] = (techniqueMap[c.technique] ?? 0) + 1;
    }
    final techniqueEntries = techniqueMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedCases = List<CaseRecord>.from(cases)
      ..sort((a, b) => a.date.compareTo(b.date));

    final showHosp = options.includeHospitalNumbers;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 28),
        build: (context) {
          return [
            _buildOfficialHeader(profile),
            pw.SizedBox(height: 10),

            pw.Text(
              'ANAESTHETIC CLINICAL LOGBOOK & AUDIT REPORT',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal700,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              showHosp
                  ? 'Total Cases Logged: $total records'
                  : 'Total Cases Logged: $total records (hospital numbers omitted)',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 14),

            pw.Row(
              children: [
                _summaryCard('Total Cases', '$total'),
                pw.SizedBox(width: 8),
                _summaryCard('Elective Cases', '$elective'),
                pw.SizedBox(width: 8),
                _summaryCard('Emergency Cases', '$emergency'),
                pw.SizedBox(width: 8),
                _summaryCard('Difficult Airway', '$difficult'),
              ],
            ),
            pw.SizedBox(height: 18),

            if (options.includeSummaryTables) ...[
              pw.Text(
                'I. Clinical Summary Breakdown Statistics',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _breakdownTable(
                      title: 'Specialty',
                      entries: specialtyEntries,
                      total: total,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _breakdownTable(
                      title: 'Anaesthetic Technique',
                      entries: techniqueEntries,
                      total: total,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'II. Detailed Case Log Records',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ] else ...[
              pw.Text(
                'Detailed Case Log Records',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
            pw.SizedBox(height: 8),

            pw.Container(
              color: PdfColors.teal700,
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: pw.Row(
                children: [
                  pw.SizedBox(width: 18, child: _th('#')),
                  pw.SizedBox(
                    width: 72,
                    child: _th(showHosp ? 'Date / Hosp No' : 'Date'),
                  ),
                  if (options.includePatientDetails)
                    pw.SizedBox(width: 58, child: _th('Patient')),
                  pw.SizedBox(width: 95, child: _th('Procedure & Specialty')),
                  pw.SizedBox(width: 90, child: _th('Technique & Airway')),
                  pw.SizedBox(width: 55, child: _th('Role')),
                  pw.Expanded(child: _th('Clinical Remarks')),
                ],
              ),
            ),

            ...sortedCases.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final c = entry.value;
              final isEven = i % 2 == 0;

              final patientStr = [
                if (c.patientAge != null)
                  '${c.patientAge}${c.ageUnit.isNotEmpty ? c.ageUnit[0] : ''}',
                if (c.patientGender != null) c.patientGender![0].toUpperCase(),
                c.asaGrade,
              ].where((e) => e.isNotEmpty).join('/');

              final timeRange =
              (options.includeTimes &&
                  c.anaesthesiaStartTime != null &&
                  c.anaesthesiaEndTime != null)
                  ? '${c.anaesthesiaStartTime}-${c.anaesthesiaEndTime}'
                  : '';

              final dateHosp = [
                _fmtDate(c.date),
                if (showHosp && c.caseNumber.isNotEmpty) 'Hosp No: ${c.caseNumber}',
                if (timeRange.isNotEmpty) timeRange,
              ].join('\n');

              final procedureSpecialty = '${c.procedure}\n(${c.specialty})';

              final techniqueAirwayParts = <String>[c.technique];
              if (options.includeAirway) {
                if (c.airwayManagement != null && c.airwayManagement != 'Not applicable') {
                  techniqueAirwayParts.add(c.airwayManagement!);
                }
                if (c.ettType != null) techniqueAirwayParts.add(c.ettType!);
                if (c.ettSize != null) techniqueAirwayParts.add('ETT ${c.ettSize}');
                if (c.lmaType != null) techniqueAirwayParts.add(c.lmaType!);
                if (c.lmaSize != null) techniqueAirwayParts.add('LMA ${c.lmaSize}');
                if (c.airwayManagement == 'Endotracheal Tube (ETT)' &&
                    c.cormackLehane != null &&
                    c.cormackLehane != 'Not graded') {
                  techniqueAirwayParts.add('(${c.cormackLehane})');
                }
              }
              final techniqueAirway = techniqueAirwayParts.join('\n');

              final remarks = <String>[];
              if (options.includeRegional) {
                final realRegional = c.regionalBlocks
                    .where((e) => e['name'] != 'None / Not performed')
                    .toList();
                if (realRegional.isNotEmpty) {
                  remarks.add('Regional: ${realRegional.map(_fmtRegional).join('; ')}');
                  if (c.catheterPlaced) remarks.add('Catheter placed');
                }
              }
              if (options.includeInvasive && c.invasiveMonitoring.isNotEmpty) {
                remarks.add(c.invasiveMonitoring.map(_fmtInvasive).join('; '));
              }
              if (options.includeComplications && c.complications.isNotEmpty) {
                remarks.add('Complications: ${c.complications.join(', ')}');
              }
              if (options.includeAirway && c.difficultAirway) {
                remarks.add(
                  c.difficultAirwayAttempts != null
                      ? 'Difficult Airway (${c.difficultAirwayAttempts} attempts)'
                      : 'Difficult Airway',
                );
              }

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.grey100 : PdfColors.white,
                  border: const pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(width: 18, child: _td('$i')),
                    pw.SizedBox(width: 72, child: _td(dateHosp)),
                    if (options.includePatientDetails)
                      pw.SizedBox(
                        width: 58,
                        child: _td(patientStr.isEmpty ? '-' : patientStr),
                      ),
                    pw.SizedBox(width: 95, child: _td(procedureSpecialty)),
                    pw.SizedBox(width: 90, child: _td(techniqueAirway)),
                    pw.SizedBox(width: 55, child: _td(c.role)),
                    pw.Expanded(child: _td(remarks.isEmpty ? '-' : remarks.join('\n'))),
                  ],
                ),
              );
            }),

            if (options.includeSignatureBlock) ...[
              pw.SizedBox(height: 28),
              _signatureBlock(profile),
            ],
          ];
        },
        footer: (context) => _footer(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: showHosp
          ? 'ETHERLOG_Logbook_${_fmtDate(DateTime.now()).replaceAll(' ', '_')}'
          : 'ETHERLOG_Logbook_NoHospNo_${_fmtDate(DateTime.now()).replaceAll(' ', '_')}',
    );
  }

  // ========== STATISTICS PDF ==========
  static Future<void> generateStatisticsPdf(List<CaseRecord> cases) async {
    if (cases.isEmpty) return;
    final profile = await ProfileStorage.getProfile();
    final options = await PdfPreferences.load();
    final pdf = pw.Document();

    final total = cases.length;
    final elective = cases.where((c) => c.priority == 'Elective').length;
    final emergency = cases.where((c) => c.priority == 'Emergency').length;
    final difficult = cases.where((c) => c.difficultAirway).length;

    int? parseDur(String? s) {
      if (s == null) return null;
      final t = s.toLowerCase();
      final h = RegExp(r'(\d+)\s*h').firstMatch(t);
      final m = RegExp(r'(\d+)\s*m').firstMatch(t);
      final hh = h != null ? int.tryParse(h.group(1)!) ?? 0 : 0;
      final mm = m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
      if (hh == 0 && mm == 0) return null;
      return hh * 60 + mm;
    }

    final durs = cases.map((c) => parseDur(c.anaesthesiaDuration)).whereType<int>().toList();
    final avgDur = durs.isEmpty ? null : durs.reduce((a, b) => a + b) / durs.length;

    String fmtAvg(double avg) {
      final t = avg.round();
      final h = t ~/ 60;
      final m = t % 60;
      if (h > 0 && m > 0) return '${h}h ${m}m';
      if (h > 0) return '${h}h';
      return '${m}m';
    }

    double? ageY(CaseRecord c) {
      if (c.patientAge == null) return null;
      switch (c.ageUnit) {
        case 'months':
          return c.patientAge! / 12.0;
        case 'days':
          return c.patientAge! / 365.25;
        default:
          return c.patientAge;
      }
    }

    String ageBand(CaseRecord c) {
      final y = ageY(c);
      if (y == null) return 'Unknown';
      if (y < 28 / 365.25) return 'Neonate (<28 days)';
      if (y < 1) return 'Infant (29 days to 1 year)';
      if (y < 3) return 'Toddler (>1 to <3 years)';
      if (y < 12) return 'Child (>3 to <12 years)';
      if (y < 18) return 'Adolescent (>12 to <18 years)';
      if (y < 65) return 'Adult (18 to <65 years)';
      return 'Elderly (65 years and above)';
    }

    String bmiBand(CaseRecord c) {
      final b = c.bmi;
      if (b == null) return 'Unknown';
      if (b < 18.5) return 'Underweight (<18.5)';
      if (b < 25) return 'Normal (18.5-24.9)';
      if (b < 30) return 'Overweight (25-29.9)';
      if (b < 35) return 'Obese Class I (30-34.9)';
      if (b < 40) return 'Obese Class II (35-39.9)';
      return 'Obese Class III (>=40)';
    }

    Map<String, int> count(Iterable<String> vals) {
      final m = <String, int>{};
      for (final v in vals) {
        if (v.isEmpty) continue;
        m[v] = (m[v] ?? 0) + 1;
      }
      return m;
    }

    List<MapEntry<String, int>> sorted(Map<String, int> m) {
      final l = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return l;
    }

    final ageOrder = [
      'Neonate (<28 days)',
      'Infant (29 days to 1 year)',
      'Toddler (>1 to <3 years)',
      'Child (>3 to <12 years)',
      'Adolescent (>12 to <18 years)',
      'Adult (18 to <65 years)',
      'Elderly (65 years and above)',
      'Unknown',
    ];
    final ageMap = count(cases.map(ageBand));
    final ageEntries = ageOrder
        .where((k) => ageMap.containsKey(k))
        .map((k) => MapEntry(k, ageMap[k]!))
        .toList();

    final bmiMap = count(cases.map(bmiBand));
    final airwayMap = count(cases
        .map((c) => c.airwayManagement ?? '')
        .where((s) => s.isNotEmpty && s != 'Not applicable'));
    final typeMap = count(cases.map((c) => c.typeOfIntubation ?? '').where((s) => s.isNotEmpty));
    final methodMap = count(cases.map((c) => c.methodOfIntubation ?? '').where((s) => s.isNotEmpty));

    final regionalMap = <String, int>{};
    for (final c in cases) {
      for (final e in c.regionalBlocks) {
        final n = e['name']?.toString() ?? '';
        if (n.isEmpty || n == 'None / Not performed') continue;
        regionalMap[n] = (regionalMap[n] ?? 0) + 1;
      }
    }

    final invasiveMap = <String, int>{};
    for (final c in cases) {
      for (final e in c.invasiveMonitoring) {
        final n = e['name']?.toString() ?? '';
        if (n.isEmpty) continue;
        invasiveMap[n] = (invasiveMap[n] ?? 0) + 1;
      }
    }

    Map<String, int> regionalRoles(String blockName) {
      final roles = <String, int>{};
      var catheters = 0;
      for (final c in cases) {
        final matches = c.regionalBlocks.where((e) => (e['name']?.toString() ?? '') == blockName);
        if (matches.isEmpty) continue;
        if (c.catheterPlaced) catheters++;
        for (final e in matches) {
          final role = e['role']?.toString() ?? 'Performed';
          roles[role] = (roles[role] ?? 0) + 1;
        }
      }
      if (catheters > 0) roles['Catheter placed'] = catheters;
      return roles;
    }

    Map<String, int> methodRoles(String method) {
      final roles = <String, int>{};
      for (final c in cases) {
        if (c.methodOfIntubation != method) continue;
        final role = c.methodOfIntubationRole ?? 'Unspecified';
        roles[role] = (roles[role] ?? 0) + 1;
      }
      return roles;
    }

    Map<String, int> invasiveRoles(String itemName) {
      final roles = <String, int>{};
      for (final c in cases) {
        for (final e in c.invasiveMonitoring) {
          if ((e['name']?.toString() ?? '') != itemName) continue;
          final role = e['role']?.toString() ?? 'Performed';
          roles[role] = (roles[role] ?? 0) + 1;
        }
      }
      return roles;
    }

    pw.Widget sectionWithPct(String title, List<MapEntry<String, int>> entries, {int? denom}) {
      if (entries.isEmpty) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            pw.SizedBox(height: 4),
            pw.Text('No data', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 10),
          ],
        );
      }
      final d = denom ?? total;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
          pw.SizedBox(height: 4),
          ...entries.map((e) {
            final pct = d > 0 ? (e.value / d * 100).toStringAsFixed(1) : '0.0';
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 8))),
                  pw.Text('${e.value}  ($pct%)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 10),
        ],
      );
    }

    pw.Widget sectionWithRoles(
        String title,
        List<MapEntry<String, int>> entries,
        Map<String, int> Function(String name) roleBuilder,
        ) {
      if (entries.isEmpty) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            pw.SizedBox(height: 4),
            pw.Text('No data', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 10),
          ],
        );
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
          pw.SizedBox(height: 4),
          ...entries.map((e) {
            final roles = sorted(roleBuilder(e.key));
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(e.key, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Text('${e.value}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  if (roles.isNotEmpty)
                    ...roles.map(
                          (r) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, top: 1),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text('- ${r.key}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                            ),
                            pw.Text('${r.value}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 10),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _buildOfficialHeader(profile),
          pw.SizedBox(height: 10),
          pw.Text(
            'STATISTICS SUMMARY REPORT',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700),
          ),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _summaryCard('Total', '$total'),
            pw.SizedBox(width: 8),
            _summaryCard('Elective', '$elective'),
            pw.SizedBox(width: 8),
            _summaryCard('Emergency', '$emergency'),
            pw.SizedBox(width: 8),
            _summaryCard('Difficult Airway', '$difficult'),
          ]),
          pw.SizedBox(height: 10),
          if (options.includeTimes)
            pw.Text(
              'Average anaesthesia duration: ${avgDur == null ? '-' : fmtAvg(avgDur)}'
                  '${durs.isEmpty ? '' : '  (${durs.length} cases)'}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 14),
          if (options.includePatientDetails) ...[
            sectionWithPct('Division by Age', ageEntries, denom: total),
            sectionWithPct('Division by BMI', sorted(bmiMap), denom: total),
          ],
          if (options.includeRegional)
            sectionWithRoles('Regional blocks by type', sorted(regionalMap), regionalRoles),
          if (options.includeAirway) ...[
            sectionWithPct('Airway management', sorted(airwayMap)),
            sectionWithPct('Type of intubation', sorted(typeMap)),
            sectionWithRoles('Method of intubation', sorted(methodMap), methodRoles),
          ],
          if (options.includeInvasive)
            sectionWithRoles('Invasive lines / Monitoring by type', sorted(invasiveMap), invasiveRoles),
          if (options.includeSignatureBlock) ...[
            pw.SizedBox(height: 16),
            _signatureBlock(profile),
          ],
        ],
        footer: (context) => _footer(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'ETHERLOG_Statistics_${_fmtDate(DateTime.now()).replaceAll(' ', '_')}',
    );
  }

  // ========== HELPERS ==========
  static pw.Widget _buildOfficialHeader(DoctorProfile profile) {
    final dateStr = _fmtDate(DateTime.now());

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ETHERLOG - OFFICIAL ANAESTHESIA CLINICAL LOGBOOK RECORD',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
            pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 8),
        if (profile.name.isNotEmpty) ...[
          pw.Text(
            profile.name,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          if (profile.qualifications.isNotEmpty)
            pw.Text(
              profile.qualifications,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          pw.SizedBox(height: 2),
          pw.Text(
            [
              if (profile.designation.isNotEmpty) profile.designation,
              if (profile.registrationNumber != null && profile.registrationNumber!.isNotEmpty)
                'Reg. No: ${profile.registrationNumber}',
            ].join(' | '),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          if (profile.hospital.isNotEmpty)
            pw.Text(
              profile.hospital,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
        ],
        pw.SizedBox(height: 6),
        pw.Container(height: 1.5, color: PdfColors.teal700),
      ],
    );
  }

  static pw.Widget _signatureBlock(DoctorProfile profile) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              profile.name.isNotEmpty ? 'Dr. ${profile.name}' : '________________',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            if (profile.qualifications.isNotEmpty)
              pw.Text(
                profile.qualifications,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            pw.SizedBox(height: 2),
            pw.Text('Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('________________________', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 2),
            pw.Text(
              'Head of Unit / Department',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Verification Signature & Date',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _breakdownTable({
    required String title,
    required List<MapEntry<String, int>> entries,
    required int total,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          color: PdfColors.teal700,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(
                width: 36,
                child: pw.Text(
                  'Cases',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(
                width: 36,
                child: pw.Text(
                  '%',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        ...entries.map((e) {
          final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0.0';
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 8)),
                ),
                pw.SizedBox(
                  width: 36,
                  child: pw.Text(
                    '${e.value}',
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(
                  width: 36,
                  child: pw.Text(
                    '$pct%',
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _th(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    );
  }

  static pw.Widget _td(String text) {
    return pw.Text(text, style: const pw.TextStyle(fontSize: 7), maxLines: 5);
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.teal800,
      ),
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400, thickness: 0.5),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Anaesthetist Logbook Mobile App | Confidential Medical Record',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}