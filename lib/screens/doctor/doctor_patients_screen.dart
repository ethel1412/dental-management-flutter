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
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filtered = [];
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}?per_page=200'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List appts = data is List ? data : (data['appointments'] ?? []);
        // Deduplicate patients by patient_id
        final Map<String, Map<String, dynamic>> seen = {};
        for (final a in appts) {
          final patient = a['patient'] as Map<String, dynamic>?;
          if (patient == null) continue;
          final id = (patient['patient_id'] ?? patient['id'] ?? '').toString();
          if (id.isNotEmpty && !seen.containsKey(id)) {
            seen[id] = {
              ...patient,
              'last_appointment_date': a['appointment_date'],
              'last_appointment_id': a['appointment_id'],
            };
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
    } catch (e) {
      setState(() { _error = 'Network error. Please check your connection.'; _isLoading = false; });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _patients
          : _patients.where((p) {
              final name = (p['full_name'] ?? p['name'] ?? '').toString().toLowerCase();
              final phone = (p['phone'] ?? p['mobile'] ?? '').toString().toLowerCase();
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor)))
                : _error != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _fetchPatients,
                            color: AppConstants.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => _PatientCard(
                                patient: _filtered[i],
                                onViewRecords: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClinicalProfileScreen(
                                      patientId: (_filtered[i]['patient_id'] ?? _filtered[i]['id'] ?? '').toString(),
                                      patientName: (_filtered[i]['full_name'] ?? _filtered[i]['name'] ?? 'Patient').toString(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
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
            _searchCtrl.text.isNotEmpty ? 'No patients match your search' : 'No patients yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'Try a different name or phone number'
                : 'Patients from your appointments will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Patient Card ────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onViewRecords;

  const _PatientCard({required this.patient, required this.onViewRecords});

  @override
  Widget build(BuildContext context) {
    final name = patient['full_name'] ?? patient['name'] ?? 'Patient';
    final phone = patient['phone'] ?? patient['mobile'] ?? '';
    final email = patient['email'] ?? '';
    final gender = patient['gender'] ?? '';
    final age = patient['age']?.toString() ?? patient['date_of_birth'] ?? '';
    final lastAppt = patient['last_appointment_date'] ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppConstants.primaryColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  if (phone.isNotEmpty)
                    _info(Icons.phone_outlined, phone),
                  if (email.isNotEmpty)
                    _info(Icons.email_outlined, email),
                  if (gender.isNotEmpty || age.isNotEmpty)
                    _info(Icons.person_outline, [gender, age].where((s) => s.isNotEmpty).join(' • ')),
                  if (lastAppt.isNotEmpty)
                    _info(Icons.calendar_today_outlined, 'Last visit: $lastAppt'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.medical_information_outlined, color: AppConstants.primaryColor),
              tooltip: 'Clinical Records',
              onPressed: onViewRecords,
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
