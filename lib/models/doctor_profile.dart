class DoctorProfile {
  final String name;
  final String qualifications;
  final String designation;
  final String hospital;
  final String? registrationNumber;
  final String accentKey;
  final bool idleAnimationEnabled;
  final DateTime? dateOfBirth;

  const DoctorProfile({
    this.name = '',
    this.qualifications = '',
    this.designation = '',
    this.hospital = '',
    this.registrationNumber,
    this.accentKey = 'default',
    this.idleAnimationEnabled = true,
    this.dateOfBirth,
  });
}