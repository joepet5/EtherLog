import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/dops_assessment.dart';
import 'profile_storage.dart';

class DopsService {
  static const int payloadVersion = 1;
  static const String reqType = 'dops_req';
  static const String resType = 'dops_res';

  // We use a simple constant salt for signing the assessment to prevent casual tampering.
  // In a high-security environment, this would be an asymmetric keypair.
  static const String _localSalt = 'etherlog_dops_2024';

  /// Generates the QR payload for a Trainee requesting a DOPS
  static Future<String> generateRequestPayload(String caseId, String procedure) async {
    final profile = await ProfileStorage.getProfile();
    final Map<String, dynamic> req = {
      'v': payloadVersion,
      'type': reqType,
      'caseId': caseId,
      'traineeName': profile.name,
      'traineeGrade': profile.designation,
      'procedure': procedure,
    };
    return jsonEncode(req);
  }

  /// Generates the QR payload for a Consultant returning a completed DOPS
  static String generateReturnPayload(DopsAssessment assessment) {
    // Generate signature first
    final unsignedJson = _buildUnsignedJson(assessment);
    final signature = _generateSignature(unsignedJson);
    
    // Add signature
    final signedAssessmentMap = unsignedJson;
    signedAssessmentMap['signature'] = signature;

    final Map<String, dynamic> res = {
      'v': payloadVersion,
      'type': resType,
      'assessment': signedAssessmentMap,
    };
    return jsonEncode(res);
  }

  /// Decode a raw QR payload. Returns a map with 'type' (dops_req or dops_res) and the data.
  static Map<String, dynamic>? decodePayload(String raw) {
    try {
      final text = raw.trim();
      if (text.isEmpty) return null;
      final dynamic decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      
      final map = Map<String, dynamic>.from(decoded);
      final type = map['type']?.toString();
      
      if (type != reqType && type != resType) return null;
      
      return map;
    } catch (_) {
      return null;
    }
  }

  /// Verifies a signed DOPS assessment payload from the Consultant
  static bool verifySignature(Map<String, dynamic> assessmentJson) {
    final providedSignature = assessmentJson['signature']?.toString();
    if (providedSignature == null || providedSignature.isEmpty) return false;

    // Create a copy without the signature to recalculate the hash
    final unsignedCopy = Map<String, dynamic>.from(assessmentJson);
    unsignedCopy.remove('signature');
    
    // Convert to deterministic JSON string (sorted keys would be safer, but this is simple)
    final expectedSignature = _generateSignature(unsignedCopy);
    
    return providedSignature == expectedSignature;
  }

  static String _generateSignature(Map<String, dynamic> unsignedJson) {
    // A robust way to serialize for hashing is to sort keys. 
    final sortedKeys = unsignedJson.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      buffer.write('$key:${unsignedJson[key]}|');
    }
    
    final hmac = Hmac(sha256, utf8.encode(_localSalt));
    final digest = hmac.convert(utf8.encode(buffer.toString()));
    return digest.toString();
  }

  static Map<String, dynamic> _buildUnsignedJson(DopsAssessment assessment) {
    final json = assessment.toJson();
    json.remove('signature');
    return json;
  }
}
