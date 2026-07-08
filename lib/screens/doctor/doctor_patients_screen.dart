import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';
import 'clinical_profile_screen.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  List<dynamic> _patients = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      // Get appointments and extract unique patients
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}?per_page=500'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final appts = data is List ? data : (data['appointments'] ?? []);
        // Extract unique patients from appointments
        final Map<String, dynamic> seen = {};
        for (final a in appts) {
          final patient = a['patient'] as Map<String, dynamic>?;
          if (patient != null) {
            final id = patient['patient_id']?.toString() ??
                patient['id']?.toString() ?? '';
            if (id.isNotEmpty && !seen.containsKey(id)) {
              seen[id] = {
                ...patient,
                '_last_visit': a['appointment_date'],
                '_last_reason': a['reason'],
              };
            }
          }
        }
        setState(() {
          _patients = seen.values.toList();
          _filtered = _patients;
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed to load patients'; _isLoading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Network error. Please check your connection.'; _isLoading = false; });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _patients
          : _patients.where((p) {
              final name = (p['full_name'] ?? p['name'] ?? '').toLowerCase();
              final phone = (p['phone'] ?? p['mobile'] ?? '').toLowerCase();
              return name.contains(q) || phone.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPatients),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppConstants.primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or phone…',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () { _searchCtrl.clear(); },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    ),
                  )
                : _error != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ],
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
            Text('Could not load patients',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchPatients,
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isEmpty ? 'No patients yet' : 'No patients match your search',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _searchCtrl.text.isEmpty
                ? 'Patients who book appointments with you will appear here.'
                : 'Try a different name or phone number.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _fetchPatients,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _PatientCard(patient: _filtered[i]),
      ),
    );
  }
}

// ─── Patient Card ─────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _PatientCard({required this.patient});

  String get _name => patient['full_name'] ?? patient['name'] ?? 'Patient';
  String get _phone => patient['phone'] ?? patient['mobile'] ?? '';
  String get _email => patient['email'] ?? '';
  String get _lastVisit => patient['_last_visit'] ?? '';
  String get _patientId =>
      patient['patient_id']?.toString() ?? patient['id']?.toString() ?? '';

  String _initials() {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _name.isNotEmpty ? _name[0].toUpperCase() : 'P';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _patientId.isNotEmpty
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClinicalProfileScreen(
                      patientId: _patientId,
                      patientName: _name,
                    ),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
                child: Text(_initials(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                        fontSize: 16)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (_phone.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(_phone,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    if (_email.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(_email,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    if (_lastVisit.isNotEmpty)
                      Text('Last visit: $_lastVisit',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
