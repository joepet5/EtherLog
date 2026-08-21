class CaseRecord {
  final String id;
  final String caseNumber;
  final DateTime date;

  final String? anaesthesiaStartTime;
  final String? anaesthesiaEndTime;
  final String? anaesthesiaDuration;
  final String? surgeryStartTime;
  final String? surgeryEndTime;
  final String? surgeryDuration;

  final String specialty;
  final String? specialtyOther;
  final String diagnosis;
  final String procedure;
  final String priority;
  final String asaGrade;
  final String technique;
  final String role;

  final bool difficultAirway;
  final int? difficultAirwayAttempts;
  final String? notes;

  final double? patientAge;
  final String ageUnit;
  final String? patientGender;
  final double? patientWeight;
  final double? patientHeight;
  final double? bmi;
  final String? hospital;
  final String? supervisor;

  final String? airwayManagement;
  final String? cormackLehane;
  final String? typeOfIntubation;
  final String? methodOfIntubation;
  final String? methodOfIntubationRole;
  final String? ettType;
  final double? ettSize;
  final String? lmaType;
  final double? lmaSize;
  final String? lmaRole;

  final List<Map<String, dynamic>> invasiveMonitoring;
  final List<String> complications;
  final String? outcome;
  final String? caseSheetImagePath;
  final List<Map<String, dynamic>> regionalBlocks;
  final bool catheterPlaced;

  /// Rare / unique case flag for later filtering.
  final bool starred;

  /// Manual or auto post-op follow-up (rounding queue).
  final bool flagForFollowUp;
  /// none | pending | completed | dismissed | expired
  final String followUpStatus;
  final DateTime? followUpCompletedAt;

  // Stage 2 follow-up form data
  final int? restPainScore;
  final int? movementPainScore;
  final String? ponv; // None | Nausea only | Vomiting
  final List<String> blockAssessmentTags;
  final List<String> followUpComplications;
  final String? followUpNotes;

  CaseRecord({
    String? id,
    required this.caseNumber,
    required this.date,
    this.anaesthesiaStartTime,
    this.anaesthesiaEndTime,
    this.anaesthesiaDuration,
    this.surgeryStartTime,
    this.surgeryEndTime,
    this.surgeryDuration,
    required this.specialty,
    this.specialtyOther,
    required this.diagnosis,
    required this.procedure,
    required this.priority,
    required this.asaGrade,
    required this.technique,
    required this.role,
    this.difficultAirway = false,
    this.difficultAirwayAttempts,
    this.notes,
    this.patientAge,
    this.ageUnit = 'years',
    this.patientGender,
    this.patientWeight,
    this.patientHeight,
    this.bmi,
    this.hospital,
    this.supervisor,
    this.airwayManagement,
    this.cormackLehane,
    this.typeOfIntubation,
    this.methodOfIntubation,
    this.methodOfIntubationRole,
    this.ettType,
    this.ettSize,
    this.lmaType,
    this.lmaSize,
    this.lmaRole,
    List<Map<String, dynamic>>? invasiveMonitoring,
    List<String>? complications,
    this.outcome,
    this.caseSheetImagePath,
    List<Map<String, dynamic>>? regionalBlocks,
    this.catheterPlaced = false,
    this.starred = false,
    this.flagForFollowUp = false,
    this.followUpStatus = 'none',
    this.followUpCompletedAt,
    this.restPainScore,
    this.movementPainScore,
    this.ponv,
    List<String>? blockAssessmentTags,
    List<String>? followUpComplications,
    this.followUpNotes,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        invasiveMonitoring = invasiveMonitoring ?? const [],
        complications = complications ?? const [],
        regionalBlocks = regionalBlocks ?? const [],
        blockAssessmentTags = blockAssessmentTags ?? const [],
        followUpComplications = followUpComplications ?? const [];

  List<String> get regionalBlockNames {
    return regionalBlocks
        .map((e) => (e['name'] ?? e['block'] ?? '').toString())
        .where((n) => n.trim().isNotEmpty)
        .toList();
  }

  CaseRecord copyWith({
    String? id,
    String? caseNumber,
    DateTime? date,
    String? anaesthesiaStartTime,
    String? anaesthesiaEndTime,
    String? anaesthesiaDuration,
    String? surgeryStartTime,
    String? surgeryEndTime,
    String? surgeryDuration,
    String? specialty,
    String? specialtyOther,
    String? diagnosis,
    String? procedure,
    String? priority,
    String? asaGrade,
    String? technique,
    String? role,
    bool? difficultAirway,
    int? difficultAirwayAttempts,
    String? notes,
    double? patientAge,
    String? ageUnit,
    String? patientGender,
    double? patientWeight,
    double? patientHeight,
    double? bmi,
    String? hospital,
    String? supervisor,
    String? airwayManagement,
    String? cormackLehane,
    String? typeOfIntubation,
    String? methodOfIntubation,
    String? methodOfIntubationRole,
    String? ettType,
    double? ettSize,
    String? lmaType,
    double? lmaSize,
    String? lmaRole,
    List<Map<String, dynamic>>? invasiveMonitoring,
    List<String>? complications,
    String? outcome,
    String? caseSheetImagePath,
    List<Map<String, dynamic>>? regionalBlocks,
    bool? catheterPlaced,
    bool? starred,
    bool? flagForFollowUp,
    String? followUpStatus,
    DateTime? followUpCompletedAt,
    int? restPainScore,
    int? movementPainScore,
    String? ponv,
    List<String>? blockAssessmentTags,
    List<String>? followUpComplications,
    String? followUpNotes,
  }) {
    return CaseRecord(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      date: date ?? this.date,
      anaesthesiaStartTime: anaesthesiaStartTime ?? this.anaesthesiaStartTime,
      anaesthesiaEndTime: anaesthesiaEndTime ?? this.anaesthesiaEndTime,
      anaesthesiaDuration: anaesthesiaDuration ?? this.anaesthesiaDuration,
      surgeryStartTime: surgeryStartTime ?? this.surgeryStartTime,
      surgeryEndTime: surgeryEndTime ?? this.surgeryEndTime,
      surgeryDuration: surgeryDuration ?? this.surgeryDuration,
      specialty: specialty ?? this.specialty,
      specialtyOther: specialtyOther ?? this.specialtyOther,
      diagnosis: diagnosis ?? this.diagnosis,
      procedure: procedure ?? this.procedure,
      priority: priority ?? this.priority,
      asaGrade: asaGrade ?? this.asaGrade,
      technique: technique ?? this.technique,
      role: role ?? this.role,
      difficultAirway: difficultAirway ?? this.difficultAirway,
      difficultAirwayAttempts:
      difficultAirwayAttempts ?? this.difficultAirwayAttempts,
      notes: notes ?? this.notes,
      patientAge: patientAge ?? this.patientAge,
      ageUnit: ageUnit ?? this.ageUnit,
      patientGender: patientGender ?? this.patientGender,
      patientWeight: patientWeight ?? this.patientWeight,
      patientHeight: patientHeight ?? this.patientHeight,
      bmi: bmi ?? this.bmi,
      hospital: hospital ?? this.hospital,
      supervisor: supervisor ?? this.supervisor,
      airwayManagement: airwayManagement ?? this.airwayManagement,
      cormackLehane: cormackLehane ?? this.cormackLehane,
      typeOfIntubation: typeOfIntubation ?? this.typeOfIntubation,
      methodOfIntubation: methodOfIntubation ?? this.methodOfIntubation,
      methodOfIntubationRole:
      methodOfIntubationRole ?? this.methodOfIntubationRole,
      ettType: ettType ?? this.ettType,
      ettSize: ettSize ?? this.ettSize,
      lmaType: lmaType ?? this.lmaType,
      lmaSize: lmaSize ?? this.lmaSize,
      lmaRole: lmaRole ?? this.lmaRole,
      invasiveMonitoring: invasiveMonitoring ?? this.invasiveMonitoring,
      complications: complications ?? this.complications,
      outcome: outcome ?? this.outcome,
      caseSheetImagePath: caseSheetImagePath ?? this.caseSheetImagePath,
      regionalBlocks: regionalBlocks ?? this.regionalBlocks,
      catheterPlaced: catheterPlaced ?? this.catheterPlaced,
      starred: starred ?? this.starred,
      flagForFollowUp: flagForFollowUp ?? this.flagForFollowUp,
      followUpStatus: followUpStatus ?? this.followUpStatus,
      followUpCompletedAt: followUpCompletedAt ?? this.followUpCompletedAt,
      restPainScore: restPainScore ?? this.restPainScore,
      movementPainScore: movementPainScore ?? this.movementPainScore,
      ponv: ponv ?? this.ponv,
      blockAssessmentTags: blockAssessmentTags ?? this.blockAssessmentTags,
      followUpComplications: followUpComplications ?? this.followUpComplications,
      followUpNotes: followUpNotes ?? this.followUpNotes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'caseNumber': caseNumber,
    'date': date.toIso8601String(),
    'anaesthesiaStartTime': anaesthesiaStartTime,
    'anaesthesiaEndTime': anaesthesiaEndTime,
    'anaesthesiaDuration': anaesthesiaDuration,
    'surgeryStartTime': surgeryStartTime,
    'surgeryEndTime': surgeryEndTime,
    'surgeryDuration': surgeryDuration,
    'specialty': specialty,
    'specialtyOther': specialtyOther,
    'diagnosis': diagnosis,
    'procedure': procedure,
    'priority': priority,
    'asaGrade': asaGrade,
    'technique': technique,
    'role': role,
    'difficultAirway': difficultAirway,
    'difficultAirwayAttempts': difficultAirwayAttempts,
    'notes': notes,
    'patientAge': patientAge,
    'ageUnit': ageUnit,
    'patientGender': patientGender,
    'patientWeight': patientWeight,
    'patientHeight': patientHeight,
    'bmi': bmi,
    'hospital': hospital,
    'supervisor': supervisor,
    'airwayManagement': airwayManagement,
    'cormackLehane': cormackLehane,
    'typeOfIntubation': typeOfIntubation,
    'methodOfIntubation': methodOfIntubation,
    'methodOfIntubationRole': methodOfIntubationRole,
    'ettType': ettType,
    'ettSize': ettSize,
    'lmaType': lmaType,
    'lmaSize': lmaSize,
    'lmaRole': lmaRole,
    'invasiveMonitoring': invasiveMonitoring,
    'complications': complications,
    'outcome': outcome,
    'caseSheetImagePath': caseSheetImagePath,
    'regionalBlocks': regionalBlocks,
    'catheterPlaced': catheterPlaced,
    'starred': starred,
    'flagForFollowUp': flagForFollowUp,
    'followUpStatus': followUpStatus,
    'followUpCompletedAt': followUpCompletedAt?.toIso8601String(),
    'restPainScore': restPainScore,
    'movementPainScore': movementPainScore,
    'ponv': ponv,
    'blockAssessmentTags': blockAssessmentTags,
    'followUpComplications': followUpComplications,
    'followUpNotes': followUpNotes,
  };

  factory CaseRecord.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> mapList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    List<String> stringList(dynamic raw) {
      if (raw is! List) {
        if (raw is String && raw.trim().isNotEmpty) return [raw];
        return [];
      }
      return raw.map((e) => e.toString()).toList();
    }

    return CaseRecord(
      id: json['id']?.toString(),
      caseNumber: json['caseNumber']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      anaesthesiaStartTime: json['anaesthesiaStartTime']?.toString(),
      anaesthesiaEndTime: json['anaesthesiaEndTime']?.toString(),
      anaesthesiaDuration: json['anaesthesiaDuration']?.toString(),
      surgeryStartTime: json['surgeryStartTime']?.toString(),
      surgeryEndTime: json['surgeryEndTime']?.toString(),
      surgeryDuration: json['surgeryDuration']?.toString(),
      specialty: json['specialty']?.toString() ?? '',
      specialtyOther: json['specialtyOther']?.toString(),
      diagnosis: json['diagnosis']?.toString() ?? '',
      procedure: json['procedure']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Elective',
      asaGrade: json['asaGrade']?.toString() ?? 'ASA I',
      technique: json['technique']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Consultant',
      difficultAirway: json['difficultAirway'] == true,
      difficultAirwayAttempts: json['difficultAirwayAttempts'] is int
          ? json['difficultAirwayAttempts'] as int
          : int.tryParse('${json['difficultAirwayAttempts'] ?? ''}'),
      notes: json['notes']?.toString(),
      patientAge: (json['patientAge'] is num)
          ? (json['patientAge'] as num).toDouble()
          : double.tryParse('${json['patientAge'] ?? ''}'),
      ageUnit: json['ageUnit']?.toString() ?? 'years',
      patientGender: json['patientGender']?.toString(),
      patientWeight: (json['patientWeight'] is num)
          ? (json['patientWeight'] as num).toDouble()
          : double.tryParse('${json['patientWeight'] ?? ''}'),
      patientHeight: (json['patientHeight'] is num)
          ? (json['patientHeight'] as num).toDouble()
          : double.tryParse('${json['patientHeight'] ?? ''}'),
      bmi: (json['bmi'] is num)
          ? (json['bmi'] as num).toDouble()
          : double.tryParse('${json['bmi'] ?? ''}'),
      hospital: json['hospital']?.toString(),
      supervisor: json['supervisor']?.toString(),
      airwayManagement: json['airwayManagement']?.toString(),
      cormackLehane: json['cormackLehane']?.toString(),
      typeOfIntubation: json['typeOfIntubation']?.toString(),
      methodOfIntubation: json['methodOfIntubation']?.toString(),
      methodOfIntubationRole: json['methodOfIntubationRole']?.toString(),
      ettType: json['ettType']?.toString(),
      ettSize: (json['ettSize'] is num)
          ? (json['ettSize'] as num).toDouble()
          : double.tryParse('${json['ettSize'] ?? ''}'),
      lmaType: json['lmaType']?.toString(),
      lmaSize: (json['lmaSize'] is num)
          ? (json['lmaSize'] as num).toDouble()
          : double.tryParse('${json['lmaSize'] ?? ''}'),
      lmaRole: json['lmaRole']?.toString(),
      invasiveMonitoring: mapList(json['invasiveMonitoring']),
      complications: stringList(json['complications']),
      outcome: json['outcome']?.toString(),
      caseSheetImagePath: json['caseSheetImagePath']?.toString(),
      regionalBlocks: mapList(json['regionalBlocks']),
      catheterPlaced: json['catheterPlaced'] == true,
      starred: json['starred'] == true,
      flagForFollowUp: json['flagForFollowUp'] == true,
      followUpStatus: json['followUpStatus']?.toString() ?? 'none',
      followUpCompletedAt: json['followUpCompletedAt'] != null
          ? DateTime.tryParse(json['followUpCompletedAt'].toString())
          : null,
      restPainScore: json['restPainScore'] is int
          ? json['restPainScore'] as int
          : int.tryParse('${json['restPainScore'] ?? ''}'),
      movementPainScore: json['movementPainScore'] is int
          ? json['movementPainScore'] as int
          : int.tryParse('${json['movementPainScore'] ?? ''}'),
      ponv: json['ponv']?.toString(),
      blockAssessmentTags: stringList(json['blockAssessmentTags']),
      followUpComplications: stringList(json['followUpComplications']),
      followUpNotes: json['followUpNotes']?.toString(),
    );
  }
}