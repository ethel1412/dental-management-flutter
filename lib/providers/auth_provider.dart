import 'package:flutter/material.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  String? _userRole;
  int? _userId;
  Map<String, dynamic>? _userData;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  String? get userRole => _userRole;
  int? get userId => _userId;
  Map<String, dynamic>? get userData => _userData;

  // Check login status on app start
  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      _userRole = await _storage.getUserRole();
      _userId = await _storage.getUserId();
      _userData = await _storage.getUserData();
    }
    notifyListeners();
  }

  // Register user
  Future<bool> register(
      String mobileNumber,
      String password,
      String role,
      String? email,
      ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(mobileNumber, password, role, email);
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

  // Login
  Future<bool> login(String mobileNumber, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(mobileNumber, password);
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

  // Verify OTP
  Future<bool> verifyOTP(String mobileNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyOTP(mobileNumber, otp);

      _isLoggedIn = true;
      if (response.containsKey('user')) {
        _userData = response['user'];
        _userRole = _userData!['role'];
        _userId = _userData!['id'];
      }

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

  // Resend OTP
  Future<bool> resendOTP(String mobileNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resendOTP(mobileNumber);
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

  // Register Doctor
  Future<bool> registerDoctor(
      Map<String, String> data,
      File? dciCertificate,
      File? profileImage,
      ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registerDoctor(data, dciCertificate, profileImage);
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

  // Register Patient
  Future<bool> registerPatient(
      Map<String, String> data,
      File? profileImage,
      ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registerPatient(data, profileImage);
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

  // Register Lab
  Future<bool> registerLab(
      Map<String, String> data,
      File? registrationCertificate,
      File? labImage,
      ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registerLab(data, registrationCertificate, labImage);
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

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _userRole = null;
    _userId = null;
    _userData = null;
    _error = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
