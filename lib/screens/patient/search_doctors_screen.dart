import 'package:flutter/material.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/constants.dart';
import 'book_appointment_screen.dart';

class SearchDoctorsScreen extends StatefulWidget {
  const SearchDoctorsScreen({super.key});

  @override
  State<SearchDoctorsScreen> createState() => _SearchDoctorsScreenState();
}

class _SearchDoctorsScreenState extends State<SearchDoctorsScreen> {
  final DoctorService _doctorService = DoctorService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();

  String? _selectedSpecialization;
  List<Doctor> _doctors = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchDoctors(); // load all doctors on open
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final results = await _doctorService.searchDoctors(
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        specialization: _selectedSpecialization,
      );
      setState(() => _doctors = results);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    _nameCtrl.clear();
    _cityCtrl.clear();
    setState(() => _selectedSpecialization = null);
    _searchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Find Doctors'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: AppConstants.primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Name search
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by doctor name…',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchDoctors(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // City filter
              Expanded(
                child: TextField(
                  controller: _cityCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'City',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon:
                        const Icon(Icons.location_on, color: Colors.white70, size: 18),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchDoctors(),
                ),
              ),
              const SizedBox(width: 10),
              // Specialization dropdown
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedSpecialization,
                      hint: const Text('Specialization',
                          style: TextStyle(color: Colors.white60, fontSize: 13)),
                      dropdownColor: AppConstants.primaryColor,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All', style: TextStyle(color: Colors.white)),
                        ),
                        ...AppConstants.specializations.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s,
                            child: Text(s, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedSpecialization = val);
                        _searchDoctors();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_doctors.isNotEmpty)
                Text(
                  '${_doctors.length} doctor${_doctors.length == 1 ? '' : 's'} found',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, color: Colors.white70, size: 16),
                    label: const Text('Clear',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero, padding: EdgeInsets.zero),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _searchDoctors,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConstants.primaryColor,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Could not load doctors',
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
                onPressed: _searchDoctors,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasSearched && _doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No doctors found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text('Try adjusting your filters',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _doctors.length,
      itemBuilder: (ctx, i) => _DoctorCard(
        doctor: _doctors[i],
        onBook: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookAppointmentScreen(doctor: _doctors[i]),
          ),
        ),
      ),
    );
  }
}

// ─── Doctor Card ────────────────────────────────────────────────────────────

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onBook;

  const _DoctorCard({required this.doctor, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final initials = doctor.fullName.isNotEmpty
        ? doctor.fullName
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : 'Dr';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
              child: Text(
                initials,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${doctor.fullName}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doctor.specialization,
                    style: TextStyle(
                        fontSize: 13, color: AppConstants.primaryColor),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        icon: Icons.workspace_premium,
                        label:
                            '${doctor.yearsOfExperience} yr${doctor.yearsOfExperience == 1 ? '' : 's'} exp',
                      ),
                      _InfoChip(
                        icon: Icons.currency_rupee,
                        label:
                            '₹${doctor.consultationFeeOffline.toStringAsFixed(0)} offline',
                      ),
                      if (doctor.consultationFeeOnline != null)
                        _InfoChip(
                          icon: Icons.videocam_outlined,
                          label:
                              '₹${doctor.consultationFeeOnline!.toStringAsFixed(0)} online',
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          doctor.qualificationBds +
                              (doctor.qualificationMds != null
                                  ? ', ${doctor.qualificationMds}'
                                  : ''),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Book button
            Column(
              children: [
                // Active indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: doctor.isActive
                        ? AppConstants.secondaryColor.withOpacity(0.12)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    doctor.isActive ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: doctor.isActive
                          ? AppConstants.secondaryColor
                          : Colors.red.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: doctor.isActive ? onBook : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Book'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
