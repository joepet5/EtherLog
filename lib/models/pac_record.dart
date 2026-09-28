import 'package:uuid/uuid.dart';

class PacRecord {
  final String id;
  final DateTime date;
  final int patientCount;
  final String? hospital;
  final String? notes;
  final DateTime createdAt;

  PacRecord({
    String? id,
    required this.date,
    required this.patientCount,
    this.hospital,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'patientCount': patientCount,
        'hospital': hospital,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PacRecord.fromJson(Map<String, dynamic> json) => PacRecord(
        id: json['id'] as String? ?? const Uuid().v4(),
        date: DateTime.parse(json['date'] as String),
        patientCount: (json['patientCount'] as num).toInt(),
        hospital: json['hospital'] as String?,
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  PacRecord copyWith({
    String? id,
    DateTime? date,
    int? patientCount,
    String? hospital,
    String? notes,
    DateTime? createdAt,
  }) {
    return PacRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      patientCount: patientCount ?? this.patientCount,
      hospital: hospital ?? this.hospital,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
