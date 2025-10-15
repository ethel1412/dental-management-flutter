import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../models/patient_model.dart';
import '../models/lab_model.dart';
import '../services/doctor_service.dart';

class UserProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();

  Doctor? _doctorProfile;
  Patient? _patientProfile;
  Lab? _labProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  Doctor? get doctorProfile => _doctorProfile;
  Patient? get patientProfile => _patientProfile;
  Lab? get labProfile => _labProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load doctor profile
  Future<void> loadDoctorProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _doctorProfile = await _doctorService.getProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update doctor profile
  Future<bool> updateDoctorProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _doctorProfile = await _doctorService.updateProfile(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Search doctors
  Future<List<Doctor>> searchDoctors({
    String? specialization,
    String? city,
    String? name,
  }) async {
    try {
      return await _doctorService.searchDoctors(
        specialization: specialization,
        city: city,
        name: name,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return [];
    }
  }

  // Clear profile data
  void clearProfile() {
    _doctorProfile = null;
    _patientProfile = null;
    _labProfile = null;
    _error = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
