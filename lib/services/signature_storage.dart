import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class SignOffRecord {
  final String id;
  final DateTime date;
  final bool isConsultantAttestation;
  final String doctorName;
  final String supervisorName;
  final String supervisorDesignation;
  final String supervisorHospital;
  final String? supervisorRegistration;
  final String? appraiserName;
  final String? appraiserDesignation;
  final String declarationText;
  final List<String> caseIds;
  final int casesCount;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final String signatureBase64;
  final String? counterSignatureBase64;

  const SignOffRecord({
    required this.id,
    required this.date,
    required this.isConsultantAttestation,
    required this.doctorName,
    required this.supervisorName,
    required this.supervisorDesignation,
    required this.supervisorHospital,
    this.supervisorRegistration,
    this.appraiserName,
    this.appraiserDesignation,
    required this.declarationText,
    required this.caseIds,
    required this.casesCount,
    this.dateRangeStart,
    this.dateRangeEnd,
    required this.signatureBase64,
    this.counterSignatureBase64,
  });

  Uint8List get signatureBytes => base64Decode(signatureBase64);
  Uint8List? get counterSignatureBytes => counterSignatureBase64 != null
      ? base64Decode(counterSignatureBase64!)
      : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'isConsultantAttestation': isConsultantAttestation,
        'doctorName': doctorName,
        'supervisorName': supervisorName,
        'supervisorDesignation': supervisorDesignation,
        'supervisorHospital': supervisorHospital,
        if (supervisorRegistration != null)
          'supervisorRegistration': supervisorRegistration,
        if (appraiserName != null) 'appraiserName': appraiserName,
        if (appraiserDesignation != null)
          'appraiserDesignation': appraiserDesignation,
        'declarationText': declarationText,
        'caseIds': caseIds,
        'casesCount': casesCount,
        if (dateRangeStart != null)
          'dateRangeStart': dateRangeStart!.toIso8601String(),
        if (dateRangeEnd != null)
          'dateRangeEnd': dateRangeEnd!.toIso8601String(),
        'signatureBase64': signatureBase64,
        if (counterSignatureBase64 != null)
          'counterSignatureBase64': counterSignatureBase64,
      };

  factory SignOffRecord.fromJson(Map<String, dynamic> json) {
    return SignOffRecord(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      isConsultantAttestation:
          json['isConsultantAttestation'] as bool? ?? false,
      doctorName: json['doctorName'] as String? ?? '',
      supervisorName: json['supervisorName'] as String? ?? '',
      supervisorDesignation: json['supervisorDesignation'] as String? ?? '',
      supervisorHospital: json['supervisorHospital'] as String? ?? '',
      supervisorRegistration: json['supervisorRegistration'] as String?,
      appraiserName: json['appraiserName'] as String?,
      appraiserDesignation: json['appraiserDesignation'] as String?,
      declarationText: json['declarationText'] as String? ?? '',
      caseIds: (json['caseIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      casesCount: json['casesCount'] as int? ?? 0,
      dateRangeStart: json['dateRangeStart'] != null
          ? DateTime.tryParse(json['dateRangeStart'] as String)
          : null,
      dateRangeEnd: json['dateRangeEnd'] != null
          ? DateTime.tryParse(json['dateRangeEnd'] as String)
          : null,
      signatureBase64: json['signatureBase64'] as String? ?? '',
      counterSignatureBase64: json['counterSignatureBase64'] as String?,
    );
  }
}

class SignatureStorage {
  static const String _doctorSignatureKey = 'etherlog_doctor_signature_base64';
  static const String _signOffHistoryKey = 'etherlog_sign_off_history';

  /// Save personal doctor signature as base64 PNG.
  static Future<void> saveDoctorSignature(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doctorSignatureKey, base64Encode(bytes));
  }

  /// Retrieve personal doctor signature as bytes.
  static Future<Uint8List?> getDoctorSignature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final base64Str = prefs.getString(_doctorSignatureKey);
      if (base64Str == null || base64Str.isEmpty) return null;
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  /// Delete personal doctor signature.
  static Future<void> deleteDoctorSignature() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doctorSignatureKey);
  }

  /// Save a formal sign-off record (trainee supervisor or consultant self-attestation).
  static Future<void> saveSignOff(SignOffRecord record) async {
    final history = await getSignOffHistory();
    history.removeWhere((r) => r.id == record.id);
    history.insert(0, record);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setString(_signOffHistoryKey, jsonEncode(jsonList));
  }

  /// Retrieve all sign-off records ordered from newest to oldest.
  static Future<List<SignOffRecord>> getSignOffHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_signOffHistoryKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw);
      final records = <SignOffRecord>[];
      for (final item in list) {
        if (item is Map) {
          try {
            records.add(SignOffRecord.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (_) {
      return [];
    }
  }

  /// Delete a specific sign-off record by ID.
  static Future<void> deleteSignOff(String id) async {
    final history = await getSignOffHistory();
    history.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setString(_signOffHistoryKey, jsonEncode(jsonList));
  }
}
