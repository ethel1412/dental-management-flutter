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
  Map<String, dynamic>? _labProfile;
  List<dynamic> _services = [];
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
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['lab'] ?? data['profile'] ?? data;
        final profile = raw is Map<String, dynamic> ? raw : null;
        setState(() {
          _labProfile = profile;
          _services = profile?['services'] ?? profile?['service_types'] ?? profile?['tests_offered'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed to load services'; _isLoading = false; });
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
        title: const Text('Lab Services'),
        backgroundColor: AppConstants.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchProfile)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchProfile,
                  color: AppConstants.accentColor,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_labProfile != null) _buildLabSummary(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.science_outlined, size: 18, color: AppConstants.accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Services Offered (${_services.length})',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppConstants.accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_services.isEmpty)
                        _buildNoServices()
                      else
                        ..._services.asMap().entries.map((e) => _ServiceCard(service: e.value, index: e.key)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLabSummary() {
    final p = _labProfile!;
    final name = p['lab_name'] ?? p['name'] ?? 'Lab';
    final city = p['city'] ?? '';
    final state = p['state'] ?? '';
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');
    final isActive = p['is_active'] ?? p['active'] ?? true;

    return Card(
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
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'L',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (location.isNotEmpty)
                    Text(location, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive == true ? 'Active' : 'Inactive',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoServices() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.science_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No services listed', style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Update your lab profile to add services and tests offered.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
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
            Text('Could not load services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
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
}

// ─── Service Card ─────────────────────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final dynamic service;
  final int index;

  const _ServiceCard({required this.service, required this.index});

  @override
  Widget build(BuildContext context) {
    if (service is String) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentColor)),
            ),
          ),
          title: Text(service.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      );
    }

    final s = service is Map<String, dynamic> ? service as Map<String, dynamic> : <String, dynamic>{};
    final name = s['service_name'] ?? s['name'] ?? s['test_name'] ?? 'Service ${index + 1}';
    final desc = s['description'] ?? s['desc'] ?? '';
    final price = s['price'] ?? s['cost'] ?? s['fee'] ?? '';
    final duration = s['duration'] ?? s['turnaround_time'] ?? '';
    final available = s['is_available'] ?? s['available'] ?? true;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppConstants.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.science_outlined, color: AppConstants.accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                      if (available == false)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.withOpacity(0.4)),
                          ),
                          child: const Text('Unavailable', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  if (desc.toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(desc.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (price.toString().isNotEmpty) ...[
                        Icon(Icons.currency_rupee, size: 13, color: Colors.grey.shade500),
                        Text('₹$price', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                      ],
                      if (duration.toString().isNotEmpty) ...[
                        Icon(Icons.schedule_outlined, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(duration.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
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
}
