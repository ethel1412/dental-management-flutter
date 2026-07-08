import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class ClinicalProfileScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const ClinicalProfileScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  State<ClinicalProfileScreen> createState() =>
      _ClinicalProfileScreenState();
}

class _ClinicalProfileScreenState extends State<ClinicalProfileScreen> {
  List<dynamic> _profiles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.clinicalProfiles}/patient/${widget.patientId}',
      );
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        setState(() {
          _profiles = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load clinical profiles';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showCreateDialog() {
    final primaryCtrl = TextEditingController();
    final diagnosisCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    final bpCtrl = TextEditingController();
    final pulseCtrl = TextEditingController();
    DateTime visitDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Clinical Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient: ${widget.patientName}',
                  style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              TextField(
                controller: primaryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Primary Complaint *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: diagnosisCtrl,
                decoration: const InputDecoration(
                  labelText: 'Provisional Diagnosis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: treatmentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Treatment Plan (Phase 1)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bpCtrl,
                      decoration: const InputDecoration(
                        labelText: 'BP',
                        border: OutlineInputBorder(),
                        hintText: '120/80',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pulseCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pulse',
                        border: OutlineInputBorder(),
                        hintText: '72',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (primaryCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Primary complaint is required')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _createProfile(
                primaryComplaint: primaryCtrl.text.trim(),
                provisionalDiagnosis: diagnosisCtrl.text.trim(),
                treatmentPhase1: treatmentCtrl.text.trim(),
                bp: bpCtrl.text.trim(),
                pulse: int.tryParse(pulseCtrl.text.trim()),
                visitDate: visitDate.toIso8601String().substring(0, 10),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createProfile({
    required String primaryComplaint,
    String? provisionalDiagnosis,
    String? treatmentPhase1,
    String? bp,
    int? pulse,
    required String visitDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.clinicalProfiles}/');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'patient_id': int.tryParse(widget.patientId) ?? widget.patientId,
          'primary_complaint': primaryComplaint,
          'provisional_diagnosis': provisionalDiagnosis,
          'treatment_phase_1': treatmentPhase1,
          'bp': bp,
          'pulse': pulse,
          'visit_date': visitDate,
          'consent_obtained': true,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinical profile created'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProfiles();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err['detail'] ?? 'Failed to create profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: Text('${widget.patientName} — Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProfiles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Record',
            style: TextStyle(color: Colors.white)),
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
                          onPressed: _fetchProfiles,
                          child: const Text('Retry')),
                    ],
                  ))
              : _profiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No clinical records yet',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create the first record',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchProfiles,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _profiles.length,
                        itemBuilder: (_, i) {
                          final p = _profiles[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: AppConstants.primaryColor
                                    .withOpacity(0.1),
                                child: Icon(
                                  Icons.medical_services,
                                  color: AppConstants.primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                p['profile_id']?.toString() ?? 'Record',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                p['visit_date'] ?? '',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (p['primary_complaint'] !=
                                          null) ...[
                                        _detailRow(
                                            'Primary Complaint',
                                            p['primary_complaint']),
                                        const SizedBox(height: 6),
                                      ],
                                      if (p['provisional_diagnosis'] !=
                                          null) ...[
                                        _detailRow('Provisional Diagnosis',
                                            p['provisional_diagnosis']),
                                        const SizedBox(height: 6),
                                      ],
                                      if (p['treatment_phase_1'] !=
                                          null) ...[
                                        _detailRow('Treatment Phase 1',
                                            p['treatment_phase_1']),
                                        const SizedBox(height: 6),
                                      ],
                                      if (p['bp'] != null)
                                        _detailRow('BP', p['bp']),
                                      if (p['pulse'] != null)
                                        _detailRow(
                                            'Pulse',
                                            '${p['pulse']} bpm'),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
