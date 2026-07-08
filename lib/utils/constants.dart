import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'ScanMyTooth';
  static const String appVersion = '1.0.0';

  // User Roles
  static const String roleDoctor = 'doctor';
  static const String rolePatient = 'patient';
  static const String roleLab = 'lab';

  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Date Formats
  static const String dateFormat = 'dd-MM-yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd-MM-yyyy hh:mm a';

  // Specializations
  static const List<String> specializations = [
    'General Dentist',
    'Orthodontist',
    'Periodontist',
    'Endodontist',
    'Oral Surgeon',
    'Prosthodontist',
    'Pediatric Dentist',
    'Cosmetic Dentist',
  ];

  // Lab Types
  static const List<String> labTypes = [
    'dental',
    'diagnostic',
    'both',
  ];

  // Gender Options
  static const List<String> genders = [
    'male',
    'female',
    'other',
  ];

  // Appointment Status
  static const String statusScheduled = 'scheduled';
  static const String statusConfirmed = 'confirmed';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Colors
  static const Color primaryColor = Color(0xFF2C3E9B);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
}
