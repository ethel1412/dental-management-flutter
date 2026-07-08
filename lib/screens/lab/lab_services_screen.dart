import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class LabServicesScreen extends StatefulWidget {
  const LabServicesScreen({super.key});

  @override
  State<LabServicesScreen> createState() => _LabServicesScreenState();
}

class _LabServicesScreenState extends State<LabServicesScreen> {
  Map<String, dynamic>? _profile;
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
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.labProfile}'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profile = data is Map ? data['lab'] ?? data : null;
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed to load services'; _isLoading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Network error.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Lab Services'),
        backgroundColor: AppConstants.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchProfile),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
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
            Text('Could not load services',
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
                backgroundColor: AppConstants.accentColor,
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
            Icon(Icons.settings_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No service info found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Update your lab profile to list your services.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    // Extract services list — could be array or comma-separated string
    final rawServices = p['services'] ?? p['test_types'] ?? p['service_types'] ?? [];
    List<String> services = [];
    if (rawServices is List) {
      services = rawServices.map((s) => s.toString()).toList();
    } else if (rawServices is String && rawServices.isNotEmpty) {
      services = rawServices.split(',').map((s) => s.trim()).toList();
    }

    final labName = p['lab_name'] ?? p['name'] ?? 'My Lab';
    final labType = p['lab_type'] ?? p['type'] ?? '';
    final city = p['city'] ?? '';
    final turnaround = p['turnaround_time'] ?? p['tat'] ?? '';
    final homeCollection = p['home_collection'] ?? p['home_sample_collection'];
    final onlineReports = p['online_reports'] ?? p['digital_reports'];
    final pickupAvailable = p['pickup_available'] ?? p['sample_pickup'];
    final accreditation = p['accreditation'] ?? p['certifications'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lab header card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [AppConstants.accentColor, AppConstants.accentColor.withGreen(120)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.biotech, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(labName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        if (labType.isNotEmpty)
                          Text(labType,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        if (city.isNotEmpty)
                          Text(city,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Feature badges
          _sectionTitle('Capabilities', Icons.verified_outlined),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (homeCollection == true || homeCollection == 1 ||
                  homeCollection?.toString() == 'true')
                _badge('Home Collection', Icons.home_outlined, Colors.green),
              if (onlineReports == true || onlineReports == 1 ||
                  onlineReports?.toString() == 'true')
                _badge('Online Reports', Icons.picture_as_pdf_outlined, Colors.blue),
              if (pickupAvailable == true || pickupAvailable == 1 ||
                  pickupAvailable?.toString() == 'true')
                _badge('Sample Pickup', Icons.local_shipping_outlined,
                    Colors.orange),
              if (turnaround.isNotEmpty)
                _badge('TAT: \$turnaround', Icons.timer_outlined, Colors.purple),
              if (accreditation.isNotEmpty)
                _badge(accreditation.toString(), Icons.workspace_premium_outlined,
                    AppConstants.accentColor),
            ],
          ),

          const SizedBox(height: 20),

          // Services list
          _sectionTitle('Services Offered', Icons.science_outlined),
          const SizedBox(height: 10),

          services.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.list_alt_outlined,
                          size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text('No services listed yet.',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Update your lab profile to add the tests and services you offer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                )
              : Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: services.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      return Container(
                        decoration: BoxDecoration(
                          color: i.isEven ? Colors.transparent : Colors.grey.shade50,
                          border: i == 0
                              ? null
                              : Border(
                                  top: BorderSide(color: Colors.grey.shade100)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppConstants.accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text('\${i + 1}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.accentColor)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppConstants.textPrimaryColor)),
                            ),
                            Icon(Icons.check_circle,
                                size: 16,
                                color: Colors.green.shade400),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.accentColor.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppConstants.accentColor, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'To update your services and capabilities, go to My Profile and edit your lab information.',
                    style: TextStyle(fontSize: 13, color: AppConstants.accentColor),
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
        Icon(icon, size: 18, color: AppConstants.accentColor),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppConstants.accentColor)),
      ],
    );
  }

  Widget _badge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
