import 'dart:io' show Platform;
import 'secrets.dart';

class ApiConfig {
  static const String cloudUrl = '';

  static String get _host {
    if (cloudUrl.isNotEmpty) return cloudUrl;
    if (Platform.isAndroid) return '192.168.100.66';
    return 'localhost';
  }

  static String get baseUrl {
    final host = _host;
    if (host.startsWith('http')) return '${host.replaceAll(RegExp(r'/$'), '')}/api/v1';
    return 'http://$host:8080/api/v1';
  }

  static String get authUrl => '$baseUrl/auth/login';
  static String get reportsUrl => '$baseUrl/reports';
  static String get trailsUrl => '$baseUrl/trails';
  static String get poisUrl => '$baseUrl/pois';

  static Map<String, String> headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static String get mapboxToken => mapboxSecretToken;
  static String get mapboxUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/tiles/{z}/{x}/{y}?access_token=$mapboxToken';
}
