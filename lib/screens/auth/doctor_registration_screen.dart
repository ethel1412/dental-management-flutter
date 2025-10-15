import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() => _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dciRegController = TextEditingController();
  final _bdsController = TextEditingController();
  final _mdsController = TextEditingController();
  final _additionalQualController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeOfflineController = TextEditingController();
  final _feeOnlineController = TextEditingController();
  final _bookingLimitController = TextEditingController();

  String _selectedSpecialization = AppConstants.specializations[0];
  bool _obscurePassword = true;
  File? _profileImage;
  File? _dciCertificate;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _dciRegController.dispose();
    _bdsController.dispose();
    _mdsController.dispose();
    _additionalQualController.dispose();
    _experienceController.dispose();
    _feeOfflineController.dispose();
    _feeOnlineController.dispose();
    _bookingLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _dciCertificate = File(result.files.single.path!);
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    // Step 1: Register user account
    final userSuccess = await authProvider.register(
      _mobileController.text.trim(),
      _passwordController.text,
      AppConstants.roleDoctor,
      _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );

    if (!mounted) return;

    if (!userSuccess) {
      Helpers.showToast(
        authProvider.error ?? 'Registration failed',
        isError: true,
      );
      return;
    }

    // Step 2: Register doctor profile
    final data = {
      'mobile_number': _mobileController.text.trim(),
      'full_name': _fullNameController.text.trim(),
      'specialization': _selectedSpecialization,
      'years_of_experience': _experienceController.text.trim(),
      'dci_registration_number': _dciRegController.text.trim(),
      'qualification_bds': _bdsController.text.trim(),
      'qualification_mds': _mdsController.text.trim(),
      'additional_qualifications': _additionalQualController.text.trim(),
      'consultation_fee_offline': _feeOfflineController.text.trim(),
      'consultation_fee_online': _feeOnlineController.text.trim(),
      'booking_limit_per_day': _bookingLimitController.text.trim(),
    };

    final profileSuccess = await authProvider.registerDoctor(
      data,
      _dciCertificate,
      _profileImage,
    );

    if (!mounted) return;

    if (profileSuccess) {
      Helpers.showToast('Registration successful! Please verify OTP.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            mobileNumber: _mobileController.text.trim(),
          ),
        ),
      );
    } else {
      Helpers.showToast(
        authProvider.error ?? 'Profile registration failed',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to add photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                // Full Name
                CustomTextField(
                  label: 'Full Name *',
                  hint: 'Dr. John Doe',
                  controller: _fullNameController,
                  prefixIcon: const Icon(Icons.person),
                  validator: (value) => Validators.validateRequired(value, 'Full name'),
                ),
                const SizedBox(height: 16),
                // Specialization
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Specialization *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSpecialization,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: AppConstants.specializations.map((spec) {
                        return DropdownMenuItem(
                          value: spec,
                          child: Text(spec),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecialization = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Years of Experience
                CustomTextField(
                  label: 'Years of Experience *',
                  hint: 'Enter years of experience',
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.work),
                  validator: Validators.validateExperience,
                ),
                const SizedBox(height: 16),
                // DCI Registration Number
                CustomTextField(
                  label: 'DCI Registration Number *',
                  hint: 'Enter DCI registration number',
                  controller: _dciRegController,
                  prefixIcon: const Icon(Icons.badge),
                  validator: (value) => Validators.validateRequired(value, 'DCI registration number'),
                ),
                const SizedBox(height: 16),
                // DCI Certificate
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DCI Certificate *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickCertificate,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _dciCertificate != null
                            ? 'Certificate Selected'
                            : 'Upload DCI Certificate',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dciCertificate != null
                            ? AppConstants.secondaryColor
                            : Colors.grey[300],
                        foregroundColor: _dciCertificate != null
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // BDS Qualification
                CustomTextField(
                  label: 'BDS Qualification *',
                  hint: 'Enter BDS qualification',
                  controller: _bdsController,
                  prefixIcon: const Icon(Icons.school),
                  validator: (value) => Validators.validateRequired(value, 'BDS qualification'),
                ),
                const SizedBox(height: 16),
                // MDS Qualification
                CustomTextField(
                  label: 'MDS Qualification (Optional)',
                  hint: 'Enter MDS qualification',
                  controller: _mdsController,
                  prefixIcon: const Icon(Icons.school),
                ),
                const SizedBox(height: 16),
                // Additional Qualifications
                CustomTextField(
                  label: 'Additional Qualifications (Optional)',
                  hint: 'Enter additional qualifications',
                  controller: _additionalQualController,
                  prefixIcon: const Icon(Icons.school),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Consultation Fee Offline
                CustomTextField(
                  label: 'Consultation Fee (Offline) *',
                  hint: 'Enter offline consultation fee',
                  controller: _feeOfflineController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.currency_rupee),
                  validator: Validators.validateFee,
                ),
                const SizedBox(height: 16),
                // Consultation Fee Online
                CustomTextField(
                  label: 'Consultation Fee (Online) (Optional)',
                  hint: 'Enter online consultation fee',
                  controller: _feeOnlineController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                const SizedBox(height: 16),
                // Booking Limit
                CustomTextField(
                  label: 'Daily Booking Limit *',
                  hint: 'Enter daily booking limit',
                  controller: _bookingLimitController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.event_available),
                  validator: (value) => Validators.validateNumber(value, 'Booking limit'),
                ),
                const SizedBox(height: 16),
                // Mobile Number
                CustomTextField(
                  label: 'Mobile Number *',
                  hint: 'Enter mobile number',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone),
                  validator: Validators.validateMobile,
                  maxLength: 15,
                ),
                const SizedBox(height: 16),
                // Email
                CustomTextField(
                  label: 'Email (Optional)',
                  hint: 'Enter email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                // Password
                CustomTextField(
                  label: 'Password *',
                  hint: 'Enter password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 24),
                // Register Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      text: 'Register',
                      onPressed: _handleRegister,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
