import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../doctor/doctor_dashboard_screen.dart';
import '../patient/patient_dashboard_screen.dart';
import '../lab/lab_dashboard_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobileNumber;

  /// DEV ONLY: when provided, the OTP field is pre-filled and a debug banner is shown.
  final String? prefillOtp;

  const OTPVerificationScreen({
    super.key,
    required this.mobileNumber,
    this.prefillOtp,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    // Pre-fill OTP in debug mode
    _otpController = TextEditingController(
      text: (kDebugMode && widget.prefillOtp != null) ? widget.prefillOtp : '',
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOTP(
      widget.mobileNumber,
      _otpController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Helpers.showToast('Login successful!');

      // Navigate to appropriate dashboard
      Widget screen;
      switch (authProvider.userRole) {
        case AppConstants.roleDoctor:
          screen = const DoctorDashboardScreen();
          break;
        case AppConstants.rolePatient:
          screen = const PatientDashboardScreen();
          break;
        case AppConstants.roleLab:
          screen = const LabDashboardScreen();
          break;
        default:
          Helpers.showToast('Invalid user role', isError: true);
          return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => screen),
        (route) => false,
      );
    } else {
      Helpers.showToast(
        authProvider.error ?? 'OTP verification failed',
        isError: true,
      );
    }
  }

  Future<void> _handleResendOTP() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendOTP(widget.mobileNumber);

    if (!mounted) return;

    if (success) {
      Helpers.showToast('OTP sent successfully!');
      // DEV: update the pre-filled OTP field with the new OTP
      if (kDebugMode && authProvider.devOtp != null) {
        _otpController.text = authProvider.devOtp!;
      }
    } else {
      Helpers.showToast(
        authProvider.error ?? 'Failed to send OTP',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.message,
                  size: 80,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to\n${widget.mobileNumber}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // DEV ONLY: amber banner showing the pre-filled OTP
                if (kDebugMode && widget.prefillOtp != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.developer_mode, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'DEV OTP: ${widget.prefillOtp}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                CustomTextField(
                  label: 'OTP',
                  hint: 'Enter 6-digit OTP',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.lock),
                  validator: Validators.validateOTP,
                  maxLength: 6,
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      text: 'Verify OTP',
                      onPressed: _handleVerifyOTP,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive OTP? ",
                      style: TextStyle(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleResendOTP,
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
