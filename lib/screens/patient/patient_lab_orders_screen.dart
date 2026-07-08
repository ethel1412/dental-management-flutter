import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class PatientLabOrdersScreen extends StatefulWidget {
  const PatientLabOrdersScreen({super.key});

  @override
  State<PatientLabOrdersScreen> createState() =>
      _PatientLabOrdersScreenState();
}

class _PatientLabOrdersScreenState extends State<PatientLabOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  static const _timeout = Duration(seconds: 30);

  static const _tabs = [
    {'label': 'All', 'status': null},
    {'label': 'Pending', 'status': 'pending'},
    {'label': 'In Progress', 'status': 'in_progress'},
    {'label': 'Completed', 'status': 'completed'},
    {'label': 'Cancelled', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);

      // Try patient-scoped endpoint first, fallback to base endpoint
      http.Response response;
      try {
        response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.labOrders}/my-orders'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(_timeout);
      } on TimeoutException {
        setState(() {
          _error = 'Request timed out. Server may be starting up — please retry.';
          _isLoading = false;
        });
        return;
      }

      // If /my-orders doesn't exist, fall back to base endpoint
      if (response.statusCode == 404 || response.statusCode == 405) {
        try {
          response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.labOrders}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ).timeout(_timeout);
        } on TimeoutException {
          setState(() {
            _error = 'Request timed out. Server may be starting up — please retry.';
            _isLoading = false;
          });
          return;
        }
      }

      if (response.statusCode == 200) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          setState(() {
            _error = 'Unexpected server response. Please try again.';
            _isLoading = false;
          });
          return;
        }
        setState(() {
          _orders = data is List
              ? data
              : (data['orders'] ?? data['lab_orders'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load lab orders (${response.statusCode})';
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

  List<dynamic> _filtered(String? status) {
    if (status == null) return _orders;
    return _orders.where((o) => o['status'] == status).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'in_progress': return AppConstants.primaryColor;
      case 'completed': return AppConstants.secondaryColor;
      case 'cancelled': return AppConstants.errorColor;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress': return 'In Progress';
      default: return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('My Lab Orders'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _tabs.map((t) => Tab(text: t['label']!)).toList(),
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
                    final list = _filtered(t['status']);
                    return _buildList(list);
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
            Text('Could not load lab orders',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchOrders,
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

  Widget _buildList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No lab orders found',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Your lab orders will appear here',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _LabOrderCard(
          order: list[i],
          statusColor: _statusColor,
          statusLabel: _statusLabel,
        ),
      ),
    );
  }
}

// ─── Lab Order Card ─────────────────────────────────────────────────────

class _LabOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;

  const _LabOrderCard({
    required this.order,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  State<_LabOrderCard> createState() => _LabOrderCardState();
}

class _LabOrderCardState extends State<_LabOrderCard> {
  bool _expanded = false;

  Map<String, dynamic> get o => widget.order;
  String get status => o['status'] ?? 'pending';

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.statusColor(status);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.biotech_rounded,
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o['order_id'] ??
                              o['id']?.toString() ??
                              'Lab Order',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          o['test_name'] ??
                              o['order_type'] ??
                              'Lab Test',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      widget.statusLabel(status).toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetails(),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: Colors.grey.shade200))),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(Icons.person_outline, 'Doctor',
              o['doctor']?['full_name'] ?? o['doctor_name'] ?? '—'),
          _row(Icons.science_outlined, 'Lab',
              o['lab']?['name'] ?? o['lab_name'] ?? '—'),
          _row(Icons.calendar_today_outlined, 'Order Date',
              _formatDate(o['created_at'] ?? o['order_date'])),
          if (o['due_date'] != null)
            _row(Icons.event_outlined, 'Due Date',
                _formatDate(o['due_date'])),
          if (o['amount'] != null || o['total_amount'] != null)
            _row(Icons.currency_rupee, 'Amount',
                '₹${(o['amount'] ?? o['total_amount']).toString()}'),
          if (o['notes'] != null &&
              o['notes'].toString().isNotEmpty)
            _row(Icons.notes_outlined, 'Notes',
                o['notes'].toString()),
          if (o['result'] != null &&
              o['result'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16,
                          color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text('Result',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(o['result'].toString(),
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.textPrimaryColor,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
