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
  final String? email;

  const OTPVerificationScreen({
    super.key,
    required this.mobileNumber,
    this.email,
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
    _otpController = TextEditingController();
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
      Helpers.showToast('OTP resent to your email!');
    } else {
      Helpers.showToast(
        authProvider.error ?? 'Failed to send OTP',
        isError: true,
      );
    }
  }

  // Mask email for display: abc***@gmail.com
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) return '***@$domain';
    return '${name.substring(0, 3)}***@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = widget.email != null ? _maskEmail(widget.email!) : null;

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
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Check Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayEmail != null
                      ? 'We sent a 6-digit OTP to\n$displayEmail'
                      : 'Enter the 6-digit OTP sent to your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),
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
