import 'dart:convert';
import '../models/case_record.dart';
import 'profile_storage.dart';

/// Anonymized QR case sharing (encode + decode/import).
class CaseShareService {
  static const payloadVersion = 1;

  /// Clinical fields only — no photo path, no local id.
  static Map<String, dynamic> buildPayload(
      CaseRecord c, {
        bool stripHospitalNumbers = true,
      }) {
    return {
      'v': payloadVersion,
      'type': 'etherlog_case',
      'sharedAt': DateTime.now().toIso8601String(),
      'case': {
        'date': c.date.toIso8601String(),
        'caseNumber': stripHospitalNumbers ? '' : c.caseNumber,
        'anaesthesiaStartTime': c.anaesthesiaStartTime,
        'anaesthesiaEndTime': c.anaesthesiaEndTime,
        'anaesthesiaDuration': c.anaesthesiaDuration,
        'surgeryStartTime': c.surgeryStartTime,
        'surgeryEndTime': c.surgeryEndTime,
        'surgeryDuration': c.surgeryDuration,
        'specialty': c.specialty,
        'specialtyOther': c.specialtyOther,
        'diagnosis': c.diagnosis,
        'procedure': c.procedure,
        'priority': c.priority,
        'asaGrade': c.asaGrade,
        'technique': c.technique,
        'role': c.role,
        'difficultAirway': c.difficultAirway,
        'difficultAirwayAttempts': c.difficultAirwayAttempts,
        'notes': c.notes,
        'patientAge': c.patientAge,
        'ageUnit': c.ageUnit,
        'patientGender': c.patientGender,
        'patientWeight': c.patientWeight,
        'patientHeight': c.patientHeight,
        'bmi': c.bmi,
        'hospital': null,
        'supervisor': null,
        'airwayManagement': c.airwayManagement,
        'cormackLehane': c.cormackLehane,
        'typeOfIntubation': c.typeOfIntubation,
        'methodOfIntubation': c.methodOfIntubation,
        'methodOfIntubationRole': c.methodOfIntubationRole,
        'ettType': c.ettType,
        'ettSize': c.ettSize,
        'lmaType': c.lmaType,
        'lmaSize': c.lmaSize,
        'lmaRole': c.lmaRole,
        'invasiveMonitoring': c.invasiveMonitoring,
        'complications': c.complications,
        'outcome': c.outcome,
        'regionalBlocks': c.regionalBlocks,
        'catheterPlaced': c.catheterPlaced,
        'starred': false,
      },
    };
  }

  static String encodePayload(
      CaseRecord c, {
        bool stripHospitalNumbers = true,
      }) {
    return jsonEncode(
      buildPayload(c, stripHospitalNumbers: stripHospitalNumbers),
    );
  }

  static bool isPayloadTooLarge(String encoded, {int maxChars = 1800}) {
    return encoded.length > maxChars;
  }

  /// Parse QR / pasted string. Returns null if not a valid Etherlog case payload.
  static Map<String, dynamic>? decodePayload(String raw) {
    try {
      final text = raw.trim();
      if (text.isEmpty) return null;
      final dynamic decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      if (map['type'] != 'etherlog_case') return null;
      if (map['case'] is! Map) return null;
      return map;
    } catch (_) {
      return null;
    }
  }

  /// Build a new local [CaseRecord] from a decoded payload.
  /// Role is forced to Consultant. Hospital comes from the receiver's profile.
  static Future<CaseRecord> toCaseRecord(Map<String, dynamic> payload) async {
    final caseMap = Map<String, dynamic>.from(payload['case'] as Map);
    final profile = await ProfileStorage.getProfile();

    caseMap.remove('id');
    caseMap['role'] = 'Consultant';
    caseMap['supervisor'] = null;
    caseMap['caseSheetImagePath'] = null;
    caseMap['starred'] = false;
    if ((caseMap['hospital'] == null ||
        caseMap['hospital'].toString().trim().isEmpty) &&
        profile.hospital.trim().isNotEmpty) {
      caseMap['hospital'] = profile.hospital;
    }

    return CaseRecord.fromJson(caseMap);
  }
}