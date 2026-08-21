import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/case_record.dart';
import 'case_storage.dart';

/// Clinical pattern only — never stores hospital numbers or identifiable patient data.
class CaseTemplate {
  final String id;
  final String name;
  final DateTime createdAt;
  final String specialty;
  final String? specialtyOther;
  final String technique;
  final String priority;
  final String asaGrade;
  final String role;
  final String? supervisor;
  final String airwayManagement;
  final String? cormackLehane;
  final String? typeOfIntubation;
  final String? methodOfIntubation;
  final String? methodOfIntubationRole;
  final String? ettType;
  final String? lmaType;
  final String? lmaRole;
  final bool difficultAirway;
  final List<Map<String, dynamic>> regionalBlocks;
  final List<Map<String, dynamic>> invasiveMonitoring;
  final bool catheterPlaced;
  final String? diagnosis;
  final String? procedure;
  final String? notes;
  final String? outcome;

  const CaseTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    this.specialty = 'General Surgery',
    this.specialtyOther,
    this.technique = 'General Anaesthesia (VA)',
    this.priority = 'Elective',
    this.asaGrade = 'ASA I',
    this.role = 'Consultant',
    this.supervisor,
    this.airwayManagement = 'Not applicable',
    this.cormackLehane,
    this.typeOfIntubation,
    this.methodOfIntubation,
    this.methodOfIntubationRole,
    this.ettType,
    this.lmaType,
    this.lmaRole,
    this.difficultAirway = false,
    this.regionalBlocks = const [],
    this.invasiveMonitoring = const [],
    this.catheterPlaced = false,
    this.diagnosis,
    this.procedure,
    this.notes,
    this.outcome,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'specialty': specialty,
    'specialtyOther': specialtyOther,
    'technique': technique,
    'priority': priority,
    'asaGrade': asaGrade,
    'role': role,
    'supervisor': supervisor,
    'airwayManagement': airwayManagement,
    'cormackLehane': cormackLehane,
    'typeOfIntubation': typeOfIntubation,
    'methodOfIntubation': methodOfIntubation,
    'methodOfIntubationRole': methodOfIntubationRole,
    'ettType': ettType,
    'lmaType': lmaType,
    'lmaRole': lmaRole,
    'difficultAirway': difficultAirway,
    'regionalBlocks': regionalBlocks,
    'invasiveMonitoring': invasiveMonitoring,
    'catheterPlaced': catheterPlaced,
    'diagnosis': diagnosis,
    'procedure': procedure,
    'notes': notes,
    'outcome': outcome,
  };

  factory CaseTemplate.fromJson(Map<String, dynamic> j) => CaseTemplate(
    id: j['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: j['name']?.toString() ?? 'Template',
    createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
    specialty: j['specialty']?.toString() ?? 'General Surgery',
    specialtyOther: j['specialtyOther']?.toString(),
    technique: j['technique']?.toString() ?? 'General Anaesthesia (VA)',
    priority: j['priority']?.toString() ?? 'Elective',
    asaGrade: j['asaGrade']?.toString() ?? 'ASA I',
    role: j['role']?.toString() ?? 'Consultant',
    supervisor: j['supervisor']?.toString(),
    airwayManagement: j['airwayManagement']?.toString() ?? 'Not applicable',
    cormackLehane: j['cormackLehane']?.toString(),
    typeOfIntubation: j['typeOfIntubation']?.toString(),
    methodOfIntubation: j['methodOfIntubation']?.toString(),
    methodOfIntubationRole: j['methodOfIntubationRole']?.toString(),
    ettType: j['ettType']?.toString(),
    lmaType: j['lmaType']?.toString(),
    lmaRole: j['lmaRole']?.toString(),
    difficultAirway: j['difficultAirway'] == true,
    regionalBlocks: (j['regionalBlocks'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    invasiveMonitoring: (j['invasiveMonitoring'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    catheterPlaced: j['catheterPlaced'] == true,
    diagnosis: j['diagnosis']?.toString(),
    procedure: j['procedure']?.toString(),
    notes: j['notes']?.toString(),
    outcome: j['outcome']?.toString(),
  );

  /// Build a template from a saved case (strips identifiers).
  factory CaseTemplate.fromCase(CaseRecord c, {required String name}) {
    return CaseTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      specialty: c.specialty,
      specialtyOther: c.specialtyOther,
      technique: c.technique,
      priority: c.priority,
      asaGrade: c.asaGrade,
      role: c.role,
      supervisor: c.supervisor,
      airwayManagement: c.airwayManagement ?? 'Not applicable',
      cormackLehane: c.cormackLehane,
      typeOfIntubation: c.typeOfIntubation,
      methodOfIntubation: c.methodOfIntubation,
      methodOfIntubationRole: c.methodOfIntubationRole,
      ettType: c.ettType,
      lmaType: c.lmaType,
      lmaRole: c.lmaRole,
      difficultAirway: c.difficultAirway,
      regionalBlocks: c.regionalBlocks.map((e) => Map<String, dynamic>.from(e)).toList(),
      invasiveMonitoring:
      c.invasiveMonitoring.map((e) => Map<String, dynamic>.from(e)).toList(),
      catheterPlaced: c.catheterPlaced,
      diagnosis: c.diagnosis,
      procedure: c.procedure,
      notes: null, // do not copy free-text notes by default
      outcome: c.outcome,
    );
  }
}

class TemplateStorage {
  static const _key = 'etherlog_case_templates';
  static const _draftKey = 'etherlog_case_draft';

  static Future<List<CaseTemplate>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CaseTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(CaseTemplate template) async {
    final all = await getAll();
    all.removeWhere((t) => t.id == template.id);
    all.insert(0, template);
    await _persist(all);
  }

  static Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((t) => t.id == id);
    await _persist(all);
  }

  static Future<void> rename(String id, String newName) async {
    final all = await getAll();
    final i = all.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = all[i];
    all[i] = CaseTemplate(
      id: t.id,
      name: newName.trim().isEmpty ? t.name : newName.trim(),
      createdAt: t.createdAt,
      specialty: t.specialty,
      specialtyOther: t.specialtyOther,
      technique: t.technique,
      priority: t.priority,
      asaGrade: t.asaGrade,
      role: t.role,
      supervisor: t.supervisor,
      airwayManagement: t.airwayManagement,
      cormackLehane: t.cormackLehane,
      typeOfIntubation: t.typeOfIntubation,
      methodOfIntubation: t.methodOfIntubation,
      methodOfIntubationRole: t.methodOfIntubationRole,
      ettType: t.ettType,
      lmaType: t.lmaType,
      lmaRole: t.lmaRole,
      difficultAirway: t.difficultAirway,
      regionalBlocks: t.regionalBlocks,
      invasiveMonitoring: t.invasiveMonitoring,
      catheterPlaced: t.catheterPlaced,
      diagnosis: t.diagnosis,
      procedure: t.procedure,
      notes: t.notes,
      outcome: t.outcome,
    );
    await _persist(all);
  }

  static Future<void> _persist(List<CaseTemplate> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((t) => t.toJson()).toList()));
  }

  /// Most recent logged case as a ready-to-apply template (no patient IDs).
  static Future<CaseTemplate?> lastCaseAsTemplate() async {
    final cases = await CaseStorage.getAllCases();
    if (cases.isEmpty) return null;
    cases.sort((a, b) => b.date.compareTo(a.date));
    final c = cases.first;
    final label = [
      if (c.specialty.isNotEmpty) c.specialty,
      if (c.procedure.isNotEmpty) c.procedure,
    ].join(' · ');
    return CaseTemplate.fromCase(
      c,
      name: label.isEmpty ? 'Last case' : 'Last: $label',
    );
  }

  // --- Draft (incomplete case) ---

  static Future<void> saveDraft(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    draft['savedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  static Future<Map<String, dynamic>?> getDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  static Future<bool> hasDraft() async {
    final d = await getDraft();
    return d != null && d.isNotEmpty;
  }
}