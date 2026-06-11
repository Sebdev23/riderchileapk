import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alert.dart';

class AlertService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Alert> _alerts = [];
  bool _loading = false;

  List<Alert> get alerts => _alerts;
  bool get loading => _loading;

  Future<void> fetchNearby(double lat, double lon, {double radiusKm = 10.0}) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _supabase.rpc('nearby_alerts', params: {
        'lat': lat,
        'lon': lon,
        'radius_km': radiusKm,
        'limit_count': 50,
      });

      _alerts = (data as List).map((j) => Alert.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      _alerts = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Alert?> createAlert(String type, String description, double lat, double lon, {String? photoUrl}) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      final body = <String, dynamic>{
        'alert_type': type,
        'description': description,
        'geom': 'POINT($lon $lat)',
        'user_id': uid,
      };
      if (photoUrl != null) body['photo_url'] = photoUrl;
      final data = await _supabase.from('alerts').insert(body).select().single();

      final alert = Alert.fromJson(data);
      _alerts.insert(0, alert);
      notifyListeners();
      return alert;
    } catch (e) {
      debugPrint('Error creating alert: $e');
    }
    return null;
  }

  Future<bool> verifyAlert(String alertId) async {
    try {
      await _supabase.rpc('verify_alert', params: {'alert_id': alertId});
      final idx = _alerts.indexWhere((a) => a.id == alertId);
      if (idx != -1) {
        final old = _alerts[idx];
        _alerts[idx] = Alert(
          id: old.id, alertType: old.alertType, description: old.description,
          active: old.active, verifiedCount: old.verifiedCount + 1,
          lat: old.lat, lon: old.lon, createdAt: old.createdAt, updatedAt: old.updatedAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error verifying alert: $e');
      return false;
    }
  }
}
