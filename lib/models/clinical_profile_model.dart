class ClinicalProfile {
  final int id;
  final String profileId;
  final int patientId;
  final int doctorId;
  final int? appointmentId;
  final String? chiefComplaint;
  final String? medicalHistory;
  final String? dentalHistory;
  final String? treatmentPlan;
  final String? diagnosis;
  final String? notes;
  final List<String>? xrayPaths;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClinicalProfile({
    required this.id,
    required this.profileId,
    required this.patientId,
    required this.doctorId,
    this.appointmentId,
    this.chiefComplaint,
    this.medicalHistory,
    this.dentalHistory,
    this.treatmentPlan,
    this.diagnosis,
    this.notes,
    this.xrayPaths,
    this.createdAt,
    this.updatedAt,
  });

  factory ClinicalProfile.fromJson(Map<String, dynamic> json) {
    return ClinicalProfile(
      id: json['id'],
      profileId: json['profile_id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      appointmentId: json['appointment_id'],
      chiefComplaint: json['chief_complaint'],
      medicalHistory: json['medical_history'],
      dentalHistory: json['dental_history'],
      treatmentPlan: json['treatment_plan'],
      diagnosis: json['diagnosis'],
      notes: json['notes'],
      xrayPaths: json['xray_paths'] != null
          ? List<String>.from(json['xray_paths'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_id': appointmentId,
      'chief_complaint': chiefComplaint,
      'medical_history': medicalHistory,
      'dental_history': dentalHistory,
      'treatment_plan': treatmentPlan,
      'diagnosis': diagnosis,
      'notes': notes,
      'xray_paths': xrayPaths,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
