import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.labOrders}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // backend may return list directly or wrapped in a key
          _orders = data is List ? data : (data['orders'] ?? data['lab_orders'] ?? []);
          _isLoading = false;
        });
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _error = body['detail'] ?? body['message'] ?? 'Failed to load orders';
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

  Future<void> _updateOrderStatus(dynamic orderId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.labOrders}/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as ${_statusLabel(newStatus)}'),
            backgroundColor: _statusColor(newStatus),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _fetchOrders();
      } else {
        final body = jsonDecode(response.body);
        _showError(body['detail'] ?? 'Failed to update order');
      }
    } catch (e) {
      _showError('Network error.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<dynamic> _filteredOrders(String? status) {
    if (status == null) return _orders;
    return _orders.where((o) => o['status'] == status).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return AppConstants.primaryColor;
      case 'completed':
        return AppConstants.secondaryColor;
      case 'cancelled':
        return AppConstants.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Lab Orders'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabAlignment: TabAlignment.start,
          tabs: _tabs
              .map((t) => Tab(text: t['label'] as String))
              .toList(),
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
                    final list = _filteredOrders(t['status'] as String?);
                    return _OrdersList(
                      orders: list,
                      onRefresh: _fetchOrders,
                      onUpdateStatus: _updateOrderStatus,
                      statusColor: _statusColor,
                      statusLabel: _statusLabel,
                    );
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
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Could not load orders',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
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
}

// ─── Orders List ──────────────────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  final List<dynamic> orders;
  final Future<void> Function() onRefresh;
  final Future<void> Function(dynamic id, String status) onUpdateStatus;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;

  const _OrdersList({
    required this.orders,
    required this.onRefresh,
    required this.onUpdateStatus,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No orders here',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              'Orders will appear here once placed',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: orders.length,
        itemBuilder: (ctx, i) => _OrderCard(
          order: orders[i],
          onUpdateStatus: onUpdateStatus,
          statusColor: statusColor,
          statusLabel: statusLabel,
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(dynamic id, String status) onUpdateStatus;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;

  const _OrderCard({
    required this.order,
    required this.onUpdateStatus,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  bool _updating = false;

  Map<String, dynamic> get o => widget.order;
  String get status => o['status'] ?? 'pending';

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _doUpdate(String newStatus) async {
    setState(() => _updating = true);
    await widget.onUpdateStatus(o['id'] ?? o['order_id'], newStatus);
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.statusColor(status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.biotech_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Order info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o['order_id'] ?? o['id']?.toString() ?? 'Order',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          o['test_name'] ?? o['order_type'] ?? 'Lab Test',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      widget.statusLabel(status).toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
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

          // ── Expandable details ───────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetails(color),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detail rows
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Doctor',
            value: o['doctor']?['full_name'] ?? o['doctor_name'] ?? '—',
          ),
          _DetailRow(
            icon: Icons.personal_injury_outlined,
            label: 'Patient',
            value: o['patient']?['full_name'] ?? o['patient_name'] ?? '—',
          ),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Order Date',
            value: _formatDate(o['created_at'] ?? o['order_date']),
          ),
          if (o['due_date'] != null)
            _DetailRow(
              icon: Icons.event_outlined,
              label: 'Due Date',
              value: _formatDate(o['due_date']),
            ),
          if (o['amount'] != null || o['total_amount'] != null)
            _DetailRow(
              icon: Icons.currency_rupee,
              label: 'Amount',
              value:
                  '\u20b9${(o['amount'] ?? o['total_amount']).toString()}',
            ),
          if (o['notes'] != null && o['notes'].toString().isNotEmpty)
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: o['notes'].toString(),
              multiline: true,
            ),
          if (o['delivery_required'] != null)
            _DetailRow(
              icon: Icons.local_shipping_outlined,
              label: 'Delivery',
              value: o['delivery_required'] == true ? 'Required' : 'Not required',
            ),

          // ── Action buttons ─────────────────────────────────────────────
          if (!_updating) _buildActions() else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.primaryColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (status == 'pending') {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _doUpdate('in_progress'),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Start'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  side: const BorderSide(color: AppConstants.primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _doUpdate('cancelled'),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.errorColor,
                  side: BorderSide(color: AppConstants.errorColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'in_progress') {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _doUpdate('completed'),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Mark as Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      );
    }

    // completed / cancelled — no actions
    return const SizedBox.shrink();
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.textPrimaryColor,
                  fontWeight: FontWeight.w500),
              maxLines: multiline ? 4 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
