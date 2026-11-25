import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'secure_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
  }) async {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final token = await SecureStorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final stringQueryParams = queryParams?.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      final uri = Uri.parse(
        '${AppConfig.baseUrl}$endpoint',
      ).replace(queryParameters: stringQueryParams);

      AppLogger.d('GET: $uri');

      final response = await http
          .get(uri, headers: await _getHeaders(includeAuth: requiresAuth))
          .timeout(
            Duration(seconds: AppConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check your connection.');
    }
    // on SocketException {
    //   throw ApiException('No internet connection');
    // }
    on http.ClientException {
      throw ApiException('Connection failed');
    } catch (e, s) {
      AppLogger.e('GET request failed', e, s);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');

      AppLogger.d('POST: $uri');
      AppLogger.d('Body: ${jsonEncode(body)}');

      final response = await http
          .post(
            uri,
            headers: await _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(
            Duration(seconds: AppConfig.requestTimeout),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check your connection.');
    }
    // on SocketException {
    //   throw ApiException('No internet connection');
    // }
    on http.ClientException {
      throw ApiException('Connection failed');
    } catch (e, s) {
      AppLogger.e('POST request failed', e, s);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');

      AppLogger.d('PUT: $uri');

      final response = await http
          .put(
            uri,
            headers: await _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: AppConfig.requestTimeout));

      return _handleResponse(response);
    }
    //  on SocketException {
    //   throw ApiException('No internet connection');
    // }
    on http.ClientException {
      throw ApiException('Connection failed');
    } catch (e, s) {
      AppLogger.e('PUT request failed', e, s);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');
      AppLogger.d('PATCH: $uri');
      final response = await http
          .patch(
            uri,
            headers: await _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: AppConfig.requestTimeout));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check your connection.');
    } on http.ClientException {
      throw ApiException('Connection failed');
    } catch (e, s) {
      AppLogger.e('PATCH request failed', e, s);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');

      AppLogger.d('DELETE: $uri');

      final response = await http
          .delete(uri, headers: await _getHeaders(includeAuth: requiresAuth))
          .timeout(Duration(seconds: AppConfig.requestTimeout));

      return _handleResponse(response);
    }
    // on SocketException {
    //   throw ApiException('No internet connection');
    // }
    on http.ClientException {
      throw ApiException('Connection failed');
    } catch (e, s) {
      AppLogger.e('DELETE request failed', e, s);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> multipartRequest(
    String endpoint,
    String method, {
    Map<String, String>? fields,
    Map<String, File>? files,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');

      AppLogger.d('$method (multipart): $uri');

      final request = http.MultipartRequest(method, uri);

      if (requiresAuth) {
        final token = await SecureStorageService.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        for (var entry in files.entries) {
          final file = await http.MultipartFile.fromPath(
            entry.key,
            entry.value.path,
          );
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: AppConfig.requestTimeout * 2),
      );

      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    }
    //  on SocketException {
    //   throw ApiException('No internet connection');
    // }
    on http.ClientException {
      throw ApiException('Connection failed');
    } catch (e, s) {
      AppLogger.e('Multipart request failed', e, s);
      rethrow;
    }
  }

  static Future<Uint8List> download(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final stringQueryParams = queryParams?.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      final uri = Uri.parse(
        '${AppConfig.baseUrl}$endpoint',
      ).replace(queryParameters: stringQueryParams);

      AppLogger.d('DOWNLOAD: $uri');

      final response = await http
          .get(uri, headers: await _getHeaders(includeAuth: requiresAuth))
          .timeout(
            Duration(seconds: AppConfig.requestTimeout * 2),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
      final message = data['message'] ?? 'Download failed';
      throw ApiException(message, response.statusCode);
    } catch (e, s) {
      AppLogger.e('Download failed', e, s);
      rethrow;
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    AppLogger.d('Response status: ${response.statusCode}');
    AppLogger.d('Response body: ${response.body}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message'] ?? 'Request failed';
    throw ApiException(message, response.statusCode);
  }
}
