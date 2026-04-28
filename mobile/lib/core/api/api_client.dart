import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.statusCode, this.message, [this.detail]);

  final int statusCode;
  final String message;
  final String? detail;

  @override
  String toString() =>
      'ApiException($statusCode): $message${detail == null ? '' : ' — $detail'}';
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException(401, 'Not signed in');
    }
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(String path) =>
      _send(() async => _http.get(_uri(path), headers: await _headers()));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() async => _http.post(
            _uri(path),
            headers: await _headers(),
            body: body == null ? null : jsonEncode(body),
          ));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() async => _http.patch(
            _uri(path),
            headers: await _headers(),
            body: body == null ? null : jsonEncode(body),
          ));

  Future<dynamic> delete(String path) =>
      _send(() async => _http.delete(_uri(path), headers: await _headers()));

  Future<dynamic> _send(Future<http.Response> Function() send) async {
    final res = await send();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String? detail;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['detail'] is String) {
        detail = decoded['detail'] as String;
      }
    } catch (_) {}
    throw ApiException(res.statusCode, _statusMessage(res.statusCode), detail);
  }

  String _statusMessage(int code) => switch (code) {
        400 => 'Bad request',
        401 => 'Unauthorized',
        403 => 'Forbidden',
        404 => 'Not found',
        429 => 'Rate limited',
        >= 500 => 'Server error',
        _ => 'Request failed',
      };
}

/// Default base URL per platform.
/// Override at runtime via `flutter run --dart-define=API_BASE_URL=...`.
String _defaultBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return 'http://localhost:8000';
  // Android emulator routes 10.0.2.2 to the host machine's localhost.
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://localhost:8000';
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _defaultBaseUrl());
});
