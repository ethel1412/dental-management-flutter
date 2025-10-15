class Appointment {
  final int id;
  final String appointmentId;
  final int patientId;
  final int doctorId;
  final int? clinicId;
  final DateTime appointmentDate;
  final String? appointmentTime;
  final String appointmentType;
  final String? chiefComplaint;
  final String status;
  final String? cancellationReason;
  final DateTime? createdAt;

  Appointment({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    this.clinicId,
    required this.appointmentDate,
    this.appointmentTime,
    required this.appointmentType,
    this.chiefComplaint,
    required this.status,
    this.cancellationReason,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      appointmentId: json['appointment_id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      clinicId: json['clinic_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      appointmentTime: json['appointment_time'],
      appointmentType: json['appointment_type'],
      chiefComplaint: json['chief_complaint'],
      status: json['status'],
      cancellationReason: json['cancellation_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'clinic_id': clinicId,
      'appointment_date': appointmentDate.toIso8601String(),
      'appointment_time': appointmentTime,
      'appointment_type': appointmentType,
      'chief_complaint': chiefComplaint,
      'status': status,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
