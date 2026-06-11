import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsService {
  static const _colorKey = 'user_dot_color';

  static Future<Color> getDotColor() async {
    final prefs = await SharedPreferences.getInstance();
    final hex = prefs.getString(_colorKey);
    if (hex == null) return const Color(0xFF42A5F5);
    return Color(int.parse(hex, radix: 16));
  }

  static Future<void> setDotColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, color.toARGB32().toRadixString(16));
  }
}
