import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends StatefulWidget
    with SingleTickerProviderStateMixin {
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments({bool upcoming = false}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.myAppointments}?upcoming=$upcoming&per_page=50',
      );
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        setState(() {
          _appointments = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load appointments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _updateStatus(String appointmentId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.appointments}/$appointmentId');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment $status'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchAppointments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> _filtered(String status) {
    if (status == 'all') return _appointments;
    return _appointments
        .where((a) => a['status'] == status)
        .toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled': return Colors.blue;
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.grey;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
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
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppointments,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (i) {
            final filters = ['all', 'scheduled', 'completed'];
            setState(() => _selectedFilter = filters[i]);
          },
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
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
                      Text(_error!,
                          style: TextStyle(color: Colors.red[400])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAppointments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAppointments,
                  child: Builder(
                    builder: (context) {
                      final list = _filtered(_selectedFilter);
                      if (list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 64,
                                  color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No appointments found',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final appt = list[i];
                          final status = appt['status'] ?? 'scheduled';
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        appt['appointment_id'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppConstants
                                              .primaryColor,
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color:
                                                  _statusColor(status)),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person,
                                          size: 16,
                                          color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        appt['patient']?['full_name'] ??
                                            'Patient',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month,
                                          size: 16,
                                          color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                          appt['appointment_date'] ??
                                              '',
                                          style: TextStyle(
                                              color: Colors.grey[700])),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.access_time,
                                          size: 16,
                                          color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                          appt['appointment_time'] ??
                                              '',
                                          style: TextStyle(
                                              color: Colors.grey[700])),
                                    ],
                                  ),
                                  if (appt['reason'] != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.medical_information,
                                            size: 16,
                                            color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            appt['reason'],
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13),
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (status == 'scheduled') ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                _updateStatus(
                                                    appt[
                                                        'appointment_id'],
                                                    'confirmed'),
                                            style:
                                                OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.green,
                                              side: const BorderSide(
                                                  color: Colors.green),
                                            ),
                                            child: const Text('Confirm'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                _updateStatus(
                                                    appt[
                                                        'appointment_id'],
                                                    'cancelled'),
                                            style:
                                                OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(
                                                  color: Colors.red),
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (status == 'confirmed') ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _updateStatus(
                                            appt['appointment_id'],
                                            'completed'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child:
                                            const Text('Mark Completed'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
