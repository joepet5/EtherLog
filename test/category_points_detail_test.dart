import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherlog/models/case_record.dart';
import 'package:etherlog/services/case_storage.dart';
import 'package:etherlog/services/points_service.dart';
import 'package:etherlog/screens/points_breakdown_screen.dart';
import 'package:etherlog/screens/category_points_detail_screen.dart';
import 'package:etherlog/l10n/app_localizations.dart';

void main() {
  group('PointsService.getCategoryDetail Unit Tests', () {
    final case1 = CaseRecord(
      id: 'c-1',
      date: DateTime(2026, 5, 10),
      caseNumber: 'HN-101',
      specialty: 'Orthopaedics',
      diagnosis: 'Femur Fracture',
      procedure: 'ORIF Femur',
      priority: 'Emergency',
      asaGrade: 'ASA III',
      technique: 'Regional',
      role: 'Consultant',
      catheterPlaced: true,
      regionalBlocks: [
        {'name': 'Femoral nerve block', 'role': 'Performed'},
        {'name': 'Sciatic nerve block', 'role': 'Assisted'},
      ],
      invasiveMonitoring: [
        {'name': 'Arterial line', 'role': 'Performed'},
      ],
      complications: ['None/uneventful'],
    );

    final case2 = CaseRecord(
      id: 'c-2',
      date: DateTime(2026, 5, 11),
      caseNumber: 'HN-102',
      specialty: 'General Surgery',
      diagnosis: 'Appendicitis',
      procedure: 'Appendectomy',
      priority: 'Elective',
      asaGrade: 'ASA III',
      technique: 'General Anaesthesia',
      role: 'Consultant',
      catheterPlaced: false,
      regionalBlocks: [
        {'name': 'Femoral nerve block', 'role': 'Performed'},
      ],
      invasiveMonitoring: [
        {'name': 'Arterial line', 'role': 'Supervised'},
        {'name': 'Central venous line', 'role': 'Assisted'},
      ],
      complications: ['Laryngospasm'],
    );

    final List<CaseRecord> testCases = [case1, case2];

    test('Base (per case) triggers and points count accurately', () {
      final detail = PointsService.getCategoryDetail('Base (per case)', testCases);
      expect(detail.totalTriggers, 2);
      expect(detail.totalPoints, 20);
      expect(detail.items.first.count, 2);
      expect(detail.items.first.pointsPerTrigger, 10);
      expect(detail.contributingCases.length, 2);
    });

    test('ASA grade breakdown counts triggers per grade correctly', () {
      final detail = PointsService.getCategoryDetail('ASA grade', testCases);
      // Both cases are ASA III (3 pts each -> 6 pts, 2 triggers)
      expect(detail.totalTriggers, 2);
      expect(detail.totalPoints, 6);
      expect(detail.items.length, 1);
      expect(detail.items.first.title, 'ASA Grade III');
      expect(detail.items.first.count, 2);
      expect(detail.items.first.totalPoints, 6);
      expect(detail.contributingCases.length, 2);
    });

    test('Regional blocks breakdown groups by block and counts triggers accurately', () {
      final detail = PointsService.getCategoryDetail('Regional blocks', testCases);
      // Femoral: case1 (Performed = 5), case2 (Performed = 5) -> 2 triggers, 10 pts
      // Sciatic: case1 (Assisted = 2) -> 1 trigger, 2 pts
      expect(detail.totalTriggers, 3);
      expect(detail.totalPoints, 12);
      expect(detail.items.length, 2);

      final femoralItem = detail.items.firstWhere((i) => i.title == 'Femoral nerve block');
      expect(femoralItem.count, 2);
      expect(femoralItem.totalPoints, 10);

      final sciaticItem = detail.items.firstWhere((i) => i.title == 'Sciatic nerve block');
      expect(sciaticItem.count, 1);
      expect(sciaticItem.totalPoints, 2);
      expect(detail.contributingCases.length, 2);
    });

    test('Catheter placed breakdown reflects single trigger case', () {
      final detail = PointsService.getCategoryDetail('Catheter placed', testCases);
      expect(detail.totalTriggers, 1);
      expect(detail.totalPoints, 5);
      expect(detail.items.first.count, 1);
      expect(detail.contributingCases.length, 1);
      expect(detail.contributingCases.first.caseRecord.id, 'c-1');
    });

    test('Invasive lines & monitoring counts lines and roles accurately', () {
      final detail = PointsService.getCategoryDetail('Invasive lines / monitoring', testCases);
      // Arterial line: case1 (Performed = 2), case2 (Supervised = 2) -> 2 triggers, 4 pts
      // Central venous line: case2 (Assisted = 1) -> 1 trigger, 1 pt
      expect(detail.totalTriggers, 3);
      expect(detail.totalPoints, 5);

      final artItem = detail.items.firstWhere((i) => i.title == 'Arterial line');
      expect(artItem.count, 2);
      expect(artItem.totalPoints, 4);

      final cvcItem = detail.items.firstWhere((i) => i.title == 'Central venous line');
      expect(cvcItem.count, 1);
      expect(cvcItem.totalPoints, 1);
    });

    test('Complications calculates uneventful bonuses and event penalties', () {
      final detail = PointsService.getCategoryDetail('Complications', testCases);
      // case1: None/uneventful (+2) -> 1 trigger, 2 pts
      // case2: Laryngospasm (-1) -> 1 trigger, -1 pt
      expect(detail.totalTriggers, 2);
      expect(detail.totalPoints, 1); // 2 - 1 = 1 pt

      final safeItem = detail.items.firstWhere((i) => i.title.contains('Uneventful'));
      expect(safeItem.count, 1);
      expect(safeItem.totalPoints, 2);

      final larynItem = detail.items.firstWhere((i) => i.title == 'Laryngospasm');
      expect(larynItem.count, 1);
      expect(larynItem.totalPoints, -1);
    });
  });

  group('PointsBreakdownScreen to CategoryPointsDetailScreen Navigation Widget Test', () {
    testWidgets('Tapping category navigates to CategoryPointsDetailScreen with trigger counts', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final caseRecord = CaseRecord(
        id: 'widget-case-1',
        date: DateTime(2026, 6, 1),
        caseNumber: 'HN-999',
        specialty: 'Orthopaedics',
        diagnosis: 'Knee Osteoarthritis',
        procedure: 'Total Knee Replacement',
        priority: 'Elective',
        asaGrade: 'ASA II',
        technique: 'Regional',
        role: 'Consultant',
        catheterPlaced: true,
        regionalBlocks: [
          {'name': 'Spinal Anaesthesia', 'role': 'Performed'},
          {'name': 'Adductor Canal Block', 'role': 'Performed'},
        ],
      );

      await CaseStorage.saveCase(caseRecord);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PointsBreakdownScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Points breakdown screen is rendered
      expect(find.text('Points breakdown'), findsOneWidget);
      expect(find.text('BY CATEGORY'), findsOneWidget);

      // Tap on 'Regional blocks' category
      final regionalFinder = find.text('Regional blocks');
      expect(regionalFinder, findsOneWidget);
      await tester.tap(regionalFinder);
      await tester.pumpAndSettle();

      // Verify CategoryPointsDetailScreen is displayed
      expect(find.byType(CategoryPointsDetailScreen), findsOneWidget);
      expect(find.text('CATEGORY BREAKDOWN'), findsOneWidget);
      expect(find.text('CONTRIBUTING CASES (1)'), findsOneWidget);

      // Verify triggers are displayed
      expect(find.text('2 triggers'), findsOneWidget);
      expect(find.text('Triggered 1 time'), findsNWidgets(2)); // Spinal and Adductor canal
      expect(find.text('Spinal Anaesthesia'), findsOneWidget);
      expect(find.text('Adductor Canal Block'), findsOneWidget);

      // Verify contributing case is listed
      expect(find.text('Total Knee Replacement'), findsOneWidget);
    });
  });
}
