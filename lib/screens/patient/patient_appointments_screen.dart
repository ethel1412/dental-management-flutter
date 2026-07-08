import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';
import 'search_doctors_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState
    extends State<PatientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String? _error;

  static const _tabs = [
    {'label': 'All', 'status': 'all'},
    {'label': 'Upcoming', 'status': 'scheduled'},
    {'label': 'Confirmed', 'status': 'confirmed'},
    {'label': 'Completed', 'status': 'completed'},
    {'label': 'Cancelled', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.myAppointments}?per_page=100'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _appointments =
              data is List ? data : (data['appointments'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load appointments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content:
            const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final response = await http.put(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.appointments}/$appointmentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'cancelled'}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment cancelled'),
            backgroundColor: AppConstants.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        _fetchAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel appointment'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<dynamic> _filtered(String status) {
    if (status == 'all') return _appointments;
    return _appointments.where((a) => a['status'] == status).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Book New',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchDoctorsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppointments,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.primaryColor),
              ),
            )
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((t) {
                    final list = _filtered(t['status']!);
                    return _buildList(list, t['status']!);
                  }).toList(),
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
            Icon(Icons.wifi_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Could not load appointments',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> list, String statusKey) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              statusKey == 'all'
                  ? 'No appointments yet'
                  : 'No $statusKey appointments',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 16),
            ),
            if (statusKey == 'all') ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SearchDoctorsScreen()),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Find a Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _AppointmentCard(
          appointment: list[i],
          statusColor: _statusColor,
          onCancel: _cancelAppointment,
        ),
      ),
    );
  }
}

// ─── Appointment Card ───────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Color Function(String) statusColor;
  final Future<void> Function(String id) onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.statusColor,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final appt = appointment;
    final status = appt['status'] ?? 'scheduled';
    final color = statusColor(status);
    final doctor = appt['doctor'] as Map<String, dynamic>?;
    final doctorName = doctor?['full_name'] ?? 'Doctor';
    final specialization =
        doctor?['specialization'] ?? appt['specialization'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      AppConstants.primaryColor.withOpacity(0.12),
                  child: Text(
                    doctorName.isNotEmpty
                        ? doctorName[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. $doctorName',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      if (specialization.isNotEmpty)
                        Text(specialization,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppConstants.primaryColor)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Date + Time
            Row(
              children: [
                _chip(Icons.calendar_month,
                    appt['appointment_date'] ?? '—'),
                const SizedBox(width: 12),
                _chip(Icons.access_time,
                    appt['appointment_time'] ?? '—'),
                if (appt['appointment_type'] != null) ...[
                  const SizedBox(width: 12),
                  _chip(
                    appt['appointment_type'] == 'online'
                        ? Icons.videocam
                        : Icons.local_hospital,
                    appt['appointment_type'].toString().toUpperCase(),
                  ),
                ],
              ],
            ),
            if (appt['reason'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.note_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appt['reason'],
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Cancel button for upcoming/scheduled appointments
            if (status == 'scheduled' || status == 'confirmed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      onCancel(appt['appointment_id'] ?? ''),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel Appointment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
