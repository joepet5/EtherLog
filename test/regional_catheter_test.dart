import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherlog/l10n/app_localizations.dart';
import 'package:etherlog/models/case_record.dart';
import 'package:etherlog/screens/case_detail_screen.dart';
import 'package:etherlog/screens/new_case_screen.dart';
import 'package:etherlog/services/case_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  group('Regional Catheter Multi-Block Selection & Validation Tests', () {
    testWidgets(
        'When multiple blocks are selected and catheter placed is checked, shows multi-block chip selector',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final multiBlockCase = CaseRecord(
        id: 'multi-block-1',
        caseNumber: 'MB-001',
        date: DateTime(2026, 3, 1),
        specialty: 'Orthopaedics',
        diagnosis: 'Knee Arthroplasty',
        procedure: 'TKA',
        priority: 'Elective',
        asaGrade: 'ASA II',
        technique: 'Spinal',
        role: 'Registrar',
        regionalBlocks: [
          {
            'name': 'Epidural',
            'role': 'Performed',
            'usgGuided': false,
            'nerveStimulator': false,
          },
          {
            'name': 'Femoral nerve block',
            'role': 'Performed',
            'usgGuided': true,
            'nerveStimulator': false,
          },
        ],
        catheterPlaced: false,
      );

      await tester.pumpWidget(buildTestableWidget(
        NewCaseScreen(existingCase: multiBlockCase),
      ));
      await tester.pumpAndSettle();

      // Before checking catheter placed, the selector is not displayed
      expect(find.text('Specify block(s) with catheter:'), findsNothing);

      // Tap the "Catheter placed" CheckboxListTile
      final catheterTile = find.byWidgetPredicate(
        (w) =>
            w is CheckboxListTile &&
            (w.title is Text) &&
            ((w.title as Text).data?.contains('Catheter placed') ?? false),
      );
      expect(catheterTile, findsOneWidget);
      await tester.tap(catheterTile);
      await tester.pumpAndSettle();

      // Now the multi-block selection widget should appear with chips for both blocks
      expect(find.text('Specify block(s) with catheter:'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Epidural'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Femoral nerve block'), findsOneWidget);

      // Tap the Epidural chip to mark catheter on Epidural
      await tester.tap(find.widgetWithText(FilterChip, 'Epidural'));
      await tester.pumpAndSettle();

      // Epidural chip should be selected
      final epiduralChip =
          tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Epidural'));
      expect(epiduralChip.selected, isTrue);

      final femoralChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Femoral nerve block'));
      expect(femoralChip.selected, isFalse);
    });

    testWidgets(
        'Validation prevents save if catheter is placed with multiple blocks and none is chosen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final multiBlockCase = CaseRecord(
        id: 'multi-block-2',
        caseNumber: 'MB-002',
        date: DateTime(2026, 3, 2),
        specialty: 'Orthopaedics',
        diagnosis: 'Knee Arthroplasty',
        procedure: 'TKA',
        priority: 'Elective',
        asaGrade: 'ASA II',
        technique: 'Spinal',
        role: 'Registrar',
        regionalBlocks: [
          {
            'name': 'Epidural',
            'role': 'Performed',
            'usgGuided': false,
            'nerveStimulator': false,
          },
          {
            'name': 'Femoral nerve block',
            'role': 'Performed',
            'usgGuided': true,
            'nerveStimulator': false,
          },
        ],
        catheterPlaced: false,
      );

      await tester.pumpWidget(buildTestableWidget(
        NewCaseScreen(existingCase: multiBlockCase),
      ));
      await tester.pumpAndSettle();

      // Turn on catheter placed
      final catheterTile = find.byWidgetPredicate(
        (w) =>
            w is CheckboxListTile &&
            (w.title is Text) &&
            ((w.title as Text).data?.contains('Catheter placed') ?? false),
      );
      await tester.tap(catheterTile);
      await tester.pumpAndSettle();

      // Without selecting any block chip, click Save Case
      final saveBtn = find.widgetWithText(ElevatedButton, 'Save case');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Validation error message should be displayed
      expect(
        find.text('Please select at least one regional block for the catheter.'),
        findsWidgets,
      );
    });

    testWidgets(
        'Single block case automatically assigns catheter and does not show multi-block widget',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final singleBlockCase = CaseRecord(
        id: 'single-block-1',
        caseNumber: 'SB-001',
        date: DateTime(2026, 3, 3),
        specialty: 'Obstetrics',
        diagnosis: 'Labour',
        procedure: 'Labour Analgesia',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'Epidural',
        role: 'Registrar',
        regionalBlocks: [
          {
            'name': 'Epidural',
            'role': 'Performed',
            'usgGuided': false,
            'nerveStimulator': false,
          },
        ],
        catheterPlaced: true,
      );

      await tester.pumpWidget(buildTestableWidget(
        NewCaseScreen(existingCase: singleBlockCase),
      ));
      await tester.pumpAndSettle();

      // Multi-block selection widget should NOT be shown because there is only 1 block
      expect(find.text('Specify block(s) with catheter:'), findsNothing);

      // Detail chip preview displays Catheter badge
      expect(find.textContaining('Catheter'), findsWidgets);
    });

    testWidgets(
        'CaseDetailScreen displays designated catheter block name',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final caseRecord = CaseRecord(
        id: 'detail-cath-1',
        caseNumber: 'DET-001',
        date: DateTime(2026, 3, 4),
        specialty: 'Orthopaedics',
        diagnosis: 'Fracture Femur',
        procedure: 'Femur ORIF',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'Spinal',
        role: 'Registrar',
        regionalBlocks: [
          {
            'name': 'Spinal (SAB)',
            'role': 'Performed',
            'usgGuided': false,
            'nerveStimulator': false,
            'catheterPlaced': false,
          },
          {
            'name': 'Femoral nerve block',
            'role': 'Performed',
            'usgGuided': true,
            'nerveStimulator': false,
            'catheterPlaced': true,
          },
        ],
        catheterPlaced: true,
      );

      await tester.pumpWidget(buildTestableWidget(
        CaseDetailScreen(caseRecord: caseRecord),
      ));
      await tester.pumpAndSettle();

      // Catheter row should display Femoral nerve block
      expect(find.text('Femoral nerve block'), findsWidgets);
      // Regional block formatted text should include Catheter badge
      expect(find.textContaining('Catheter'), findsWidgets);
    });
  });
}
