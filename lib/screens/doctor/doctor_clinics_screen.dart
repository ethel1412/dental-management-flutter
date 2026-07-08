import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class DoctorClinicsScreen extends StatefulWidget {
  const DoctorClinicsScreen({super.key});

  @override
  State<DoctorClinicsScreen> createState() => _DoctorClinicsScreenState();
}

class _DoctorClinicsScreenState extends State<DoctorClinicsScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _clinics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.doctorProfile}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = data['doctor'] ?? data['profile'] ?? data;
        setState(() {
          _profile = profile as Map<String, dynamic>?;
          _clinics = profile['clinics'] ?? profile['clinic_addresses'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed to load clinic info'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error. Please check your connection.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('My Clinics'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchProfile),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchProfile,
                  color: AppConstants.primaryColor,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Doctor summary card
                      if (_profile != null) _buildDoctorSummary(),
                      const SizedBox(height: 16),
                      // Section header
                      Row(
                        children: [
                          const Icon(Icons.business, size: 18, color: AppConstants.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Clinic Locations (${_clinics.length})',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppConstants.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_clinics.isEmpty)
                        _buildNoClinics()
                      else
                        ...List.generate(_clinics.length, (i) => _ClinicCard(clinic: _clinics[i], index: i)),
                      const SizedBox(height: 20),
                      // Availability info
                      if (_profile != null) _buildAvailability(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDoctorSummary() {
    final p = _profile!;
    final name = p['full_name'] ?? p['name'] ?? 'Doctor';
    final spec = p['specialization'] ?? '';
    final exp = p['experience_years']?.toString() ?? '';
    final qual = p['qualifications'] ?? p['qualification'] ?? '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppConstants.primaryColor, AppConstants.primaryColor.withBlue(160)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (spec.isNotEmpty) Text(spec, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (exp.isNotEmpty) _chip('$exp yrs exp'),
                      if (qual.isNotEmpty) ...[const SizedBox(width: 6), _chip(qual.toString())],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildAvailability() {
    final p = _profile!;
    final days = p['available_days'] ?? p['working_days'] ?? [];
    final start = p['available_time_start'] ?? p['start_time'] ?? '';
    final end = p['available_time_end'] ?? p['end_time'] ?? '';
    final offlineFee = p['offline_consultation_fee']?.toString() ?? p['consultation_fee']?.toString() ?? '';
    final onlineFee = p['online_consultation_fee']?.toString() ?? '';
    final isOnline = p['online_consultation_available'] ?? p['is_online'] ?? false;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 17, color: AppConstants.primaryColor),
                const SizedBox(width: 8),
                const Text('Availability', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConstants.primaryColor)),
              ],
            ),
            const SizedBox(height: 12),
            if (days is List && (days as List).isNotEmpty)
              _avRow(Icons.calendar_today_outlined, 'Working Days', (days as List).join(', ')),
            if (start.isNotEmpty || end.isNotEmpty)
              _avRow(Icons.access_time_outlined, 'Hours', '$start – $end'),
            if (offlineFee.isNotEmpty)
              _avRow(Icons.local_hospital_outlined, 'Offline Fee', '₹$offlineFee'),
            if (isOnline == true && onlineFee.isNotEmpty)
              _avRow(Icons.videocam_outlined, 'Online Fee', '₹$onlineFee'),
            if (isOnline == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 15, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text('Online consultations available', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppConstants.textPrimaryColor, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildNoClinics() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No clinic addresses added', style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Update your profile to add clinic locations.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Could not load clinic info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Clinic Card ─────────────────────────────────────────────────────────────

class _ClinicCard extends StatelessWidget {
  final dynamic clinic;
  final int index;

  const _ClinicCard({required this.clinic, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = clinic is Map ? clinic as Map<String, dynamic> : <String, dynamic>{};
    final name = c['clinic_name'] ?? c['name'] ?? 'Clinic ${index + 1}';
    final address = c['address'] ?? c['full_address'] ?? '';
    final city = c['city'] ?? '';
    final state = c['state'] ?? '';
    final pincode = c['pincode'] ?? c['zip'] ?? '';
    final phone = c['phone'] ?? c['clinic_phone'] ?? '';
    final fullAddress = [address, city, state, pincode].where((s) => s.toString().isNotEmpty).join(', ');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (fullAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(child: Text(fullAddress, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                ],
              ),
            ],
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(phone.toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
