import '../config/api_config.dart';
import '../models/doctor_model.dart';
import 'api_service.dart';

class DoctorService {
  final ApiService _api = ApiService();

  // Get doctor profile
  Future<Doctor> getProfile() async {
    final response = await _api.get(ApiConfig.doctorProfile);
    return Doctor.fromJson(response);
  }

  // Update doctor profile
  Future<Doctor> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put(ApiConfig.doctorProfile, data);
    return Doctor.fromJson(response);
  }

  // Search doctors
  Future<List<Doctor>> searchDoctors({
    String? specialization,
    String? city,
    String? name,
  }) async {
    String endpoint = ApiConfig.doctorSearch;
    final params = <String>[];

    if (specialization != null) params.add('specialization=$specialization');
    if (city != null) params.add('city=$city');
    if (name != null) params.add('name=$name');

    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }

    final response = await _api.get(endpoint, includeAuth: false);

    if (response['doctors'] != null) {
      return (response['doctors'] as List)
          .map((json) => Doctor.fromJson(json))
          .toList();
    }

    return [];
  }

  // Get doctor by ID
  Future<Doctor> getDoctorById(int doctorId) async {
    final response = await _api.get('${ApiConfig.doctorProfile}/$doctorId');
    return Doctor.fromJson(response);
  }
}
