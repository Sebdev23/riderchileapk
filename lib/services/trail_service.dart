import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trail.dart';

class TrailService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Trail> _trails = [];
  bool _loading = false;

  List<Trail> get trails => _trails;
  bool get loading => _loading;

  Future<void> fetchTrails({String? discipline, bool canonicalOnly = false}) async {
    _loading = true;
    notifyListeners();

    try {
      dynamic query = _supabase.from('trails').select();
      if (discipline != null) query = query.eq('discipline', discipline);
      query = query.order('rating', ascending: false).limit(50);

      final data = await query;
      var result = data.map((j) => Trail.fromJson(j)).toList();
      if (canonicalOnly) result = result.where((t) => t.canonicalTrailId == null).toList();
      _trails = result;
    } catch (e) {
      debugPrint('Error fetching trails: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Trail>> findSimilar(double lat, double lon, {String? name}) async {
    try {
      final data = await _supabase.rpc('nearby_trails', params: {
        'lat': lat, 'lon': lon, 'radius_km': 2.0, 'name_filter': name ?? '',
      });
      return (data as List).map((j) => Trail.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error finding similar: $e');
    }
    return [];
  }

  Future<Trail?> uploadTrail({
    required String name,
    required String discipline,
    required String difficulty,
    String? description,
    required String gpxContent,
    String? canonicalTrailId,
  }) async {
    try {
      final uid = _supabase.auth.currentUser?.id;

      final insertData = <String, dynamic>{
        'name': name,
        'discipline': discipline,
        'difficulty': difficulty,
        'description': description,
        'user_id': uid,
        'is_public': true,
      };

      if (canonicalTrailId != null) {
        insertData['canonical_trail_id'] = canonicalTrailId;
        await _supabase.rpc('increment_times_ridden', params: {'trail_id': canonicalTrailId});
        final updated = await _supabase.from('trails').select().eq('id', canonicalTrailId).single();
        _updateLocalTrail(Trail.fromJson(updated));
        return Trail.fromJson(updated);
      }

      final trailData = await _supabase.rpc('insert_trail_with_gpx', params: {
        'p_name': name,
        'p_discipline': discipline,
        'p_difficulty': difficulty,
        'p_description': description ?? '',
        'p_gpx': gpxContent,
        'p_user_id': uid,
      });

      final trail = Trail.fromJson(trailData);
      _trails.insert(0, trail);
      notifyListeners();
      return trail;
    } catch (e) {
      debugPrint('Error uploading trail: $e');
    }
    return null;
  }

  Future<void> rateTrail(String trailId, double rating) async {
    try {
      await _supabase.rpc('rate_trail', params: {'trail_id': trailId, 'r': rating});
      final updated = await _supabase.from('trails').select().eq('id', trailId).single();
      _updateLocalTrail(Trail.fromJson(updated));
    } catch (e) {
      debugPrint('Error rating trail: $e');
    }
  }

  void _updateLocalTrail(Trail updated) {
    final idx = _trails.indexWhere((t) => t.id == updated.id);
    if (idx >= 0) {
      _trails[idx] = updated;
      notifyListeners();
    }
  }
}
