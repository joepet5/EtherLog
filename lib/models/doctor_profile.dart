class DoctorProfile {
  final String name;
  final String qualifications;
  final String designation;
  final String hospital;
  final String? registrationNumber;
  final String accentKey;
  final bool zenMode;
  final DateTime? dateOfBirth;
  final bool clinicalVerificationEnabled;

  const DoctorProfile({
    this.name = '',
    this.qualifications = '',
    this.designation = '',
    this.hospital = '',
    this.registrationNumber,
    this.accentKey = 'default',
    this.zenMode = false,
    this.dateOfBirth,
    this.clinicalVerificationEnabled = false,
  });

  DoctorProfile copyWith({
    String? name,
    String? qualifications,
    String? designation,
    String? hospital,
    String? registrationNumber,
    String? accentKey,
    bool? zenMode,
    DateTime? dateOfBirth,
    bool? clinicalVerificationEnabled,
  }) {
    return DoctorProfile(
      name: name ?? this.name,
      qualifications: qualifications ?? this.qualifications,
      designation: designation ?? this.designation,
      hospital: hospital ?? this.hospital,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      accentKey: accentKey ?? this.accentKey,
      zenMode: zenMode ?? this.zenMode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      clinicalVerificationEnabled:
          clinicalVerificationEnabled ?? this.clinicalVerificationEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'qualifications': qualifications,
        'designation': designation,
        'hospital': hospital,
        if (registrationNumber != null)
          'registrationNumber': registrationNumber,
        'accentKey': accentKey,
        'zenMode': zenMode,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
        'clinicalVerificationEnabled': clinicalVerificationEnabled,
      };

  factory DoctorProfile.fromJson(Map<String, dynamic> json) => DoctorProfile(
        name: json['name'] as String? ?? '',
        qualifications: json['qualifications'] as String? ?? '',
        designation: json['designation'] as String? ?? '',
        hospital: json['hospital'] as String? ?? '',
        registrationNumber: json['registrationNumber'] as String?,
        accentKey: json['accentKey'] as String? ?? 'default',
        zenMode: json['zenMode'] as bool? ?? false,
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'] as String)
            : null,
        clinicalVerificationEnabled:
            json['clinicalVerificationEnabled'] as bool? ?? false,
      );
}