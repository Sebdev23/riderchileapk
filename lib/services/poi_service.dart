import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/poi.dart';

class PoiService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Poi> _pois = [];
  bool _loading = false;
  String? _activeCategory;

  List<Poi> get pois => _pois;
  bool get loading => _loading;
  String? get activeCategory => _activeCategory;

  Future<void> fetchNearby(double lat, double lon, {String? category, double radiusKm = 50}) async {
    _loading = true;
    _activeCategory = category;
    notifyListeners();

    try {
      var query = _supabase.rpc('nearby_pois', params: {
        'lat': lat, 'lon': lon, 'radius_km': radiusKm,
      });

      final data = await query;
      var items = (data as List).map((j) => Poi.fromJson(j)).toList();

      if (category != null) {
        items = items.where((p) => p.category == category).toList();
      }

      _pois = items;
    } catch (e) {
      debugPrint('Error fetching POIs: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
