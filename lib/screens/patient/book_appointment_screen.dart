import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../models/doctor_model.dart';
import '../../utils/constants.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _appointmentType = 'offline';
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _timeSlots = [
    {'label': '09:00 AM', 'time': TimeOfDay(hour: 9, minute: 0)},
    {'label': '09:30 AM', 'time': TimeOfDay(hour: 9, minute: 30)},
    {'label': '10:00 AM', 'time': TimeOfDay(hour: 10, minute: 0)},
    {'label': '10:30 AM', 'time': TimeOfDay(hour: 10, minute: 30)},
    {'label': '11:00 AM', 'time': TimeOfDay(hour: 11, minute: 0)},
    {'label': '11:30 AM', 'time': TimeOfDay(hour: 11, minute: 30)},
    {'label': '12:00 PM', 'time': TimeOfDay(hour: 12, minute: 0)},
    {'label': '02:00 PM', 'time': TimeOfDay(hour: 14, minute: 0)},
    {'label': '02:30 PM', 'time': TimeOfDay(hour: 14, minute: 30)},
    {'label': '03:00 PM', 'time': TimeOfDay(hour: 15, minute: 0)},
    {'label': '03:30 PM', 'time': TimeOfDay(hour: 15, minute: 30)},
    {'label': '04:00 PM', 'time': TimeOfDay(hour: 16, minute: 0)},
    {'label': '04:30 PM', 'time': TimeOfDay(hour: 16, minute: 30)},
    {'label': '05:00 PM', 'time': TimeOfDay(hour: 17, minute: 0)},
  ];

  @override
  void dispose() {
    _complaintCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _formatTime24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppConstants.primaryColor,
            onPrimary: Colors.white,
            onSurface: AppConstants.textPrimaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Please select a date.');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select a time slot.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);

      final body = {
        'doctor_id': widget.doctor.id,
        'appointment_date':
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
        'appointment_time': _formatTime24(_selectedTime!),
        'appointment_type': _appointmentType,
        if (_complaintCtrl.text.trim().isNotEmpty)
          'chief_complaint': _complaintCtrl.text.trim(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        final err = jsonDecode(response.body);
        _showError(err['detail'] ?? err['message'] ?? 'Booking failed. Please try again.');
      }
    } catch (e) {
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppConstants.secondaryColor, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Appointment Booked!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Your appointment with Dr. ${widget.doctor.fullName} on ${_formatDate(_selectedDate!)} at ${_selectedTime!.format(context)} has been booked.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppConstants.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to search
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
    final hasOnline = doc.consultationFeeOnline != null;
    final fee = _appointmentType == 'online' && hasOnline
        ? doc.consultationFeeOnline!
        : doc.consultationFeeOffline;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Doctor Summary Card ──────────────────────────────────
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            AppConstants.primaryColor.withOpacity(0.12),
                        child: Text(
                          doc.fullName.isNotEmpty
                              ? doc.fullName
                                  .split(' ')
                                  .take(2)
                                  .map((w) => w[0].toUpperCase())
                                  .join()
                              : 'Dr',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${doc.fullName}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              doc.specialization,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppConstants.primaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${doc.yearsOfExperience} yrs exp  •  ${doc.qualificationBds}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textSecondaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Appointment Type ─────────────────────────────────────
              _sectionLabel('Appointment Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeChip(
                    label: 'Offline',
                    icon: Icons.local_hospital_outlined,
                    fee: '\u20b9${doc.consultationFeeOffline.toStringAsFixed(0)}',
                    selected: _appointmentType == 'offline',
                    onTap: () => setState(() => _appointmentType = 'offline'),
                  ),
                  const SizedBox(width: 12),
                  _TypeChip(
                    label: 'Online',
                    icon: Icons.videocam_outlined,
                    fee: hasOnline
                        ? '\u20b9${doc.consultationFeeOnline!.toStringAsFixed(0)}'
                        : 'N/A',
                    selected: _appointmentType == 'online',
                    onTap: hasOnline
                        ? () => setState(() => _appointmentType = 'online')
                        : null,
                    disabled: !hasOnline,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Select Date ──────────────────────────────────────────
              _sectionLabel('Select Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _selectedDate != null
                          ? AppConstants.primaryColor
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: _selectedDate != null
                            ? AppConstants.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : 'Choose a date',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedDate != null
                              ? AppConstants.textPrimaryColor
                              : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Select Time Slot ─────────────────────────────────────
              _sectionLabel('Select Time Slot'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final t = slot['time'] as TimeOfDay;
                  final isSelected = _selectedTime != null &&
                      _selectedTime!.hour == t.hour &&
                      _selectedTime!.minute == t.minute;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppConstants.primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        slot['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppConstants.textPrimaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Chief Complaint ──────────────────────────────────────
              _sectionLabel('Chief Complaint (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _complaintCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Describe your symptoms or reason for visit…',
                  hintStyle: const TextStyle(
                      color: AppConstants.textSecondaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppConstants.primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Fee Summary ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Consultation Fee',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      '\u20b9${fee.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Book Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Confirm Booking'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppConstants.textPrimaryColor,
        ),
      );
}

// ── Type Chip ──────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String fee;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.fee,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppConstants.primaryColor
                : disabled
                    ? Colors.grey.shade100
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppConstants.primaryColor
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? Colors.white
                      : disabled
                          ? Colors.grey.shade400
                          : AppConstants.primaryColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: selected
                      ? Colors.white
                      : disabled
                          ? Colors.grey.shade400
                          : AppConstants.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fee,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? Colors.white70
                      : disabled
                          ? Colors.grey.shade400
                          : AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
