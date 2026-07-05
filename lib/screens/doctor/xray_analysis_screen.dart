import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/xray_service.dart';
import '../../utils/constants.dart';

/// Doctor-facing X-ray analysis screen.
/// Identical capability to the patient screen but adds a clinical notes
/// section and labels the view as a professional tool.
class XrayAnalysisScreen extends StatefulWidget {
  const XrayAnalysisScreen({super.key});

  @override
  State<XrayAnalysisScreen> createState() => _XrayAnalysisScreenState();
}

enum _AnalysisState { idle, analyzing, done, error }

class _XrayAnalysisScreenState extends State<XrayAnalysisScreen>
    with TickerProviderStateMixin {
  final XrayService _service = XrayService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  XrayAnalysisResult? _result;
  _AnalysisState _state = _AnalysisState.idle;
  String _errorMsg = '';
  bool _showDiseased = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 2048,
    );
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _state = _AnalysisState.idle;
    });
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() {
      _state = _AnalysisState.analyzing;
      _result = null;
    });
    final result = await _service.analyzeXray(_selectedImage!);
    setState(() {
      _result = result;
      _state = result.status == 'success'
          ? _AnalysisState.done
          : _AnalysisState.error;
      _errorMsg = result.errorMessage ?? 'Unknown error';
    });
  }

  Color _diseaseColor(String disease) {
    switch (disease) {
      case 'Healthy':           return const Color(0xFF4CAF50);
      case 'Caries':            return const Color(0xFFFF9800);
      case 'Deep Caries':       return const Color(0xFFF44336);
      case 'Periapical Lesion': return const Color(0xFFE91E63);
      case 'Impacted':          return const Color(0xFF2196F3);
      default:                  return Colors.grey;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'none':     return const Color(0xFF4CAF50);
      case 'mild':     return const Color(0xFFFF9800);
      case 'moderate': return const Color(0xFFFF5722);
      case 'severe':   return const Color(0xFFF44336);
      default:         return Colors.grey;
    }
  }

  IconData _diseaseIcon(String disease) {
    switch (disease) {
      case 'Healthy':           return Icons.check_circle;
      case 'Caries':            return Icons.warning_amber_rounded;
      case 'Deep Caries':       return Icons.dangerous;
      case 'Periapical Lesion': return Icons.gpp_bad;
      case 'Impacted':          return Icons.compress;
      default:                  return Icons.help_outline;
    }
  }

  String _overallStatusLabel(String s) {
    switch (s) {
      case 'all_healthy':        return 'All Healthy';
      case 'mostly_healthy':     return 'Mostly Healthy';
      case 'moderate_issues':    return 'Moderate Issues';
      case 'significant_issues': return 'Significant Issues';
      case 'no_teeth_detected':  return 'No Teeth Detected';
      default:                   return 'Unknown';
    }
  }

  Color _overallColor(String s) {
    switch (s) {
      case 'all_healthy':        return const Color(0xFF4CAF50);
      case 'mostly_healthy':     return const Color(0xFF8BC34A);
      case 'moderate_issues':    return const Color(0xFFFF9800);
      case 'significant_issues': return const Color(0xFFF44336);
      default:                   return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('AI X-ray Analysis (Clinical)'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildClinicalBanner(),
              const SizedBox(height: 12),
              _buildUploadSection(),
              const SizedBox(height: 16),
              if (_state == _AnalysisState.analyzing) _buildAnalyzingCard(),
              if (_state == _AnalysisState.done && _result != null)
                _buildResults(),
              if (_state == _AnalysisState.error) _buildErrorCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicalBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: AppConstants.primaryColor.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.medical_services_outlined, size: 18, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Clinical tool — AI results are decision-support only. '
                  'Diagnosis and treatment decisions remain the clinician\'s responsibility.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.biotech,
                      color: AppConstants.primaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload Patient X-ray',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Panoramic dental radiograph',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showSourceSheet,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 60,
                        color: AppConstants.primaryColor
                            .withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Text('Tap to select X-ray image',
                        style: TextStyle(
                            color: AppConstants.primaryColor
                                .withOpacity(0.7),
                            fontSize: 15)),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_selectedImage!,
                      fit: BoxFit.contain,
                      width: double.infinity),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSourceSheet,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      side: BorderSide(color: AppConstants.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_selectedImage != null &&
                        _state != _AnalysisState.analyzing)
                        ? _analyze
                        : null,
                    icon: const Icon(Icons.search),
                    label: const Text('Analyse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Image Source',
                  style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.biotech,
                    size: 44, color: AppConstants.primaryColor),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Analysing X-ray...',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Running Stage 1 segmentation + Stage 2 disease classification.\nThis may take 10–60 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              backgroundColor:
              AppConstants.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFF3F3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Analysis Failed',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            const SizedBox(height: 8),
            Text(_errorMsg,
                textAlign: TextAlign.center,
                style:
                const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _analyze,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final r = _result!;
    final s = r.summary!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCard(s),
        const SizedBox(height: 12),
        if (r.annotatedImageBase64 != null)
          _buildAnnotatedImageCard(r.annotatedImageBase64!),
        const SizedBox(height: 12),
        _buildAgeEstimateCard(s),
        const SizedBox(height: 12),
        _buildToothTypeCard(s),
        const SizedBox(height: 12),
        _buildDiseaseBreakdownCard(s),
        const SizedBox(height: 12),
        _buildTeethListCard(r.teeth),
        const SizedBox(height: 12),
        _buildNewAnalysisButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummaryCard(XraySummary s) {
    final color = _overallColor(s.overallStatus);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: color, size: 26),
                const SizedBox(width: 10),
                const Text('Clinical Summary',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border:
                  Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  _overallStatusLabel(s.overallStatus),
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statBadge(
                    label: 'Total',
                    value: '${s.totalTeethDetected}',
                    color: AppConstants.primaryColor,
                    icon: Icons.format_list_numbered),
                _statBadge(
                    label: 'Healthy',
                    value: '${s.healthyTeeth}',
                    color: const Color(0xFF4CAF50),
                    icon: Icons.check_circle_outline),
                _statBadge(
                    label: 'Issues',
                    value: '${s.diseasedTeeth}',
                    color: s.diseasedTeeth > 0
                        ? const Color(0xFFF44336)
                        : const Color(0xFF4CAF50),
                    icon: Icons.warning_amber_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(
            child: Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAnnotatedImageCard(String b64) {
    Uint8List bytes;
    try {
      bytes = base64Decode(b64);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.image_search,
                    color: AppConstants.primaryColor, size: 22),
                const SizedBox(width: 8),
                const Text('Annotated Radiograph',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Image.memory(bytes,
              fit: BoxFit.contain, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _buildColorLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorLegend() {
    final items = [
      ('Healthy', const Color(0xFF64DC00)),
      ('Caries', const Color(0xFFFF3232)),
      ('Deep Caries', const Color(0xFFC800C8)),
      ('Periapical', const Color(0xFF00C8FF)),
      ('Impacted', const Color(0xFF0064FF)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: items
          .map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: e.$2,
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(e.$1,
              style: const TextStyle(fontSize: 11)),
        ],
      ))
          .toList(),
    );
  }

  Widget _buildAgeEstimateCard(XraySummary s) {
    final age = s.ageEstimate;
    if (age.isEmpty) return const SizedBox.shrink();
    final range = age['age_range'] as String? ?? 'Undetermined';
    final basis = age['basis'] as String? ?? '';
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_search_outlined,
                    color: AppConstants.primaryColor, size: 22),
                const SizedBox(width: 8),
                const Text('Estimated Dental Age',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  range,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor),
                ),
              ),
            ),
            if (basis.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(basis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToothTypeCard(XraySummary s) {
    if (s.toothTypeBreakdown.isEmpty) return const SizedBox.shrink();
    final typeColors = {
      'Incisor': const Color(0xFF5C6BC0),
      'Canine': const Color(0xFF26A69A),
      'Premolar': const Color(0xFFEF6C00),
      'Molar': const Color(0xFF6D4C41),
      'Unknown': Colors.grey,
    };
    final typeIcons = {
      'Incisor': Icons.looks_one_outlined,
      'Canine': Icons.looks_two_outlined,
      'Premolar': Icons.looks_3_outlined,
      'Molar': Icons.looks_4_outlined,
      'Unknown': Icons.help_outline,
    };
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category_outlined, size: 20),
                SizedBox(width: 8),
                Text('Tooth Types Detected',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: s.toothTypeBreakdown.entries.map((e) {
                final type = e.key;
                final count = e.value as int;
                final color = typeColors[type] ?? Colors.grey;
                final icon =
                    typeIcons[type] ?? Icons.help_outline;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                          Text('$count detected',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color.withOpacity(0.7))),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseBreakdownCard(XraySummary s) {
    if (s.diseaseBreakdown.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_outline, size: 20),
                SizedBox(width: 8),
                Text('Findings Breakdown',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...s.diseaseBreakdown.entries.map((e) {
              final disease = e.key;
              final count = e.value as int;
              final total = s.totalTeethDetected;
              final fraction = total > 0 ? count / total : 0.0;
              final color = _diseaseColor(disease);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_diseaseIcon(disease),
                            color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(disease,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14))),
                        Text('$count',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor:
                        AlwaysStoppedAnimation<Color>(color),
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

  Widget _buildTeethListCard(List<ToothResult> teeth) {
    final filtered = _showDiseased
        ? teeth.where((t) => t.disease != 'Healthy').toList()
        : teeth;
    final sorted = [...filtered]
      ..sort((a, b) => a.fdiNumber.compareTo(b.fdiNumber));
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_list_bulleted, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Per-Tooth Results',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                FilterChip(
                  label: const Text('Issues only'),
                  selected: _showDiseased,
                  onSelected: (v) =>
                      setState(() => _showDiseased = v),
                  selectedColor:
                  AppConstants.primaryColor.withOpacity(0.15),
                  checkmarkColor: AppConstants.primaryColor,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: _showDiseased
                        ? AppConstants.primaryColor
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No issues found — all detected teeth are healthy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.green, fontSize: 14),
                  ),
                ),
              )
            else
              ...sorted.map((t) => _buildToothTile(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildToothTile(ToothResult t) {
    final color = _diseaseColor(t.disease);
    final severityColor = _severityColor(t.severity);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(
          '${t.fdiNumber}',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
      ),
      title: Text(t.disease,
          style:
          TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            t.toothType,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: severityColor.withOpacity(0.4)),
                ),
                child: Text(
                  t.severity.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: severityColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(t.diseaseConfidence * 100).toStringAsFixed(0)}% confidence',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      children: [
        if (t.advice.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(t.advice,
                        style: const TextStyle(
                            fontSize: 13, height: 1.4))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNewAnalysisButton() {
    return OutlinedButton.icon(
      onPressed: () => setState(() {
        _selectedImage = null;
        _result = null;
        _state = _AnalysisState.idle;
      }),
      icon: const Icon(Icons.refresh),
      label: const Text('Start New Analysis'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.primaryColor,
        side: BorderSide(color: AppConstants.primaryColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}