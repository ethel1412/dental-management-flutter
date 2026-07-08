import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  // Timeout duration — Render free tier cold starts can take ~30s
  static const _timeout = Duration(seconds: 30);

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // GET
  Future<Map<String, dynamic>> get(String endpoint,
      {bool includeAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response =
          await http.get(url, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception(
          'Request timed out. The server may be starting up — please try again.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // POST
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception(
          'Request timed out. The server may be starting up — please try again.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // PUT
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception(
          'Request timed out. The server may be starting up — please try again.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // DELETE
  Future<Map<String, dynamic>> delete(String endpoint,
      {bool includeAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response =
          await http.delete(url, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception(
          'Request timed out. The server may be starting up — please try again.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Multipart (file uploads)
  Future<Map<String, dynamic>> multipartRequest(
    String endpoint,
    Map<String, String> fields,
    Map<String, File> files, {
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', url);

      final headers = await _getHeaders(includeAuth: includeAuth);
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      request.fields.addAll(fields);

      for (var entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }

      final streamedResponse =
          await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception(
          'Request timed out. The server may be starting up — please try again.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Safe response handler — guards against HTML error pages from cold-starting server
  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Server returned non-JSON (e.g. HTML error page during cold start)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'message': 'Success'};
      }
      throw Exception(
          'Server returned an unexpected response (status ${response.statusCode}). '
          'It may still be starting up — please try again in a moment.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final error =
          body['detail'] ?? body['message'] ?? 'Unknown error occurred';
      throw Exception(error);
    }
  }
}
