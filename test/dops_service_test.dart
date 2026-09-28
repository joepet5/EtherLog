import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:etherlog/models/dops_assessment.dart';
import 'package:etherlog/services/dops_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'flutter.doctor_name': 'Dr. Trainee',
      'flutter.doctor_designation': 'ST3',
    });
  });

  group('DopsService', () {
    test('generateRequestPayload creates valid dops_req JSON', () async {
      final payloadStr = await DopsService.generateRequestPayload('case123', 'Intubation');
      final decoded = jsonDecode(payloadStr);
      
      expect(decoded['v'], 1);
      expect(decoded['type'], 'dops_req');
      expect(decoded['caseId'], 'case123');
      expect(decoded['traineeName'], 'Dr. Trainee');
      expect(decoded['traineeGrade'], 'ST3');
      expect(decoded['procedure'], 'Intubation');
    });

    test('generateReturnPayload creates signed dops_res JSON', () {
      final assessment = DopsAssessment(
        id: 'dops123',
        caseId: 'case123',
        traineeName: 'Dr. Trainee',
        assessorName: 'Dr. Boss',
        procedure: 'Intubation',
        scores: {'Technical': 5},
        overallCompetence: 'Competent',
      );

      final payloadStr = DopsService.generateReturnPayload(assessment);
      final decoded = jsonDecode(payloadStr);

      expect(decoded['v'], 1);
      expect(decoded['type'], 'dops_res');
      
      final payloadAssessment = decoded['assessment'] as Map<String, dynamic>;
      expect(payloadAssessment['id'], 'dops123');
      expect(payloadAssessment['signature'], isNotEmpty);
    });

    test('verifySignature correctly validates a signed payload', () {
      final assessment = DopsAssessment(
        id: 'dops123',
        caseId: 'case123',
        traineeName: 'Dr. Trainee',
        assessorName: 'Dr. Boss',
        procedure: 'Intubation',
        scores: {'Technical': 5},
        overallCompetence: 'Competent',
      );

      final payloadStr = DopsService.generateReturnPayload(assessment);
      final decoded = DopsService.decodePayload(payloadStr)!;
      final payloadAssessment = decoded['assessment'] as Map<String, dynamic>;

      final isValid = DopsService.verifySignature(payloadAssessment);
      expect(isValid, true);
    });

    test('verifySignature rejects tampered payload', () {
      final assessment = DopsAssessment(
        id: 'dops123',
        caseId: 'case123',
        traineeName: 'Dr. Trainee',
        assessorName: 'Dr. Boss',
        procedure: 'Intubation',
        scores: {'Technical': 2}, // Bad score
        overallCompetence: 'Needs help',
      );

      final payloadStr = DopsService.generateReturnPayload(assessment);
      final decoded = DopsService.decodePayload(payloadStr)!;
      final payloadAssessment = decoded['assessment'] as Map<String, dynamic>;

      // Trainee attempts to tamper with the score before importing
      payloadAssessment['scores'] = {'Technical': 5};
      payloadAssessment['overallCompetence'] = 'Excellent';

      final isValid = DopsService.verifySignature(payloadAssessment);
      expect(isValid, false);
    });
  });
}
