import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save auth token (secure)
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyToken, value: token);
  }

  // Get auth token (secure)
  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.keyToken);
  }

  // Remove auth token
  Future<void> removeToken() async {
    await _secureStorage.delete(key: AppConstants.keyToken);
  }

  // Save user ID
  Future<void> saveUserId(int userId) async {
    await init();
    await _prefs!.setInt(AppConstants.keyUserId, userId);
  }

  // Get user ID
  Future<int?> getUserId() async {
    await init();
    return _prefs!.getInt(AppConstants.keyUserId);
  }

  // Save user role
  Future<void> saveUserRole(String role) async {
    await init();
    await _prefs!.setString(AppConstants.keyUserRole, role);
  }

  // Get user role
  Future<String?> getUserRole() async {
    await init();
    return _prefs!.getString(AppConstants.keyUserRole);
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await init();
    await _prefs!.setString(AppConstants.keyUserData, jsonEncode(userData));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    await init();
    final data = _prefs!.getString(AppConstants.keyUserData);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // Save login status
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await init();
    await _prefs!.setBool(AppConstants.keyIsLoggedIn, isLoggedIn);
  }

  // Get login status
  Future<bool> isLoggedIn() async {
    await init();
    return _prefs!.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await init();
    await _secureStorage.deleteAll();
    await _prefs!.clear();
  }

  // Save string
  Future<void> saveString(String key, String value) async {
    await init();
    await _prefs!.setString(key, value);
  }

  // Get string
  Future<String?> getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  // Save int
  Future<void> saveInt(String key, int value) async {
    await init();
    await _prefs!.setInt(key, value);
  }

  // Get int
  Future<int?> getInt(String key) async {
    await init();
    return _prefs!.getInt(key);
  }

  // Save bool
  Future<void> saveBool(String key, bool value) async {
    await init();
    await _prefs!.setBool(key, value);
  }

  // Get bool
  Future<bool?> getBool(String key) async {
    await init();
    return _prefs!.getBool(key);
  }
}
