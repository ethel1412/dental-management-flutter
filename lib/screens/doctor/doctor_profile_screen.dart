import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _specializationCtrl;
  late TextEditingController _yearsCtrl;
  late TextEditingController _feeOfflineCtrl;
  late TextEditingController _feeOnlineCtrl;
  late TextEditingController _bookingLimitCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _specializationCtrl = TextEditingController();
    _yearsCtrl = TextEditingController();
    _feeOfflineCtrl = TextEditingController();
    _feeOnlineCtrl = TextEditingController();
    _bookingLimitCtrl = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specializationCtrl.dispose();
    _yearsCtrl.dispose();
    _feeOfflineCtrl.dispose();
    _feeOnlineCtrl.dispose();
    _bookingLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.doctorProfile}');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profile = data;
          _nameCtrl.text = data['full_name'] ?? '';
          _specializationCtrl.text = data['specialization'] ?? '';
          _yearsCtrl.text = (data['years_of_experience'] ?? '').toString();
          _feeOfflineCtrl.text =
              (data['consultation_fee_offline'] ?? '').toString();
          _feeOnlineCtrl.text =
              (data['consultation_fee_online'] ?? '').toString();
          _bookingLimitCtrl.text =
              (data['booking_limit_per_day'] ?? '').toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.doctorProfile}');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': _nameCtrl.text.trim(),
          'specialization': _specializationCtrl.text.trim(),
          'years_of_experience': int.tryParse(_yearsCtrl.text.trim()) ?? 0,
          'consultation_fee_offline':
              double.tryParse(_feeOfflineCtrl.text.trim()) ?? 0,
          'consultation_fee_online':
              double.tryParse(_feeOnlineCtrl.text.trim()),
          'booking_limit_per_day':
              int.tryParse(_bookingLimitCtrl.text.trim()) ?? 10,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(response.body);
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _fetchProfile,
                          child: const Text('Retry')),
                    ],
                  ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar card
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: AppConstants.primaryColor
                                    .withOpacity(0.1),
                                child: Text(
                                  (_profile?['full_name'] ?? 'D')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _profile?['full_name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _profile?['specialization'] ?? '',
                                style: TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _profile?['is_verified'] == true
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _profile?['is_verified'] == true
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                child: Text(
                                  _profile?['is_verified'] == true
                                      ? 'Verified'
                                      : 'Pending Verification',
                                  style: TextStyle(
                                    color: _profile?['is_verified'] == true
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_isEditing) ...[
                        // View mode
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Professional Details',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const Divider(height: 20),
                                _infoRow(
                                    'Doctor ID',
                                    _profile?['doctor_id'] ?? '-',
                                    Icons.badge),
                                _infoRow(
                                    'DCI Registration',
                                    _profile?['dci_registration_number'] ?? '-',
                                    Icons.verified),
                                _infoRow(
                                    'Qualification',
                                    _profile?['qualification_bds'] ?? '-',
                                    Icons.school),
                                _infoRow(
                                    'Experience',
                                    '${_profile?['years_of_experience'] ?? 0} years',
                                    Icons.work),
                                _infoRow(
                                    'Offline Fee',
                                    '₹${_profile?['consultation_fee_offline'] ?? 0}',
                                    Icons.currency_rupee),
                                _infoRow(
                                    'Daily Booking Limit',
                                    '${_profile?['booking_limit_per_day'] ?? 0} patients',
                                    Icons.people),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Edit mode
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Edit Profile',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    validator: (v) => v!.isEmpty
                                        ? 'Name is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    value: AppConstants.specializations
                                            .contains(
                                                _specializationCtrl.text)
                                        ? _specializationCtrl.text
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Specialization',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.local_hospital),
                                    ),
                                    items: AppConstants.specializations
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (v) =>
                                        _specializationCtrl.text = v!,
                                    validator: (v) => v == null
                                        ? 'Select specialization'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _yearsCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Years of Experience',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.work),
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _feeOfflineCtrl,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Consultation Fee (Offline) ₹',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.currency_rupee),
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _feeOnlineCtrl,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Consultation Fee (Online) ₹ (optional)',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.currency_rupee),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _bookingLimitCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Daily Booking Limit',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.people),
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isSaving ? null : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppConstants.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Save Changes',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
