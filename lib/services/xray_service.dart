import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
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
        detectionConfidence:
            (j['detection_confidence'] as num?)?.toDouble() ?? 0,
        disease: j['disease'] as String? ?? 'Unknown',
        diseaseConfidence:
            (j['disease_confidence'] as num?)?.toDouble() ?? 0,
        severity: j['severity'] as String? ?? 'unknown',
        advice: j['advice'] as String? ?? '',
        boundingBox:
            Map<String, dynamic>.from(j['bounding_box'] as Map? ?? {}),
        diseaseProbabilities: Map<String, dynamic>.from(
            j['disease_probabilities'] as Map? ?? {}),
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
        diseaseBreakdown: Map<String, dynamic>.from(
            j['disease_breakdown'] as Map? ?? {}),
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

  factory XrayAnalysisResult.fromJson(Map<String, dynamic> j) =>
      XrayAnalysisResult(
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

/// Derive a MIME type from the file extension.
MediaType _mediaTypeFromPath(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  switch (ext) {
    case '.jpg':
    case '.jpeg':
      return MediaType('image', 'jpeg');
    case '.png':
      return MediaType('image', 'png');
    case '.webp':
      return MediaType('image', 'webp');
    default:
      return MediaType('image', 'jpeg'); // safe default for X-rays
  }
}

class XrayService {
  final StorageService _storage = StorageService();

  Future<XrayAnalysisResult> analyzeXray(File imageFile) async {
    final token = await _storage.getToken();

    // DEBUG — remove before release
    debugPrint('🔑 TOKEN: ${token != null ? '${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'NULL — not logged in!'}');
    debugPrint('🌐 URL: ${ApiConfig.baseUrl}${ApiConfig.analyzeXray}');

    if (token == null || token.isEmpty) {
      return const XrayAnalysisResult(
        status: 'error',
        teeth: [],
        errorMessage: 'Not authenticated. Please log out and log in again.',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.analyzeXray}');
    final contentType = _mediaTypeFromPath(imageFile.path);

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: contentType,
      ),
    );

    try {
      final streamed =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      debugPrint('📡 Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('🚨 Error body: ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return XrayAnalysisResult.fromJson(json);
      } else {
        Map<String, dynamic> err = {};
        try {
          err = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        return XrayAnalysisResult(
          status: 'error',
          teeth: [],
          errorMessage: err['detail']?.toString() ??
              'Server error ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('🚨 Exception: $e');
      return XrayAnalysisResult(
        status: 'error',
        teeth: [],
        errorMessage: e.toString(),
      );
    }
  }
}
