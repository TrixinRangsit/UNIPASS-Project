// lib/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// API base (emulator)
const String API_BASE = 'http://10.0.2.2:3000/api';

class Api {
  static Future<http.Response> post(String path, Map body) {
    final url = Uri.parse('$API_BASE$path');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String path) {
    final url = Uri.parse('$API_BASE$path');
    return http.get(url);
  }

  static Future<http.Response> put(String path, Map body) {
    final url = Uri.parse('$API_BASE$path');
    return http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String path) {
    final url = Uri.parse('$API_BASE$path');
    return http.delete(url);
  }
}
