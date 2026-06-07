import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherInfo {
  final double temp;
  final int weatherCode;
  final double windSpeed;
  final String condition;

  WeatherInfo({required this.temp, required this.weatherCode, required this.windSpeed, required this.condition});

  String get icon {
    if (weatherCode <= 3) return '☀️';
    if (weatherCode <= 48) return '☁️';
    if (weatherCode <= 57) return '🌧️';
    if (weatherCode <= 67) return '🌨️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '⛈️';
    return '🌤️';
  }
}

class WeatherService {
  Future<WeatherInfo?> getWeather(double lat, double lon) async {
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        final code = current['weather_code'] as int;
        return WeatherInfo(
          temp: (current['temperature_2m'] as num).toDouble(),
          weatherCode: code,
          windSpeed: (current['wind_speed_10m'] as num).toDouble(),
          condition: _conditionLabel(code),
        );
      }
    } catch (e) {
      debugPrint('Weather error: $e');
    }
    return null;
  }

  String _conditionLabel(int code) {
    if (code <= 1) return 'Despejado';
    if (code <= 3) return 'Parcial';
    if (code <= 48) return 'Nublado';
    if (code <= 57) return 'Lluvia';
    if (code <= 67) return 'Lluvia fuerte';
    if (code <= 77) return 'Nieve';
    if (code <= 82) return 'Tormenta';
    return 'Variable';
  }
}
