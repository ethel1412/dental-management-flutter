import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Token (SharedPreferences — persists until logout) ──────────────────
  Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(AppConstants.keyToken, token);
  }

  Future<String?> getToken() async {
    await init();
    return _prefs!.getString(AppConstants.keyToken);
  }

  Future<void> removeToken() async {
    await init();
    await _prefs!.remove(AppConstants.keyToken);
  }

  // ── User ID ────────────────────────────────────────────────────────────
  Future<void> saveUserId(int userId) async {
    await init();
    await _prefs!.setInt(AppConstants.keyUserId, userId);
  }

  Future<int?> getUserId() async {
    await init();
    return _prefs!.getInt(AppConstants.keyUserId);
  }

  // ── User Role ──────────────────────────────────────────────────────────
  Future<void> saveUserRole(String role) async {
    await init();
    await _prefs!.setString(AppConstants.keyUserRole, role);
  }

  Future<String?> getUserRole() async {
    await init();
    return _prefs!.getString(AppConstants.keyUserRole);
  }

  // ── User Data ──────────────────────────────────────────────────────────
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await init();
    await _prefs!.setString(AppConstants.keyUserData, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    await init();
    final data = _prefs!.getString(AppConstants.keyUserData);
    if (data != null) return jsonDecode(data);
    return null;
  }

  // ── Login Status ───────────────────────────────────────────────────────
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await init();
    await _prefs!.setBool(AppConstants.keyIsLoggedIn, isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    await init();
    return _prefs!.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  // ── Clear All (logout) ─────────────────────────────────────────────────
  Future<void> clearAll() async {
    await init();
    await _prefs!.clear();
  }

  // ── Generic helpers ────────────────────────────────────────────────────
  Future<void> saveString(String key, String value) async {
    await init();
    await _prefs!.setString(key, value);
  }

  Future<String?> getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  Future<void> saveInt(String key, int value) async {
    await init();
    await _prefs!.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    await init();
    return _prefs!.getInt(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await init();
    await _prefs!.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    await init();
    return _prefs!.getBool(key);
  }
}
