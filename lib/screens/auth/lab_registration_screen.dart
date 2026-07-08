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

class LabRegistrationScreen extends StatefulWidget {
  const LabRegistrationScreen({super.key});

  @override
  State<LabRegistrationScreen> createState() => _LabRegistrationScreenState();
}

class _LabRegistrationScreenState extends State<LabRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _labNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _licenseController = TextEditingController();
  final _deliveryChargesController = TextEditingController();

  String _selectedLabType = AppConstants.labTypes[0];
  bool _pickupAvailable = true;
  bool _deliveryAvailable = true;
  bool _freeDelivery = false;
  bool _obscurePassword = true;
  File? _labImage;
  File? _registrationCertificate;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _labNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _licenseController.dispose();
    _deliveryChargesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _labImage = File(pickedFile.path);
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
        _registrationCertificate = File(result.files.single.path!);
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
      AppConstants.roleLab,
      _emailController.text.trim(), // Email is now required
    );

    if (!mounted) return;

    if (!userSuccess) {
      Helpers.showToast(
        authProvider.error ?? 'Registration failed',
        isError: true,
      );
      return;
    }

    // Step 2: Register lab profile
    final data = {
      'mobile_number': _mobileController.text.trim(),
      'lab_name': _labNameController.text.trim(),
      'lab_type': _selectedLabType,
      'owner_name': _ownerNameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'license_number': _licenseController.text.trim(),
      'pickup_available': _pickupAvailable.toString(),
      'delivery_available': _deliveryAvailable.toString(),
      'delivery_charges': _deliveryChargesController.text.trim(),
      'free_delivery': _freeDelivery.toString(),
    };

    final profileSuccess = await authProvider.registerLab(
      data,
      _registrationCertificate,
      _labImage,
    );

    if (!mounted) return;

    if (profileSuccess) {
      Helpers.showToast('Registration successful! OTP sent to your email.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            mobileNumber: _mobileController.text.trim(),
            email: _emailController.text.trim(),
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
        title: const Text('Lab Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lab Image
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        image: _labImage != null
                            ? DecorationImage(
                          image: FileImage(_labImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _labImage == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to add lab photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                // Lab Name
                CustomTextField(
                  label: 'Lab Name *',
                  hint: 'Enter lab name',
                  controller: _labNameController,
                  prefixIcon: const Icon(Icons.business),
                  validator: (value) => Validators.validateRequired(value, 'Lab name'),
                ),
                const SizedBox(height: 16),
                // Lab Type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lab Type *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLabType,
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
                      items: AppConstants.labTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLabType = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Owner Name
                CustomTextField(
                  label: 'Owner Name *',
                  hint: 'Enter owner name',
                  controller: _ownerNameController,
                  prefixIcon: const Icon(Icons.person),
                  validator: (value) => Validators.validateRequired(value, 'Owner name'),
                ),
                const SizedBox(height: 16),
                // License Number
                CustomTextField(
                  label: 'License Number *',
                  hint: 'Enter license number',
                  controller: _licenseController,
                  prefixIcon: const Icon(Icons.badge),
                  validator: (value) => Validators.validateRequired(value, 'License number'),
                ),
                const SizedBox(height: 16),
                // Registration Certificate
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registration Certificate *',
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
                        _registrationCertificate != null
                            ? 'Certificate Selected'
                            : 'Upload Certificate',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _registrationCertificate != null
                            ? AppConstants.secondaryColor
                            : Colors.grey[300],
                        foregroundColor: _registrationCertificate != null
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Address
                CustomTextField(
                  label: 'Lab Address *',
                  hint: 'Enter complete address',
                  controller: _addressController,
                  prefixIcon: const Icon(Icons.location_on),
                  maxLines: 2,
                  validator: (value) => Validators.validateRequired(value, 'Address'),
                ),
                const SizedBox(height: 16),
                // City
                CustomTextField(
                  label: 'City *',
                  hint: 'Enter city',
                  controller: _cityController,
                  prefixIcon: const Icon(Icons.location_city),
                  validator: (value) => Validators.validateRequired(value, 'City'),
                ),
                const SizedBox(height: 16),
                // State
                CustomTextField(
                  label: 'State *',
                  hint: 'Enter state',
                  controller: _stateController,
                  prefixIcon: const Icon(Icons.map),
                  validator: (value) => Validators.validateRequired(value, 'State'),
                ),
                const SizedBox(height: 16),
                // Pincode
                CustomTextField(
                  label: 'Pincode *',
                  hint: 'Enter pincode',
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.pin_drop),
                  validator: (value) => Validators.validateRequired(value, 'Pincode'),
                  maxLength: 6,
                ),
                const SizedBox(height: 16),
                // Service Options
                CheckboxListTile(
                  title: const Text('Pickup Available'),
                  value: _pickupAvailable,
                  onChanged: (value) {
                    setState(() {
                      _pickupAvailable = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('Delivery Available'),
                  value: _deliveryAvailable,
                  onChanged: (value) {
                    setState(() {
                      _deliveryAvailable = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_deliveryAvailable) ...[
                  CheckboxListTile(
                    title: const Text('Free Delivery'),
                    value: _freeDelivery,
                    onChanged: (value) {
                      setState(() {
                        _freeDelivery = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (!_freeDelivery)
                    CustomTextField(
                      label: 'Delivery Charges *',
                      hint: 'Enter delivery charges',
                      controller: _deliveryChargesController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.currency_rupee),
                      validator: Validators.validateFee,
                    ),
                ],
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
                // Email — now required
                CustomTextField(
                  label: 'Email *',
                  hint: 'Enter email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email),
                  validator: Validators.validateEmailRequired,
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
