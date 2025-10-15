class Patient {
  final int id;
  final String patientId;
  final int userId;
  final String fullName;
  final int age;
  final String gender;
  final String? profileImagePath;
  final bool consentGiven;
  final bool isActive;
  final DateTime? createdAt;

  Patient({
    required this.id,
    required this.patientId,
    required this.userId,
    required this.fullName,
    required this.age,
    required this.gender,
    this.profileImagePath,
    required this.consentGiven,
    this.isActive = true,
    this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      patientId: json['patient_id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      age: json['age'],
      gender: json['gender'],
      profileImagePath: json['profile_image_path'],
      consentGiven: json['consent_given'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'user_id': userId,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'profile_image_path': profileImagePath,
      'consent_given': consentGiven,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
