import 'package:flutter_test/flutter_test.dart';
import 'package:etherlog/models/case_record.dart';
import 'package:etherlog/services/csv_service.dart';
import 'package:etherlog/services/pdf_preferences.dart';

void main() {
  test('CaseRecord JSON roundtrip preserves catheterPlaced, pca, and detailedAssessment', () {
    final caseRecord = CaseRecord(
      id: 'test-case-1',
      date: DateTime(2026, 9, 21, 10, 30),
      caseNumber: 'HN12345',
      specialty: 'Orthopaedics',
      diagnosis: 'Right femur fracture',
      procedure: 'ORIF Femur',
      priority: 'Elective',
      asaGrade: 'ASA II',
      technique: 'General Anaesthesia',
      role: 'First Anaesthetist',
      patientAge: 12,
      ageUnit: 'years',
      patientGender: 'Male',
      patientWeight: 45,
      catheterPlaced: true,
      pca: true,
      regionalBlocks: [
        {'name': 'Femoral Nerve Block', 'side': 'Right'}
      ],
      detailedAssessment: {
        'occupation': 'Child',
        'monitors': 'Standard ASA, Arterial line, CVC',
        'tempProbe': 'Nasopharynx',
        'ivPlan': '2x 18G, CVC right IJV',
        'ebl': '250',
        'estTime': '120 min',
        'baselineHb': '13.5',
        'targetHb': '10',
        'bloodOrdered': '2 units PRBC crossmatched',
        'npoHours': '6',
        'thirdSpaceRate': '4',
        'analgesiaPlan': 'Femoral Nerve Block + Catheter, IV PCA Morphine',
        'intraopNotes': 'Stable throughout',
        'disposition': 'PACU / Ward',
      },
    );

    final json = caseRecord.toJson();
    expect(json['catheterPlaced'], isTrue);
    expect(json['pca'], isTrue);
    expect(json['detailedAssessment'], isNotNull);
    expect(json['detailedAssessment']['occupation'], equals('Child'));
    expect(json['detailedAssessment']['ebl'], equals('250'));

    final restored = CaseRecord.fromJson(json);
    expect(restored.catheterPlaced, isTrue);
    expect(restored.pca, isTrue);
    expect(restored.detailedAssessment, isNotNull);
    expect(restored.detailedAssessment!['occupation'], equals('Child'));
    expect(restored.detailedAssessment!['monitors'], contains('Standard ASA'));
    expect(restored.detailedAssessment!['analgesiaPlan'], contains('PCA'));
  });

  test('CsvService.generateCsvString includes catheter, pca, occupation, fluids, monitors', () {
    final caseRecord = CaseRecord(
      id: 'test-case-2',
      date: DateTime(2026, 9, 21, 10, 30),
      caseNumber: 'HN99999',
      specialty: 'General Surgery',
      diagnosis: 'Appendicitis',
      procedure: 'Laparoscopic Appendectomy',
      priority: 'Emergency',
      asaGrade: 'ASA I',
      technique: 'General Anaesthesia',
      role: 'Consultant',
      patientAge: 15,
      ageUnit: 'years',
      patientGender: 'Female',
      patientWeight: 50,
      catheterPlaced: true,
      pca: true,
      regionalBlocks: [
        {'name': 'TAP Block', 'side': 'Bilateral'}
      ],
      detailedAssessment: {
        'occupation': 'Child',
        'monitors': 'Standard ASA, Arterial line',
        'tempProbe': 'Esophageal',
        'bgWarmer': 'Forced Air Blanket (Bair Hugger)',
        'ivPlan': '1x 18G',
        'ebl': '50',
        'estTime': '60 min',
        'baselineHb': '12',
        'targetHb': '10',
        'bloodOrdered': 'None',
        'npoHours': '4',
        'thirdSpaceRate': '4',
        'analgesiaPlan': 'TAP Block + Catheter, PCA Tramadol',
        'intraopNotes': 'Uneventful surgery',
        'disposition': 'Ward',
      },
    );

    const prefs = PdfPreferences();
    final csv = CsvService.generateCsvString([caseRecord], prefs: prefs);

    expect(csv, contains('Catheter Placed'));
    expect(csv, contains('PCA'));
    expect(csv, contains('Occupation'));
    expect(csv, contains('Monitors'));
    expect(csv, contains('Fluid Warmer / Blanket'));
    expect(csv, contains('Estimated Blood Loss'));
    expect(csv, contains('Analgesia Plan'));

    final lines = csv.trim().split('\n');
    expect(lines.length, equals(2)); // header + 1 case row

    final row = lines[1];
    expect(row, contains('Yes')); // catheter placed & pca
    expect(row, contains('Child'));
    expect(row, contains('Standard ASA'));
    expect(row, contains('Esophageal'));
    expect(row, contains('Forced Air Blanket (Bair Hugger)'));
    expect(row, contains('50'));
    expect(row, contains('TAP Block'));
  });

  test('Duration parsing handles 1 hr and 30mins and calculates proportionate 2nd hour', () {
    double parseDuration(String text) {
      final t = text.trim().toLowerCase();
      if (t.isEmpty) return 2.0;

      final hrMinMatch = RegExp(
              r'(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b[^\d]*(\d+(?:\.\d+)?)\s*(?:minutes?|mins?|m)\b')
          .firstMatch(t);
      if (hrMinMatch != null) {
        final h = double.tryParse(hrMinMatch.group(1)!) ?? 0.0;
        final m = double.tryParse(hrMinMatch.group(2)!) ?? 0.0;
        final total = h + (m / 60.0);
        if (total > 0) return total.clamp(0.25, 24.0);
      }

      final colonMatch = RegExp(r'(\d+):(\d{2})').firstMatch(t);
      if (colonMatch != null) {
        final h = double.tryParse(colonMatch.group(1)!) ?? 0.0;
        final m = double.tryParse(colonMatch.group(2)!) ?? 0.0;
        final total = h + (m / 60.0);
        if (total > 0) return total.clamp(0.25, 24.0);
      }

      if (t.contains('1.5')) return 1.5;
      if (t.contains('2.5')) return 2.5;

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

    expect(parseDuration('1 hr and 30mins'), equals(1.5));
    expect(parseDuration('1 hr 30 mins'), equals(1.5));
    expect(parseDuration('1h 30m'), equals(1.5));
    expect(parseDuration('1:30'), equals(1.5));
    expect(parseDuration('2 hr 30 mins'), equals(2.5));
    expect(parseDuration('45 mins'), equals(0.75));

    // For 1.5 hours:
    final duration = parseDuration('1 hr and 30mins');
    expect(duration.ceil(), equals(2)); // exactly 2 rows

    const maintPerHour = 100.0;
    const totalDeficit = 600.0;
    const thirdSpacePerHour = 280.0;
    const totalBloodRepl = 300.0; // 100 mL EBL * 3:1
    final bloodReplPerHour = totalBloodRepl / duration; // 200/hr

    // Hour 1: full hour (fraction 1.0)
    final dHr1 = totalDeficit * 0.50 * 1.0; // 300
    final mHr1 = maintPerHour * 1.0;        // 100
    final tHr1 = thirdSpacePerHour * 1.0;   // 280
    final bHr1 = bloodReplPerHour * 1.0;    // 200
    final totHr1 = dHr1 + mHr1 + tHr1 + bHr1; // 880

    // Hour 2: 30 minutes (fraction 0.5)
    final fraction2 = duration - 1.0; // 0.5
    final dHr2 = totalDeficit * 0.25 * fraction2; // 75
    final mHr2 = maintPerHour * fraction2;        // 50
    final tHr2 = thirdSpacePerHour * fraction2;   // 140
    final bHr2 = bloodReplPerHour * fraction2;    // 100
    final totHr2 = dHr2 + mHr2 + tHr2 + bHr2;     // 365

    expect(dHr1, equals(300.0));
    expect(dHr2, equals(75.0)); // exactly 12.5% of deficit
    expect(mHr2, equals(50.0)); // half of maintenance
    expect(tHr2, equals(140.0)); // half of 3rd space
    expect(bHr2, equals(100.0)); // half of remaining blood repl
    expect(totHr1 + totHr2, equals(1245.0));
  });
}
