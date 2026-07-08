import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class LabProfileScreen extends StatefulWidget {
  const LabProfileScreen({super.key});

  @override
  State<LabProfileScreen> createState() => _LabProfileScreenState();
}

class _LabProfileScreenState extends State<LabProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _labNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _deliveryChargesCtrl;

  String? _labType;
  bool _pickupAvailable = true;
  bool _deliveryAvailable = true;
  bool _freeDelivery = false;

  @override
  void initState() {
    super.initState();
    _labNameCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _pincodeCtrl = TextEditingController();
    _deliveryChargesCtrl = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    _labNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _deliveryChargesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
        _populateControllers(data);
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _error = body['detail'] ?? body['message'] ?? 'Failed to load profile';
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

  void _populateControllers(Map<String, dynamic> data) {
    _labNameCtrl.text = data['lab_name'] ?? '';
    _ownerNameCtrl.text = data['owner_name'] ?? '';
    _addressCtrl.text = data['lab_address'] ?? '';
    _cityCtrl.text = data['city'] ?? '';
    _stateCtrl.text = data['state'] ?? '';
    _pincodeCtrl.text = data['pincode'] ?? '';
    _deliveryChargesCtrl.text = (data['delivery_charges'] ?? 0).toString();
    _labType = AppConstants.labTypes.contains(data['lab_type'])
        ? data['lab_type']
        : AppConstants.labTypes.first;
    _pickupAvailable = data['pickup_available'] ?? true;
    _deliveryAvailable = data['delivery_available'] ?? true;
    _freeDelivery = data['free_delivery'] ?? false;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      final body = {
        'lab_name': _labNameCtrl.text.trim(),
        'owner_name': _ownerNameCtrl.text.trim(),
        'lab_address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'lab_type': _labType,
        'pickup_available': _pickupAvailable,
        'delivery_available': _deliveryAvailable,
        'free_delivery': _freeDelivery,
        'delivery_charges':
            double.tryParse(_deliveryChargesCtrl.text.trim()) ?? 0.0,
      };
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.labProfile}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final updated = jsonDecode(response.body);
        _populateControllers(updated);
        setState(() {
          _profile = updated;
          _isEditing = false;
          _isSaving = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppConstants.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        final err = jsonDecode(response.body);
        _showError(err['detail'] ?? err['message'] ?? 'Failed to save profile');
        setState(() => _isSaving = false);
      }
    } catch (e) {
      _showError('Network error. Please check your connection.');
      setState(() => _isSaving = false);
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

  void _enterEdit() {
    if (_profile != null) _populateControllers(_profile!);
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    if (_profile != null) _populateControllers(_profile!);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Lab Profile'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing && !_isLoading && _error == null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: _enterEdit,
            ),
          if (_isEditing)
            TextButton(
              onPressed: _cancelEdit,
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
        ],
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
              : RefreshIndicator(
                  onRefresh: _fetchProfile,
                  color: AppConstants.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _isEditing ? _buildEditForm() : _buildViewMode(),
                  ),
                ),
    );
  }

  // ─── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Could not load profile',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchProfile,
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

  // ─── View Mode ───────────────────────────────────────────────────────────────
  Widget _buildViewMode() {
    final p = _profile!;
    final isActive = p['is_active'] ?? true;

    return Column(
      children: [
        // Avatar / Identity card
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor:
                      AppConstants.primaryColor.withOpacity(0.12),
                  child: Text(
                    (p['lab_name'] as String? ?? 'L')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  p['lab_name'] ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _labTypeLabel(p['lab_type'] ?? ''),
                  style: const TextStyle(
                      fontSize: 14, color: AppConstants.primaryColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusBadge(
                      label: isActive ? 'Active' : 'Inactive',
                      color: isActive
                          ? AppConstants.secondaryColor
                          : Colors.grey,
                    ),
                    if (p['is_verified'] != null) ...[
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: p['is_verified'] == true
                            ? 'Verified'
                            : 'Pending Verification',
                        color: p['is_verified'] == true
                            ? Colors.teal
                            : Colors.orange,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Lab details card
        _InfoCard(
          title: 'Lab Details',
          icon: Icons.science_outlined,
          rows: [
            _InfoRowData(Icons.badge_outlined, 'Lab ID',
                p['lab_id'] ?? '—'),
            _InfoRowData(Icons.person_outline, 'Owner',
                p['owner_name'] ?? '—'),
            _InfoRowData(Icons.verified_outlined, 'License No.',
                p['license_number'] ?? '—'),
            _InfoRowData(Icons.biotech_outlined, 'Lab Type',
                _labTypeLabel(p['lab_type'] ?? '')),
          ],
        ),
        const SizedBox(height: 12),

        // Address card
        _InfoCard(
          title: 'Address',
          icon: Icons.location_on_outlined,
          rows: [
            _InfoRowData(Icons.home_outlined, 'Address',
                p['lab_address'] ?? '—'),
            _InfoRowData(Icons.location_city_outlined, 'City',
                p['city'] ?? '—'),
            _InfoRowData(Icons.map_outlined, 'State',
                p['state'] ?? '—'),
            _InfoRowData(Icons.pin_outlined, 'Pincode',
                p['pincode'] ?? '—'),
          ],
        ),
        const SizedBox(height: 12),

        // Services card
        _InfoCard(
          title: 'Services & Delivery',
          icon: Icons.local_shipping_outlined,
          rows: [
            _InfoRowData(
              Icons.hail_outlined,
              'Sample Pickup',
              (p['pickup_available'] ?? false) ? 'Available' : 'Not available',
            ),
            _InfoRowData(
              Icons.delivery_dining_outlined,
              'Delivery',
              (p['delivery_available'] ?? false)
                  ? 'Available'
                  : 'Not available',
            ),
            _InfoRowData(
              Icons.currency_rupee,
              'Delivery Fee',
              (p['free_delivery'] ?? false)
                  ? 'Free'
                  : '\u20b9${(p['delivery_charges'] ?? 0).toString()}',
            ),
          ],
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _enterEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Edit Form ───────────────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormSection(
            title: 'Lab Information',
            children: [
              _field(
                ctrl: _labNameCtrl,
                label: 'Lab Name',
                icon: Icons.science_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Lab name is required' : null,
              ),
              _field(
                ctrl: _ownerNameCtrl,
                label: 'Owner Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Owner name is required' : null,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: _labType,
                  decoration: const InputDecoration(
                    labelText: 'Lab Type',
                    prefixIcon: Icon(Icons.biotech_outlined),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: AppConstants.labTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_labTypeLabel(t)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _labType = v),
                  validator: (v) =>
                      v == null ? 'Please select lab type' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _FormSection(
            title: 'Address',
            children: [
              _field(
                ctrl: _addressCtrl,
                label: 'Lab Address',
                icon: Icons.home_outlined,
                maxLines: 2,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      ctrl: _cityCtrl,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      ctrl: _stateCtrl,
                      label: 'State',
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),
              _field(
                ctrl: _pincodeCtrl,
                label: 'Pincode',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _FormSection(
            title: 'Services & Delivery',
            children: [
              _SwitchRow(
                icon: Icons.hail_outlined,
                label: 'Sample Pickup Available',
                value: _pickupAvailable,
                onChanged: (v) => setState(() => _pickupAvailable = v),
              ),
              _SwitchRow(
                icon: Icons.delivery_dining_outlined,
                label: 'Delivery Available',
                value: _deliveryAvailable,
                onChanged: (v) => setState(() => _deliveryAvailable = v),
              ),
              _SwitchRow(
                icon: Icons.card_giftcard_outlined,
                label: 'Free Delivery',
                value: _freeDelivery,
                onChanged: (v) => setState(() => _freeDelivery = v),
              ),
              if (!_freeDelivery)
                _field(
                  ctrl: _deliveryChargesCtrl,
                  label: 'Delivery Charges (\u20b9)',
                  icon: Icons.currency_rupee,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  String _labTypeLabel(String type) {
    switch (type) {
      case 'dental':
        return 'Dental Lab';
      case 'diagnostic':
        return 'Diagnostic Lab';
      case 'both':
        return 'Dental & Diagnostic';
      default:
        return type;
    }
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRowData(this.icon, this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRowData> rows;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppConstants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 18),
            ...rows.map((r) => _InfoRowWidget(r)),
          ],
        ),
      ),
    );
  }
}

class _InfoRowWidget extends StatelessWidget {
  final _InfoRowData data;
  const _InfoRowWidget(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              data.label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              data.value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.textPrimaryColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppConstants.textPrimaryColor)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }
}
