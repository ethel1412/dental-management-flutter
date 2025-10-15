class Doctor {
  final int id;
  final String doctorId;
  final int userId;
  final String fullName;
  final String specialization;
  final int yearsOfExperience;
  final String dciRegistrationNumber;
  final String qualificationBds;
  final String? qualificationMds;
  final String? additionalQualifications;
  final String? dciCertificatePath;
  final String? profileImagePath;
  final double consultationFeeOffline;
  final double? consultationFeeOnline;
  final int bookingLimitPerDay;
  final bool isActive;
  final DateTime? createdAt;

  Doctor({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.fullName,
    required this.specialization,
    required this.yearsOfExperience,
    required this.dciRegistrationNumber,
    required this.qualificationBds,
    this.qualificationMds,
    this.additionalQualifications,
    this.dciCertificatePath,
    this.profileImagePath,
    required this.consultationFeeOffline,
    this.consultationFeeOnline,
    required this.bookingLimitPerDay,
    this.isActive = true,
    this.createdAt,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      doctorId: json['doctor_id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      specialization: json['specialization'],
      yearsOfExperience: json['years_of_experience'],
      dciRegistrationNumber: json['dci_registration_number'],
      qualificationBds: json['qualification_bds'],
      qualificationMds: json['qualification_mds'],
      additionalQualifications: json['additional_qualifications'],
      dciCertificatePath: json['dci_certificate_path'],
      profileImagePath: json['profile_image_path'],
      consultationFeeOffline: (json['consultation_fee_offline'] ?? 0).toDouble(),
      consultationFeeOnline: json['consultation_fee_online'] != null
          ? (json['consultation_fee_online']).toDouble()
          : null,
      bookingLimitPerDay: json['booking_limit_per_day'] ?? 10,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'user_id': userId,
      'full_name': fullName,
      'specialization': specialization,
      'years_of_experience': yearsOfExperience,
      'dci_registration_number': dciRegistrationNumber,
      'qualification_bds': qualificationBds,
      'qualification_mds': qualificationMds,
      'additional_qualifications': additionalQualifications,
      'dci_certificate_path': dciCertificatePath,
      'profile_image_path': profileImagePath,
      'consultation_fee_offline': consultationFeeOffline,
      'consultation_fee_online': consultationFeeOnline,
      'booking_limit_per_day': bookingLimitPerDay,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
