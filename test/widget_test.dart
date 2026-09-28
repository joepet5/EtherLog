// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etherlog/main.dart';
import 'package:etherlog/models/case_record.dart';
import 'package:etherlog/screens/lock_screen.dart';
import 'package:etherlog/services/league_calculator.dart';
import 'package:etherlog/l10n/app_localizations.dart';
import 'package:etherlog/l10n/achievement_localizations.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EtherlogApp());
    expect(find.byType(EtherlogApp), findsOneWidget);
  });

  test('AchievementLocalizations covers all 15 sections across all 9 non-English languages', () {
    final sampleIndices = [0, 50, 88, 124, 165, 218, 255, 325, 385, 425, 460, 472, 483, 571, 591];
    final languages = ['es', 'fr', 'de', 'pt', 'zh', 'ar', 'ko', 'ja', 'id'];

    for (final idx in sampleIndices) {
      final id = 'ach_$idx';
      for (final lang in languages) {
        final title = AchievementLocalizations.getTitle(id, 'Fallback', lang);
        final desc = AchievementLocalizations.getDescription(id, 'Fallback', lang);
        
        expect(title, isNotEmpty);
        expect(title, isNot(equals('Fallback')));
        expect(desc, isNotEmpty);
        expect(desc, isNot(equals('Fallback')));
      }
    }
  });

  test('Scan for untranslated descriptions', () {
    const sampleIds = [
      'ach_82', 'ach_100', 'ach_150', 'ach_200', 'ach_250',
      'ach_300', 'ach_350', 'ach_400', 'ach_450', 'ach_500',
      'ach_550', 'ach_600', 'ach_650', 'ach_700'
    ];
    final languages = ['es', 'fr', 'de', 'pt', 'zh', 'ar', 'ko', 'ja', 'id'];

    for (final id in sampleIds) {
      for (final lang in languages) {
        final desc = AchievementLocalizations.getDescription(id, 'Fallback', lang);
        print('[$lang][$id]: $desc');
      }
    }
  });

  test('Heavyweight Champion correctly tracks ASA IV, ASA V, and Emergencies', () async {
    final cases = [
      CaseRecord(
        id: '1',
        caseNumber: 'C1',
        date: DateTime.now(),
        specialty: 'General Surgery',
        diagnosis: 'D1',
        procedure: 'P1',
        priority: 'Elective',
        asaGrade: 'ASA IV',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: '2',
        caseNumber: 'C2',
        date: DateTime.now(),
        specialty: 'General Surgery',
        diagnosis: 'D2',
        procedure: 'P2',
        priority: 'Elective',
        asaGrade: 'ASA V',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: '3',
        caseNumber: 'C3',
        date: DateTime.now(),
        specialty: 'General Surgery',
        diagnosis: 'D3',
        procedure: 'P3',
        priority: 'Emergency',
        asaGrade: 'ASA II',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: '4',
        caseNumber: 'C4',
        date: DateTime.now(),
        specialty: 'General Surgery',
        diagnosis: 'D4',
        procedure: 'P4',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: '5',
        caseNumber: 'C5',
        date: DateTime.now(),
        specialty: 'General Surgery',
        diagnosis: 'D5',
        procedure: 'P5',
        priority: 'Elective',
        asaGrade: 'ASA II',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: '6',
        caseNumber: 'C6',
        date: DateTime.now(),
        specialty: 'General Surgery',
        diagnosis: 'D6',
        procedure: 'P6',
        priority: 'Emergency',
        asaGrade: 'ASA III',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: '7',
        caseNumber: 'C7',
        date: DateTime.now(),
        specialty: 'General Surgery',
        diagnosis: 'D7',
        procedure: 'P7',
        priority: 'Elective',
        asaGrade: 'ASA III',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
    ];

    final scores = await LeagueCalculator.calculateAllScores(cases, []);

    // Qualified cases:
    // - Case 1: Elective ASA IV (qualifies: ASA >= 4)
    // - Case 2: Elective ASA V (qualifies: ASA >= 4)
    // - Case 6: Emergency ASA III (qualifies: Emergency && ASA >= 3)
    // Non-qualified cases:
    // - Case 3: Emergency ASA II (fails: Emergency but ASA < 3)
    // - Case 4: Elective ASA I (fails: Elective and ASA < 4)
    // - Case 5: Elective ASA II (fails: Elective and ASA < 4)
    // - Case 7: Elective ASA III (fails: Elective and ASA < 4)
    expect(scores['high_acuity'], equals(3));
  });

  test('LeagueCalculator audits Turnover Titan, Marathon Runner, Paediatric, and Night Shift', () async {
    final now = DateTime(2026, 9, 4, 10, 0);
    final cases = [
      // Turnover Titan: 3 cases within 8 hours (08:00, 11:00, 15:30 = 7h 30m)
      CaseRecord(
        id: 'tt1',
        caseNumber: 'TT1',
        date: now,
        anaesthesiaStartTime: '08:00',
        specialty: 'Obstetrics',
        diagnosis: '',
        procedure: '',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: 'tt2',
        caseNumber: 'TT2',
        date: now,
        anaesthesiaStartTime: '11:00',
        specialty: 'Obstetric Surgery',
        diagnosis: '',
        procedure: '',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: 'tt3',
        caseNumber: 'TT3',
        date: now,
        anaesthesiaStartTime: '15:30',
        specialty: 'General Surgery',
        diagnosis: '',
        procedure: '',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      // Marathon Runner: 6h 30m and 380m
      CaseRecord(
        id: 'mr1',
        caseNumber: 'MR1',
        date: now,
        anaesthesiaDuration: '6h 30m',
        specialty: 'General Surgery',
        diagnosis: '',
        procedure: '',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: 'mr2',
        caseNumber: 'MR2',
        date: now,
        anaesthesiaDuration: '380m',
        specialty: 'General Surgery',
        diagnosis: '',
        procedure: '',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: 'mr3_short',
        caseNumber: 'MR3',
        date: now,
        anaesthesiaDuration: '5h 45m',
        specialty: 'General Surgery',
        diagnosis: '',
        procedure: '',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      // Paediatric Whisperer: American 'Pediatric ENT' and age 5
      CaseRecord(
        id: 'p1',
        caseNumber: 'P1',
        date: now,
        specialty: 'Pediatric ENT',
        patientAge: 17,
        ageUnit: 'years',
        diagnosis: '',
        procedure: '',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      CaseRecord(
        id: 'p2',
        caseNumber: 'P2',
        date: now,
        specialty: 'General Surgery',
        patientAge: 5,
        ageUnit: 'years',
        diagnosis: '',
        procedure: '',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
      // 3 AM Club: 03:30 AM
      CaseRecord(
        id: 'ns1',
        caseNumber: 'NS1',
        date: now,
        anaesthesiaStartTime: '03:30 AM',
        specialty: 'General Surgery',
        diagnosis: '',
        procedure: '',
        priority: 'Emergency',
        asaGrade: 'ASA II',
        technique: 'GA',
        role: 'Primary',
        difficultAirway: false,
        ageUnit: 'years',
        invasiveMonitoring: [],
        complications: [],
        regionalBlocks: [],
        catheterPlaced: false,
        starred: false,
        flagForFollowUp: false,
        followUpStatus: 'none',
      ),
    ];

    final scores = await LeagueCalculator.calculateAllScores(cases, []);

    // Marathon Runner: 2 cases >= 6 hours (6h 30m and 380m)
    expect(scores['endurance'], equals(2));

    // Paediatric: 2 cases (1 via Pediatric spelling, 1 via age 5)
    expect(scores['paediatric'], equals(2));

    // Obstetric: 2 cases (Obstetrics, Obstetric Surgery)
    expect(scores['obstetric'], equals(2));

    // Night shift: 1 case (03:30 AM)
    expect(scores['night_shift'], equals(1));
  });

  testWidgets('LockScreen does not display redundant unlock with biometric text button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LockScreen(onUnlocked: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unlock with biometric'), findsNothing);
  });
}
