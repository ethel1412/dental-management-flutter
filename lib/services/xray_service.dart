import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// Result model for a single detected tooth.
class ToothResult {
  final int fdiNumber;
  final double detectionConfidence;
  final String disease;
  final double diseaseConfidence;
  final String severity;
  final String advice;
  final Map<String, dynamic> boundingBox;
  final Map<String, dynamic> diseaseProbabilities;

  const ToothResult({
    required this.fdiNumber,
    required this.detectionConfidence,
    required this.disease,
    required this.diseaseConfidence,
    required this.severity,
    required this.advice,
    required this.boundingBox,
    required this.diseaseProbabilities,
  });

  factory ToothResult.fromJson(Map<String, dynamic> j) => ToothResult(
        fdiNumber: j['fdi_number'] as int? ?? 0,
        detectionConfidence: (j['detection_confidence'] as num?)?.toDouble() ?? 0,
        disease: j['disease'] as String? ?? 'Unknown',
        diseaseConfidence: (j['disease_confidence'] as num?)?.toDouble() ?? 0,
        severity: j['severity'] as String? ?? 'unknown',
        advice: j['advice'] as String? ?? '',
        boundingBox: Map<String, dynamic>.from(j['bounding_box'] as Map? ?? {}),
        diseaseProbabilities:
            Map<String, dynamic>.from(j['disease_probabilities'] as Map? ?? {}),
      );
}

/// Summary of the full X-ray scan.
class XraySummary {
  final int totalTeethDetected;
  final int healthyTeeth;
  final int diseasedTeeth;
  final String overallStatus;
  final Map<String, dynamic> diseaseBreakdown;

  const XraySummary({
    required this.totalTeethDetected,
    required this.healthyTeeth,
    required this.diseasedTeeth,
    required this.overallStatus,
    required this.diseaseBreakdown,
  });

  factory XraySummary.fromJson(Map<String, dynamic> j) => XraySummary(
        totalTeethDetected: j['total_teeth_detected'] as int? ?? 0,
        healthyTeeth: j['healthy_teeth'] as int? ?? 0,
        diseasedTeeth: j['diseased_teeth'] as int? ?? 0,
        overallStatus: j['overall_status'] as String? ?? 'unknown',
        diseaseBreakdown:
            Map<String, dynamic>.from(j['disease_breakdown'] as Map? ?? {}),
      );
}

/// Full analysis result from the backend.
class XrayAnalysisResult {
  final String status;
  final XraySummary? summary;
  final List<ToothResult> teeth;
  final String? annotatedImageBase64;
  final String? errorMessage;

  const XrayAnalysisResult({
    required this.status,
    this.summary,
    required this.teeth,
    this.annotatedImageBase64,
    this.errorMessage,
  });

  factory XrayAnalysisResult.fromJson(Map<String, dynamic> j) => XrayAnalysisResult(
        status: j['status'] as String? ?? 'error',
        summary: j['summary'] != null
            ? XraySummary.fromJson(j['summary'] as Map<String, dynamic>)
            : null,
        teeth: (j['teeth'] as List? ?? [])
            .map((t) => ToothResult.fromJson(t as Map<String, dynamic>))
            .toList(),
        annotatedImageBase64: j['annotated_image_base64'] as String?,
        errorMessage: j['message'] as String?,
      );

  bool get hasIssues => (summary?.diseasedTeeth ?? 0) > 0;
}

class XrayService {
  final StorageService _storage = StorageService();

  Future<XrayAnalysisResult> analyzeXray(File imageFile) async {
    final token = await _storage.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/ml-analysis/analyze-xray');

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return XrayAnalysisResult.fromJson(json);
      } else {
        final err = jsonDecode(response.body);
        return XrayAnalysisResult(
          status: 'error',
          teeth: [],
          errorMessage: err['detail']?.toString() ?? 'Server error ${response.statusCode}',
        );
      }
    } catch (e) {
      return XrayAnalysisResult(
        status: 'error',
        teeth: [],
        errorMessage: e.toString(),
      );
    }
  }
}
