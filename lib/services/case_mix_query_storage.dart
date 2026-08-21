import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedMixQuery {
  final String id;
  final String name;
  final List<Map<String, String>> conditions; // field, op, value
  final DateTime createdAt;

  SavedMixQuery({
    required this.id,
    required this.name,
    required this.conditions,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'conditions': conditions,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedMixQuery.fromJson(Map<String, dynamic> json) {
    final raw = json['conditions'];
    final list = <Map<String, String>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add({
            'field': '${e['field'] ?? ''}',
            'op': '${e['op'] ?? ''}',
            'value': '${e['value'] ?? ''}',
          });
        }
      }
    }
    return SavedMixQuery(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Untitled',
      conditions: list,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CaseMixQueryStorage {
  static const _key = 'etherlog_saved_mix_queries';

  static Future<List<SavedMixQuery>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => SavedMixQuery.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(SavedMixQuery query) async {
    final all = await getAll();
    all.removeWhere((q) => q.id == query.id);
    all.add(query);
    await _persist(all);
  }

  static Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((q) => q.id == id);
    await _persist(all);
  }

  static Future<void> _persist(List<SavedMixQuery> queries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(queries.map((q) => q.toJson()).toList()),
    );
  }
}