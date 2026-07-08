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

  // DEV: stores the last OTP returned by the server
  String? _devOtp;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  String? get userRole => _userRole;
  int? get userId => _userId;
  Map<String, dynamic>? get userData => _userData;
  String? get devOtp => _devOtp;

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
    _devOtp = null;
    notifyListeners();
    try {
      final response =
          await _authService.register(mobileNumber, password, role, email);
      _devOtp = response['otp']?.toString();
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
    _devOtp = null;
    notifyListeners();
    try {
      final response = await _authService.login(mobileNumber, password);
      _devOtp = response['otp']?.toString();
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

  // Verify OTP — also persists session to storage so it survives hot restart
  Future<bool> verifyOTP(String mobileNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _authService.verifyOTP(mobileNumber, otp);

      _isLoggedIn = true;

      if (response.containsKey('user')) {
        _userData = response['user'] as Map<String, dynamic>;
        _userRole = _userData!['role']?.toString();
        final rawId = _userData!['id'];
        _userId = rawId is int ? rawId : int.tryParse(rawId.toString());
      }

      // Persist session — ensures screens survive hot restart / app relaunch
      if (response.containsKey('access_token')) {
        await _storage.saveToken(response['access_token'].toString());
        await _storage.saveLoginStatus(true);
        if (_userRole != null) await _storage.saveUserRole(_userRole!);
        if (_userId != null) await _storage.saveUserId(_userId!);
        if (_userData != null) await _storage.saveUserData(_userData!);
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
    _devOtp = null;
    notifyListeners();
    try {
      final response = await _authService.resendOTP(mobileNumber);
      _devOtp = response['otp']?.toString();
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
    _devOtp = null;
    notifyListeners();
    try {
      final response =
          await _authService.registerDoctor(data, dciCertificate, profileImage);
      _devOtp = response['otp']?.toString();
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
    _devOtp = null;
    notifyListeners();
    try {
      final response =
          await _authService.registerPatient(data, profileImage);
      _devOtp = response['otp']?.toString();
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
    _devOtp = null;
    notifyListeners();
    try {
      final response =
          await _authService.registerLab(data, registrationCertificate, labImage);
      _devOtp = response['otp']?.toString();
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
    _devOtp = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
