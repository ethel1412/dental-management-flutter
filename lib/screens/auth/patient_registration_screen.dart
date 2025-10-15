import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();

  String _selectedGender = 'male';
  bool _consentGiven = false;
  bool _obscurePassword = true;
  File? _profileImage;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consentGiven) {
      Helpers.showToast('Please give consent to proceed', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // Step 1: Register user account
    final userSuccess = await authProvider.register(
      _mobileController.text.trim(),
      _passwordController.text,
      AppConstants.rolePatient,
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

    // Step 2: Register patient profile
    final data = {
      'mobile_number': _mobileController.text.trim(),
      'full_name': _fullNameController.text.trim(),
      'age': _ageController.text.trim(),
      'gender': _selectedGender,
      'consent_given': _consentGiven.toString(),
    };

    final profileSuccess = await authProvider.registerPatient(
      data,
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
        title: const Text('Patient Registration'),
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
                  hint: 'Enter your full name',
                  controller: _fullNameController,
                  prefixIcon: const Icon(Icons.person),
                  validator: (value) => Validators.validateRequired(value, 'Full name'),
                ),
                const SizedBox(height: 16),
                // Age
                CustomTextField(
                  label: 'Age *',
                  hint: 'Enter your age',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.cake),
                  validator: Validators.validateAge,
                ),
                const SizedBox(height: 16),
                // Gender
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gender *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Male'),
                            value: 'male',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Female'),
                            value: 'female',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
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
                const SizedBox(height: 16),
                // Consent
                CheckboxListTile(
                  title: const Text(
                    'I consent to the collection and use of my medical data',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _consentGiven,
                  onChanged: (value) {
                    setState(() {
                      _consentGiven = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
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
