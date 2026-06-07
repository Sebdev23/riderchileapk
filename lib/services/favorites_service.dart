import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_trails';
  Set<String> _favorites = {};

  Set<String> get favorites => _favorites;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> toggle(String trailId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(trailId)) {
      _favorites.remove(trailId);
    } else {
      _favorites.add(trailId);
    }
    await prefs.setStringList(_key, _favorites.toList());
  }

  bool isFavorite(String trailId) => _favorites.contains(trailId);
}
