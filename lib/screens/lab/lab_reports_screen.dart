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
  int get _total => _orders.length;
  int get _pending => _orders.where((o) => o['status'] == 'pending').length;
  int get _inProgress => _orders.where((o) => o['status'] == 'in_progress').length;
  int get _completed => _orders.where((o) => o['status'] == 'completed').length;
  int get _cancelled => _orders.where((o) => o['status'] == 'cancelled').length;
  double get _revenue => _orders
      .where((o) => o['status'] == 'completed')
      .fold(0.0, (sum, o) => sum + (double.tryParse((o['amount'] ?? o['total_amount'] ?? 0).toString()) ?? 0));

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.labOrders}?per_page=500'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _orders = data is List ? data : (data['orders'] ?? data['lab_orders'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed to load reports'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Network error.'; _isLoading = false; });
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
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  color: AppConstants.accentColor,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryGrid(),
                        const SizedBox(height: 20),
                        _buildRevenueCard(),
                        const SizedBox(height: 20),
                        _buildStatusBreakdown(),
                        const SizedBox(height: 20),
                        _buildRecentCompleted(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _statCard('Total Orders', _total.toString(), Icons.shopping_bag_outlined, Colors.blue),
            _statCard('Pending', _pending.toString(), Icons.pending_outlined, Colors.orange),
            _statCard('In Progress', _inProgress.toString(), Icons.autorenew, AppConstants.accentColor),
            _statCard('Completed', _completed.toString(), Icons.check_circle_outline, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [AppConstants.accentColor, AppConstants.accentColor.withGreen(120)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.currency_rupee, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Revenue', style: TextStyle(fontSize: 13, color: Colors.white70)),
                Text('₹${_revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('from $_completed completed orders', style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    if (_total == 0) return const SizedBox.shrink();
    final statuses = [
      {'label': 'Completed', 'count': _completed, 'color': Colors.green},
      {'label': 'Pending', 'count': _pending, 'color': Colors.orange},
      {'label': 'In Progress', 'count': _inProgress, 'color': AppConstants.accentColor},
      {'label': 'Cancelled', 'count': _cancelled, 'color': Colors.red},
    ];
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ...statuses.map((s) {
              final count = s['count'] as int;
              final pct = _total > 0 ? count / _total : 0.0;
              final color = s['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s['label'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                        Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCompleted() {
    final recent = _orders.where((o) => o['status'] == 'completed').take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Completed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...recent.map((o) {
              final testName = o['test_name'] ?? o['order_type'] ?? 'Lab Test';
              final patientName = o['patient']?['full_name'] ?? o['patient_name'] ?? '';
              final amount = o['amount'] ?? o['total_amount'] ?? '';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.check, color: Colors.green, size: 18),
                ),
                title: Text(testName.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: patientName.isNotEmpty ? Text(patientName.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)) : null,
                trailing: amount.toString().isNotEmpty
                    ? Text('₹${amount.toString()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green))
                    : null,
                dense: true,
              );
            }),
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
            Text('Could not load reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchOrders,
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
