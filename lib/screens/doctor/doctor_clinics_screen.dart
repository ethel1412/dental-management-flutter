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
  bool _isLoading = true;
  String? _error;

  // Edit controllers for clinic hours
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.doctorProfile}'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profile = data is Map ? data['doctor'] ?? data : null;
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed to load clinic info'; _isLoading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Network error.'; _isLoading = false; });
    }
  }

  String _formatTime(String? t) {
    if (t == null || t.isEmpty) return '—';
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? parts[1] : '00';
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '\$hour:\$m \$period';
    } catch (_) {
      return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('My Clinics & Hours'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchProfile),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
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
            Text('Could not load clinic info',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
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

  Widget _buildContent() {
    final p = _profile;
    if (p == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No clinic info found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Complete your profile to add clinic details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    final clinicName = p['clinic_name'] ?? p['hospital_name'] ?? '';
    final clinicAddress = p['clinic_address'] ?? p['address'] ?? '';
    final clinicCity = p['city'] ?? '';
    final clinicState = p['state'] ?? '';
    final clinicPhone = p['clinic_phone'] ?? p['clinic_contact'] ?? '';
    final offlineFee = p['offline_fee'] ?? p['consultation_fee'];
    final onlineFee = p['online_fee'];
    final consultStart = p['consultation_start_time'];
    final consultEnd = p['consultation_end_time'];
    final consultDays = p['consultation_days'];
    final slotDuration = p['slot_duration'];
    final maxPatients = p['max_patients_per_day'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic card
          Card(
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clinicName.isNotEmpty ? clinicName : 'My Clinic',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            if (clinicCity.isNotEmpty || clinicState.isNotEmpty)
                              Text(
                                [clinicCity, clinicState].where((s) => s.isNotEmpty).join(', '),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (clinicAddress.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(clinicAddress,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                  if (clinicPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(clinicPhone,
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Consultation Hours
          _sectionTitle('Consultation Hours', Icons.schedule),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow(Icons.access_time, 'Start Time',
                      _formatTime(consultStart?.toString())),
                  _infoRow(Icons.access_time_filled, 'End Time',
                      _formatTime(consultEnd?.toString())),
                  if (consultDays != null)
                    _infoRow(Icons.calendar_view_week, 'Working Days',
                        consultDays.toString()),
                  if (slotDuration != null)
                    _infoRow(Icons.timer_outlined, 'Slot Duration',
                        '\$slotDuration mins'),
                  if (maxPatients != null)
                    _infoRow(Icons.people_outline, 'Max Patients/Day',
                        maxPatients.toString()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Fees
          _sectionTitle('Consultation Fees', Icons.currency_rupee),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _feeCard(
                  label: 'In-clinic Fee',
                  amount: offlineFee,
                  icon: Icons.local_hospital,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _feeCard(
                  label: 'Online Fee',
                  amount: onlineFee,
                  icon: Icons.videocam,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Info note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: AppConstants.primaryColor, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'To update clinic details, visit My Profile and edit your clinic information.',
                    style: TextStyle(fontSize: 13, color: AppConstants.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _feeCard({
    required String label,
    required dynamic amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              amount != null ? '₹\${amount.toString()}' : '—',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
