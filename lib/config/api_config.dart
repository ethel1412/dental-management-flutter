class ApiConfig {
  static const String baseUrl = 'https://dental-management-api-hjeh.onrender.com';

  // API Endpoints
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String authResendOtp = '/api/auth/resend-otp';

  // Doctor Endpoints
  static const String doctorRegister = '/api/doctors/register';
  static const String doctorProfile = '/api/doctors/profile';
  static const String doctorSearch = '/api/doctors/search';

  // Patient Endpoints
  static const String patientRegister = '/api/patients/register';
  static const String patientProfile = '/api/patients/profile';

  // Lab Endpoints
  static const String labRegister = '/api/labs/register';
  static const String labProfile = '/api/labs/profile';

  // Appointment Endpoints
  static const String appointments = '/api/appointments';
  static const String myAppointments = '/api/appointments/my-appointments';

  // Clinical Profile Endpoints
  static const String clinicalProfiles = '/api/clinical-profiles';

  // Lab Orders
  static const String labOrders = '/api/lab-orders';

  // ML Analysis
  static const String analyzeXray = '/api/ml-analysis/analyze-xray-direct';
}
