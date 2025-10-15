import 'dart:io';
import '../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // Register user (initial step)
  Future<Map<String, dynamic>> register(
      String mobileNumber,
      String password,
      String role,
      String? email,
      ) async {
    final response = await _api.post(
      ApiConfig.authRegister,
      {
        'mobile_number': mobileNumber,
        'password': password,
        'role': role,
        if (email != null) 'email': email,
      },
      includeAuth: false,
    );

    return response;
  }

  // Login
  Future<Map<String, dynamic>> login(String mobileNumber, String password) async {
    final response = await _api.post(
      ApiConfig.authLogin,
      {
        'mobile_number': mobileNumber,
        'password': password,
      },
      includeAuth: false,
    );

    return response;
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String mobileNumber, String otp) async {
    final response = await _api.post(
      ApiConfig.authVerifyOtp,
      {
        'mobile_number': mobileNumber,
        'otp': otp,
      },
      includeAuth: false,
    );

    // Save token and user data
    if (response.containsKey('access_token')) {
      await _storage.saveToken(response['access_token']);
      await _storage.saveLoginStatus(true);

      if (response.containsKey('user')) {
        final user = response['user'];
        await _storage.saveUserId(user['id']);
        await _storage.saveUserRole(user['role']);
        await _storage.saveUserData(user);
      }
    }

    return response;
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String mobileNumber) async {
    final response = await _api.post(
      ApiConfig.authResendOtp,
      {
        'mobile_number': mobileNumber,
      },
      includeAuth: false,
    );

    return response;
  }

  // Register Doctor (with files)
  Future<Map<String, dynamic>> registerDoctor(
      Map<String, String> data,
      File? dciCertificate,
      File? profileImage,
      ) async {
    final files = <String, File>{};
    if (dciCertificate != null) files['dci_certificate'] = dciCertificate;
    if (profileImage != null) files['profile_image'] = profileImage;

    return await _api.multipartRequest(
      ApiConfig.doctorRegister,
      data,
      files,
    );
  }

  // Register Patient (with files)
  Future<Map<String, dynamic>> registerPatient(
      Map<String, String> data,
      File? profileImage,
      ) async {
    final files = <String, File>{};
    if (profileImage != null) files['profile_image'] = profileImage;

    return await _api.multipartRequest(
      ApiConfig.patientRegister,
      data,
      files,
    );
  }

  // Register Lab (with files)
  Future<Map<String, dynamic>> registerLab(
      Map<String, String> data,
      File? registrationCertificate,
      File? labImage,
      ) async {
    final files = <String, File>{};
    if (registrationCertificate != null) {
      files['registration_certificate'] = registrationCertificate;
    }
    if (labImage != null) files['lab_image'] = labImage;

    return await _api.multipartRequest(
      ApiConfig.labRegister,
      data,
      files,
    );
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearAll();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  // Get current user role
  Future<String?> getCurrentUserRole() async {
    return await _storage.getUserRole();
  }
}
