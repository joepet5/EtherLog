class DopsAssessment {
  final String id; // Unique ID for the assessment
  final String caseId;
  final String traineeName;
  final String traineeGrade;
  final String assessorName;
  final String assessorPosition;
  final String procedure;
  
  // Scores (e.g., 1 to 5, or string-based)
  // To keep it simple and flexible, we use a map for domain scores.
  final Map<String, int> scores; 
  
  // Feedback
  final String strengths;
  final String areasForImprovement;
  final String overallCompetence; // e.g., 'Requires Assistance', 'Competent', 'Excellent'
  
  final DateTime date;
  final String signature; // Hash of the assessment for anti-tampering

  DopsAssessment({
    String? id,
    required this.caseId,
    required this.traineeName,
    this.traineeGrade = '',
    required this.assessorName,
    this.assessorPosition = '',
    required this.procedure,
    required this.scores,
    this.strengths = '',
    this.areasForImprovement = '',
    required this.overallCompetence,
    DateTime? date,
    this.signature = '',
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'caseId': caseId,
    'traineeName': traineeName,
    'traineeGrade': traineeGrade,
    'assessorName': assessorName,
    'assessorPosition': assessorPosition,
    'procedure': procedure,
    'scores': scores,
    'strengths': strengths,
    'areasForImprovement': areasForImprovement,
    'overallCompetence': overallCompetence,
    'date': date.toIso8601String(),
    'signature': signature,
  };

  factory DopsAssessment.fromJson(Map<String, dynamic> json) {
    return DopsAssessment(
      id: json['id']?.toString(),
      caseId: json['caseId']?.toString() ?? '',
      traineeName: json['traineeName']?.toString() ?? '',
      traineeGrade: json['traineeGrade']?.toString() ?? '',
      assessorName: json['assessorName']?.toString() ?? '',
      assessorPosition: json['assessorPosition']?.toString() ?? '',
      procedure: json['procedure']?.toString() ?? '',
      scores: json['scores'] != null 
          ? Map<String, int>.from(json['scores'] as Map) 
          : {},
      strengths: json['strengths']?.toString() ?? '',
      areasForImprovement: json['areasForImprovement']?.toString() ?? '',
      overallCompetence: json['overallCompetence']?.toString() ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      signature: json['signature']?.toString() ?? '',
    );
  }
}
