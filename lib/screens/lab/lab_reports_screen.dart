import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class LabReportsScreen extends StatefulWidget {
  const LabReportsScreen({super.key});

  @override
  State<LabReportsScreen> createState() => _LabReportsScreenState();
}

class _LabReportsScreenState extends State<LabReportsScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  // Computed stats
  int _total = 0;
  int _pending = 0;
  int _inProgress = 0;
  int _completed = 0;
  int _cancelled = 0;
  double _totalRevenue = 0;
  double _completedRevenue = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.labOrders}?per_page=500'),
        headers: {
          'Authorization': 'Bearer \$token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = data is List ? data : (data['orders'] ?? data['lab_orders'] ?? []);
        _computeStats(orders);
        setState(() { _orders = orders; _isLoading = false; });
      } else {
        setState(() { _error = 'Failed to load reports'; _isLoading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Network error.'; _isLoading = false; });
    }
  }

  void _computeStats(List<dynamic> orders) {
    _total = orders.length;
    _pending = 0; _inProgress = 0; _completed = 0; _cancelled = 0;
    _totalRevenue = 0; _completedRevenue = 0;
    for (final o in orders) {
      final status = o['status'] ?? '';
      final amount = double.tryParse(
              (o['amount'] ?? o['total_amount'] ?? 0).toString()) ?? 0;
      _totalRevenue += amount;
      switch (status) {
        case 'pending': _pending++; break;
        case 'in_progress': _inProgress++; break;
        case 'completed':
          _completed++;
          _completedRevenue += amount;
          break;
        case 'cancelled': _cancelled++; break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: AppConstants.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
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
            Text('Could not load reports',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchData,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Orders',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('\$_total',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Earned (completed)',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        '₹\${_completedRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('Pipeline (all orders)',
                          style: TextStyle(color: Colors.white60, fontSize: 11)),
                      Text(
                        '₹\${_totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          _sectionTitle('Order Breakdown', Icons.pie_chart_outline),
          const SizedBox(height: 12),

          // Status breakdown grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statCard('Pending', _pending, _total, Colors.orange,
                  Icons.pending_actions),
              _statCard('In Progress', _inProgress, _total,
                  AppConstants.accentColor, Icons.autorenew),
              _statCard('Completed', _completed, _total, Colors.green,
                  Icons.check_circle_outline),
              _statCard('Cancelled', _cancelled, _total, Colors.red,
                  Icons.cancel_outlined),
            ],
          ),

          const SizedBox(height: 20),
          _sectionTitle('Recent Orders', Icons.history),
          const SizedBox(height: 12),

          // Last 10 orders table
          if (_orders.isEmpty)
            Center(
              child: Text('No orders yet.',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  // Table header
                  Container(
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor.withOpacity(0.08),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 3,
                            child: Text('Order / Test',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.grey.shade700))),
                        Expanded(flex: 2,
                            child: Text('Status',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.grey.shade700))),
                        Expanded(flex: 2,
                            child: Text('Amount',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.grey.shade700))),
                      ],
                    ),
                  ),
                  // Rows (last 10)
                  ...(_orders.reversed.take(10).toList().asMap().entries.map((e) {
                    final i = e.key;
                    final o = e.value as Map<String, dynamic>;
                    final status = o['status'] ?? 'pending';
                    final amount = o['amount'] ?? o['total_amount'];
                    Color sColor;
                    switch (status) {
                      case 'pending': sColor = Colors.orange; break;
                      case 'in_progress': sColor = AppConstants.accentColor; break;
                      case 'completed': sColor = Colors.green; break;
                      default: sColor = Colors.red;
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.transparent
                            : Colors.grey.shade50,
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade100)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              o['test_name'] ?? o['order_type'] ??
                                  o['order_id']?.toString() ?? '—',
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: sColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status == 'in_progress' ? 'In Prog.' :
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                    color: sColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              amount != null ? '₹\${amount.toString()}' : '—',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
          const SizedBox(height: 24),
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

  Widget _statCard(String label, int count, int total, Color color, IconData icon) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('\$count',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
                Text('\$pct%',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
