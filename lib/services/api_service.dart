import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {bool includeAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http.get(url, headers: headers);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body, {
        bool includeAuth = true,
      }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> body, {
        bool includeAuth = true,
      }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http.delete(url, headers: headers);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Multipart request (for file uploads)
  Future<Map<String, dynamic>> multipartRequest(
      String endpoint,
      Map<String, String> fields,
      Map<String, File> files, {
        bool includeAuth = true,
      }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', url);

      // Add headers
      final headers = await _getHeaders(includeAuth: includeAuth);
      headers.remove('Content-Type'); // Remove for multipart
      request.headers.addAll(headers);

      // Add fields
      request.fields.addAll(fields);

      // Add files
      for (var entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final error = body['detail'] ?? body['message'] ?? 'Unknown error occurred';
      throw Exception(error);
    }
  }
}
