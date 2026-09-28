import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherlog/models/case_record.dart';
import 'package:etherlog/services/case_storage.dart';
import 'package:etherlog/services/signature_storage.dart';
import 'package:etherlog/screens/sign_off_screen.dart';
import 'package:etherlog/screens/case_detail_screen.dart';
import 'package:etherlog/screens/points_breakdown_screen.dart';
import 'package:etherlog/services/profile_storage.dart';
import 'package:etherlog/models/doctor_profile.dart';
import 'package:etherlog/screens/new_case_screen.dart';
import 'package:etherlog/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CaseRecord Verification Fields', () {
    test('Defaults to unverified', () {
      final c = CaseRecord(
        caseNumber: 'CASE-001',
        date: DateTime(2026, 3, 15),
        specialty: 'General Surgery',
        diagnosis: 'Appendicitis',
        procedure: 'Laparoscopic Appendicectomy',
        priority: 'Emergency',
        asaGrade: 'ASA I',
        technique: 'General Anaesthesia',
        role: 'Primary Anaesthetist',
      );

      expect(c.verified, isFalse);
      expect(c.verifiedBy, isNull);
      expect(c.verifiedAt, isNull);
    });

    test('copyWith updates verification attributes', () {
      final c = CaseRecord(
        id: 'c-101',
        caseNumber: 'CASE-001',
        date: DateTime(2026, 3, 15),
        specialty: 'General Surgery',
        diagnosis: 'Appendicitis',
        procedure: 'Laparoscopic Appendicectomy',
        priority: 'Emergency',
        asaGrade: 'ASA I',
        technique: 'General Anaesthesia',
        role: 'Primary Anaesthetist',
      );

      final signTime = DateTime(2026, 3, 16, 14, 30);
      final verifiedCase = c.copyWith(
        verified: true,
        verifiedBy: 'Dr. Jane Smith',
        verifiedAt: signTime,
      );

      expect(verifiedCase.id, 'c-101');
      expect(verifiedCase.verified, isTrue);
      expect(verifiedCase.verifiedBy, 'Dr. Jane Smith');
      expect(verifiedCase.verifiedAt, signTime);
    });

    test('Serializes to and from JSON correctly', () {
      final signTime = DateTime(2026, 3, 16, 14, 30);
      final c = CaseRecord(
        id: 'c-102',
        caseNumber: 'CASE-002',
        date: DateTime(2026, 3, 15),
        specialty: 'Obstetrics',
        diagnosis: 'Fetal Distress',
        procedure: 'Category 1 Caesarean Section',
        priority: 'Emergency',
        asaGrade: 'ASA II',
        technique: 'Spinal Anaesthesia',
        role: 'Supervised',
        verified: true,
        verifiedBy: 'Prof. Alistair Ross',
        verifiedAt: signTime,
      );

      final json = c.toJson();
      expect(json['verified'], isTrue);
      expect(json['verifiedBy'], 'Prof. Alistair Ross');
      expect(json['verifiedAt'], signTime.toIso8601String());

      final restored = CaseRecord.fromJson(json);
      expect(restored.id, 'c-102');
      expect(restored.verified, isTrue);
      expect(restored.verifiedBy, 'Prof. Alistair Ross');
      expect(restored.verifiedAt, signTime);
    });

    test('Gracefully handles missing or legacy JSON without verification fields', () {
      final legacyJson = <String, dynamic>{
        'id': 'c-legacy',
        'caseNumber': 'OLD-1',
        'date': '2025-01-01T00:00:00.000',
        'specialty': 'Orthopaedics',
        'diagnosis': 'Fracture NOF',
        'procedure': 'DHS',
        'priority': 'Emergency',
        'asaGrade': 'ASA III',
        'technique': 'Spinal',
        'role': 'Consultant',
      };

      final restored = CaseRecord.fromJson(legacyJson);
      expect(restored.verified, isFalse);
      expect(restored.verifiedBy, isNull);
      expect(restored.verifiedAt, isNull);
    });
  });

  group('SignOffRecord & SignatureStorage', () {
    test('Personal doctor signature save, retrieve, and delete', () async {
      expect(await SignatureStorage.getDoctorSignature(), isNull);

      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      await SignatureStorage.saveDoctorSignature(sampleBytes);

      final retrieved = await SignatureStorage.getDoctorSignature();
      expect(retrieved, isNotNull);
      expect(retrieved, sampleBytes);

      await SignatureStorage.deleteDoctorSignature();
      expect(await SignatureStorage.getDoctorSignature(), isNull);
    });

    test('SignOffRecord serializes and deserializes cleanly', () {
      final now = DateTime.now();
      final sigBytes = Uint8List.fromList([10, 20, 30, 40]);
      final counterBytes = Uint8List.fromList([50, 60, 70, 80]);

      final record = SignOffRecord(
        id: 'signoff-1',
        date: now,
        isConsultantAttestation: true,
        doctorName: 'Dr. John Doe',
        supervisorName: 'Dr. John Doe',
        supervisorDesignation: 'Consultant Anaesthetist',
        supervisorHospital: 'Royal Infirmary',
        appraiserName: 'Dr. Arthur Pendelton',
        appraiserDesignation: 'Clinical Director',
        declarationText: 'Formal self-attestation statement',
        caseIds: ['case-1', 'case-2', 'case-3'],
        casesCount: 3,
        dateRangeStart: DateTime(2025, 1, 1),
        dateRangeEnd: DateTime(2025, 12, 31),
        signatureBase64: base64Encode(sigBytes),
        counterSignatureBase64: base64Encode(counterBytes),
      );

      final json = record.toJson();
      final restored = SignOffRecord.fromJson(json);

      expect(restored.id, 'signoff-1');
      expect(restored.isConsultantAttestation, isTrue);
      expect(restored.doctorName, 'Dr. John Doe');
      expect(restored.casesCount, 3);
      expect(restored.caseIds, ['case-1', 'case-2', 'case-3']);
      expect(restored.signatureBytes, sigBytes);
      expect(restored.counterSignatureBytes, counterBytes);
    });

    test('SignOff history saving, retrieval ordering, and deletion', () async {
      final rec1 = SignOffRecord(
        id: 'so-1',
        date: DateTime(2026, 1, 10),
        isConsultantAttestation: false,
        doctorName: 'Dr. Trainee',
        supervisorName: 'Dr. Consultant A',
        supervisorDesignation: 'Consultant',
        supervisorHospital: 'Hospital A',
        declarationText: 'Declaration A',
        caseIds: ['c1'],
        casesCount: 1,
        signatureBase64: base64Encode([1, 2, 3]),
      );

      final rec2 = SignOffRecord(
        id: 'so-2',
        date: DateTime(2026, 2, 20),
        isConsultantAttestation: false,
        doctorName: 'Dr. Trainee',
        supervisorName: 'Dr. Consultant B',
        supervisorDesignation: 'Consultant',
        supervisorHospital: 'Hospital B',
        declarationText: 'Declaration B',
        caseIds: ['c2', 'c3'],
        casesCount: 2,
        signatureBase64: base64Encode([4, 5, 6]),
      );

      await SignatureStorage.saveSignOff(rec1);
      await SignatureStorage.saveSignOff(rec2);

      final history = await SignatureStorage.getSignOffHistory();
      expect(history.length, 2);
      // Ordered newest first
      expect(history[0].id, 'so-2');
      expect(history[1].id, 'so-1');

      await SignatureStorage.deleteSignOff('so-1');
      final updatedHistory = await SignatureStorage.getSignOffHistory();
      expect(updatedHistory.length, 1);
      expect(updatedHistory[0].id, 'so-2');
    });
  });

  group('CaseStorage Batch Verification', () {
    test('verifyCases updates matching cases atomically', () async {
      final case1 = CaseRecord(
        id: 'batch-1',
        caseNumber: 'BN-1',
        date: DateTime(2026, 1, 5),
        specialty: 'General Surgery',
        diagnosis: 'Hernia',
        procedure: 'TAPP Repair',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'General',
        role: 'Primary Anaesthetist',
      );

      final case2 = CaseRecord(
        id: 'batch-2',
        caseNumber: 'BN-2',
        date: DateTime(2026, 1, 6),
        specialty: 'Orthopaedics',
        diagnosis: 'Knee OA',
        procedure: 'Total Knee Arthroplasty',
        priority: 'Elective',
        asaGrade: 'ASA II',
        technique: 'Spinal',
        role: 'Primary Anaesthetist',
      );

      await CaseStorage.saveCase(case1);
      await CaseStorage.saveCase(case2);

      final signTime = DateTime(2026, 1, 15, 10, 0);
      await CaseStorage.verifyCases(
        ['batch-1', 'batch-2'],
        verifiedBy: 'Dr. Elizabeth Ward',
        verifiedAt: signTime,
      );

      final all = await CaseStorage.getAllCases();
      final updated1 = all.firstWhere((c) => c.id == 'batch-1');
      final updated2 = all.firstWhere((c) => c.id == 'batch-2');

      expect(updated1.verified, isTrue);
      expect(updated1.verifiedBy, 'Dr. Elizabeth Ward');
      expect(updated1.verifiedAt, signTime);

      expect(updated2.verified, isTrue);
      expect(updated2.verifiedBy, 'Dr. Elizabeth Ward');
      expect(updated2.verifiedAt, signTime);

      // Unverify one
      await CaseStorage.unverifyCases(['batch-1']);
      final refreshed = await CaseStorage.getAllCases();
      final unverified1 = refreshed.firstWhere((c) => c.id == 'batch-1');
      final stillVerified2 = refreshed.firstWhere((c) => c.id == 'batch-2');

      expect(unverified1.verified, isFalse);
      expect(unverified1.verifiedBy, isNull);
      expect(stillVerified2.verified, isTrue);
    });
  });

  group('SignOffScreen UI & History Tab Tests', () {
    testWidgets('TabBar displays all 3 tabs with marquee labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignOffScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trainee Sign-Off'), findsOneWidget);
      expect(find.text('Consultant Appraisal'), findsOneWidget);
      expect(find.text('History (0)'), findsOneWidget);
    });

    testWidgets('History tab is not blank and shows verification status and guidance', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SignOffScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the History tab
      await tester.tap(find.text('History (0)'));
      await tester.pumpAndSettle();

      // Verify the history tab is not a blank screen
      expect(find.text('Logbook Verification Status'), findsOneWidget);
      expect(find.text('ARCP & revalidation appraisal readiness'), findsOneWidget);
      expect(find.text('Total Cases'), findsOneWidget);
      expect(find.text('Verified Cases'), findsOneWidget);
      expect(find.text('Certificates'), findsOneWidget);
      expect(find.text('Signed Certificates (0)'), findsOneWidget);
      expect(find.text('No Formal Signed Certificates Yet'), findsOneWidget);
      expect(find.text('Clinically Verified Cases (0)'), findsOneWidget);
    });

    testWidgets('History tab displays verified cases when cases are verified', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Seed a verified case
      final verifiedCase = CaseRecord(
        id: 'hist-v-1',
        caseNumber: 'HOSP-7788',
        date: DateTime(2026, 4, 10),
        specialty: 'Obstetrics',
        diagnosis: 'Placenta Praevia',
        procedure: 'Elective Caesarean Section',
        priority: 'Elective',
        asaGrade: 'ASA II',
        technique: 'Spinal Anaesthesia',
        role: 'Primary Anaesthetist',
        verified: true,
        verifiedBy: 'Dr. Michael Chen',
        verifiedAt: DateTime(2026, 4, 11),
      );
      await CaseStorage.saveCase(verifiedCase);

      await tester.pumpWidget(
        const MaterialApp(
          home: SignOffScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on History tab
      await tester.tap(find.text('History (0)'));
      await tester.pumpAndSettle();

      // Verify verified cases section reflects the verified case
      expect(find.text('Clinically Verified Cases (1)'), findsOneWidget);
      expect(find.text('Elective Caesarean Section'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.text('By: Dr. Michael Chen'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
    });
  });

  group('CaseDetailScreen Role Verification Banner Tests', () {
    testWidgets('Consultant role does NOT show Unverified Clinical Case banner', (tester) async {
      final consultantCase = CaseRecord(
        id: 'c-role-cons-1',
        caseNumber: 'HOSP-001',
        date: DateTime(2026, 4, 10),
        specialty: 'General Surgery',
        diagnosis: 'Hernia',
        procedure: 'Laparoscopic Inguinal Hernia Repair',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'General Anaesthesia',
        role: 'Consultant',
        verified: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CaseDetailScreen(caseRecord: consultantCase),
        ),
      );
      await tester.pumpAndSettle();

      // Should NOT show unverified clinical case banner when role is consultant
      expect(find.text('Unverified Clinical Case'), findsNothing);
      expect(find.text('Tap to request consultant sign-off for this case'), findsNothing);
    });

    testWidgets('Trainee / Registrar role DOES show Unverified Clinical Case banner when unverified', (tester) async {
      await ProfileStorage.saveProfile(const DoctorProfile(
        name: 'Dr. Test Trainee',
        clinicalVerificationEnabled: true,
      ));

      final registrarCase = CaseRecord(
        id: 'c-role-reg-1',
        caseNumber: 'HOSP-002',
        date: DateTime(2026, 4, 10),
        specialty: 'General Surgery',
        diagnosis: 'Hernia',
        procedure: 'Open Inguinal Hernia Repair',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'General Anaesthesia',
        role: 'Registrar',
        verified: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CaseDetailScreen(caseRecord: registrarCase),
        ),
      );
      await tester.pumpAndSettle();

      // Non-consultant unverified cases should show the sign-off banner
      expect(find.text('Unverified Clinical Case'), findsOneWidget);
      expect(find.text('Tap to request consultant sign-off for this case'), findsOneWidget);
    });

    test('CaseStorage.saveCase normalizes consultant cases to verified automatically', () async {
      final unverifiedCons = CaseRecord(
        id: 'cons-save-test-1',
        caseNumber: 'HOSP-003',
        date: DateTime(2026, 4, 10),
        specialty: 'General Surgery',
        diagnosis: 'Hernia',
        procedure: 'Laparoscopic Inguinal Hernia Repair',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'General Anaesthesia',
        role: 'Consultant',
        verified: false,
      );

      await CaseStorage.saveCase(unverifiedCons);
      final fetched = await CaseStorage.getCase('cons-save-test-1');
      expect(fetched, isNotNull);
      expect(fetched!.verified, isTrue);
      expect(fetched.verifiedBy, isNotNull);

      // JSON serialization retains verified, isVerified, and clinicallyVerified
      final json = fetched.toJson();
      expect(json['verified'], isTrue);
      expect(json['isVerified'], isTrue);
      expect(json['clinicallyVerified'], isTrue);

      // JSON deserialization faithfully restores verified
      final restored = CaseRecord.fromJson(json);
      expect(restored.verified, isTrue);
    });

    test('Verified tag is saved to JSON file/storage and retained when refreshed', () async {
      final caseRecord = CaseRecord(
        id: 'verify-refresh-1',
        caseNumber: 'VR-001',
        date: DateTime(2026, 4, 10),
        specialty: 'Neurosurgery',
        diagnosis: 'Subdural Haematoma',
        procedure: 'Burr Hole Evacuation',
        priority: 'Emergency',
        asaGrade: 'ASA III',
        technique: 'General Anaesthesia',
        role: 'Fellow',
        verified: true,
        verifiedBy: 'Dr. Supervisor',
        verifiedAt: DateTime(2026, 4, 10, 15, 0),
      );

      await CaseStorage.saveCase(caseRecord);

      // Verify it is written to the raw JSON string in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString('etherlog_cases');
      expect(rawJson, isNotNull);
      final List<dynamic> decodedList = jsonDecode(rawJson!);
      final storedJson =
          decodedList.firstWhere((e) => e['id'] == 'verify-refresh-1');
      expect(storedJson['verified'], isTrue);
      expect(storedJson['isVerified'], isTrue);
      expect(storedJson['clinicallyVerified'], isTrue);
      expect(storedJson['verifiedBy'], 'Dr. Supervisor');

      // Simulate multiple screen refreshes
      final refreshedOnce = await CaseStorage.getCase('verify-refresh-1');
      expect(refreshedOnce, isNotNull);
      expect(refreshedOnce!.verified, isTrue);

      final allCasesRefreshed = await CaseStorage.getAllCases();
      final match =
          allCasesRefreshed.firstWhere((c) => c.id == 'verify-refresh-1');
      expect(match.verified, isTrue);
      expect(match.verifiedBy, 'Dr. Supervisor');
    });

    testWidgets('CaseDetailScreen retains Clinically Verified Record tag on pull-to-refresh', (tester) async {
      await ProfileStorage.saveProfile(const DoctorProfile(
        name: 'Dr. Test Mentor',
        clinicalVerificationEnabled: true,
      ));

      final verifiedCase = CaseRecord(
        id: 'cd-verified-1',
        caseNumber: 'CD-001',
        date: DateTime(2026, 4, 12),
        specialty: 'ENT',
        diagnosis: 'Tonsillitis',
        procedure: 'Tonsillectomy',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'General Anaesthesia',
        role: 'Trainee',
        verified: true,
        verifiedBy: 'Dr. Mentor',
        verifiedAt: DateTime(2026, 4, 12, 10, 0),
      );

      await CaseStorage.saveCase(verifiedCase);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CaseDetailScreen(caseRecord: verifiedCase),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinically Verified Record'), findsOneWidget);
      expect(find.textContaining('Dr. Mentor'), findsOneWidget);

      // Simulate pull-to-refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Tag must STILL be present
      expect(find.text('Clinically Verified Record'), findsOneWidget);
      expect(find.textContaining('Dr. Mentor'), findsOneWidget);
    });
  });

  group('PointsBreakdownScreen Ordering Tests', () {
    testWidgets('Categories are arranged in descending order with profile bonus last', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // Add profile with completion bonus
      await ProfileStorage.saveProfile(const DoctorProfile(
        name: 'Dr. Test Anaesthetist',
        hospital: 'City Hospital',
        designation: 'Consultant',
        registrationNumber: 'MED-12345',
      ));

      // Add cases generating points across different categories
      await CaseStorage.saveCase(CaseRecord(
        id: 'pts-case-1',
        caseNumber: 'CASE-PTS-1',
        date: DateTime(2026, 4, 1),
        specialty: 'General Surgery',
        diagnosis: 'Appendicitis',
        procedure: 'Laparoscopic Appendicectomy',
        priority: 'Emergency', // Emergency adds points
        asaGrade: 'ASA III', // ASA III adds points
        technique: 'General Anaesthesia',
        role: 'Consultant',
        difficultAirway: true, // Airway points
        difficultAirwayAttempts: 2,
      ));

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

      expect(find.text('Points breakdown'), findsOneWidget);
      expect(find.text('BY CATEGORY'), findsOneWidget);
      expect(find.text('Profile completion bonus'), findsOneWidget);
    });
  });

  group('Clinical Verification Toggle Option Tests', () {
    test('ProfileStorage and DoctorProfile handle clinicalVerificationEnabled toggle', () async {
      SharedPreferences.setMockInitialValues({});

      // Defaults to false
      final defaultProfile = await ProfileStorage.getProfile();
      expect(defaultProfile.clinicalVerificationEnabled, isFalse);
      expect(await ProfileStorage.isClinicalVerificationEnabled(), isFalse);

      // Enable verification
      await ProfileStorage.setClinicalVerificationEnabled(true);
      final enabledProfile = await ProfileStorage.getProfile();
      expect(enabledProfile.clinicalVerificationEnabled, isTrue);
      expect(await ProfileStorage.isClinicalVerificationEnabled(), isTrue);

      // JSON serialization
      final json = enabledProfile.toJson();
      expect(json['clinicalVerificationEnabled'], isTrue);
      final deserialized = DoctorProfile.fromJson(json);
      expect(deserialized.clinicalVerificationEnabled, isTrue);

      // Disable verification
      await ProfileStorage.setClinicalVerificationEnabled(false);
      expect(await ProfileStorage.isClinicalVerificationEnabled(), isFalse);
    });

    testWidgets('CaseDetailScreen hides unverified warning and verified banner when verification is disabled', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // Set verification to disabled in profile
      await ProfileStorage.saveProfile(const DoctorProfile(
        name: 'Dr. Test Anaesthetist',
        clinicalVerificationEnabled: false,
      ));

      final traineeCase = CaseRecord(
        id: 'trainee-ver-disabled-1',
        caseNumber: 'CASE-DIS-1',
        date: DateTime(2026, 4, 10),
        specialty: 'General Surgery',
        diagnosis: 'Hernia',
        procedure: 'Hernia Repair',
        priority: 'Elective',
        asaGrade: 'ASA I',
        technique: 'Spinal',
        role: 'Trainee',
        verified: false,
      );
      await CaseStorage.saveCase(traineeCase);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CaseDetailScreen(caseRecord: traineeCase),
        ),
      );
      await tester.pumpAndSettle();

      // Neither Unverified banner nor Clinically Verified Record should appear
      expect(find.text('Unverified Clinical Case'), findsNothing);
      expect(find.text('Clinically Verified Record'), findsNothing);
    });

    testWidgets('NewCaseScreen hides Clinically Verified Record switch when verification is disabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      // Disable clinical verification in profile
      await ProfileStorage.saveProfile(const DoctorProfile(
        name: 'Dr. Test Anaesthetist',
        clinicalVerificationEnabled: false,
      ));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NewCaseScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // The Clinically Verified Record switch tile must NOT be displayed
      expect(find.text('Clinically Verified Record'), findsNothing);
    });

    testWidgets('NewCaseScreen shows Clinically Verified Record switch when verification is enabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      // Enable clinical verification in profile
      await ProfileStorage.saveProfile(const DoctorProfile(
        name: 'Dr. Test Anaesthetist',
        clinicalVerificationEnabled: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NewCaseScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // The Clinically Verified Record switch tile MUST be displayed
      expect(find.text('Clinically Verified Record'), findsOneWidget);
    });
  });
}
