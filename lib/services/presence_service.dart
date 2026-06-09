import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceUser {
  final String userId;
  final String displayName;
  final double lat;
  final double lon;
  final DateTime updatedAt;

  PresenceUser({
    required this.userId,
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.updatedAt,
  });

  factory PresenceUser.fromJson(Map<String, dynamic> json) {
    return PresenceUser(
      userId: json['user_id'],
      displayName: json['display_name'],
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class PresenceService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<PresenceUser> _nearbyUsers = [];
  Timer? _timer;
  bool _active = false;
  bool _paused = false;
  bool _disposed = false;
  double _currentLat = 0;
  double _currentLon = 0;
  String? _persistedUserId;
  StreamSubscription? _authSub;

  List<PresenceUser> get nearbyUsers => _nearbyUsers;
  bool get isActive => _active;

  PresenceService() {
    _authSub = _supabase.auth.onAuthStateChange.listen(_onAuthChange);
  }

  void _onAuthChange(AuthState data) {
    if (data.event == AuthChangeEvent.signedOut) {
      final uid = _persistedUserId;
      _active = false;
      _paused = false;
      _persistedUserId = null;
      _timer?.cancel();
      _timer = null;
      _nearbyUsers.clear();
      if (uid != null) {
        _supabase.from('user_locations').delete().eq('user_id', uid).then(
          (_) {},
          onError: (e) => debugPrint('PresenceService delete error: $e'),
        );
      }
      notifyListeners();
    } else if (data.event == AuthChangeEvent.signedIn && _paused) {
      resume();
    }
  }

  String? get _userId => _supabase.auth.currentUser?.id;
  String get _displayName {
    final u = _supabase.auth.currentUser;
    final meta = u?.userMetadata;
    if (meta == null) return 'Rutero';
    return (meta['display_name'] ?? meta['name'] ?? meta['email']?.toString().split('@').first ?? 'Rutero').toString();
  }

  void start(double lat, double lon) {
    final uid = _userId;
    if (uid == null) return;
    _active = true;
    _paused = false;
    _persistedUserId = uid;
    _currentLat = lat;
    _currentLon = lon;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
    notifyListeners();
  }

  void updatePosition(double lat, double lon) {
    _currentLat = lat;
    _currentLon = lon;
  }

  void pause() {
    if (!_active) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    if (!_active || _userId == null) return;
    _paused = false;
    _persistedUserId = _userId;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
  }

  void stop() {
    final uid = _persistedUserId;
    _active = false;
    _paused = false;
    _persistedUserId = null;
    _timer?.cancel();
    _timer = null;
    _nearbyUsers.clear();
    notifyListeners();
    if (uid != null) {
      _supabase.from('user_locations').delete().eq('user_id', uid).then(
        (_) {},
        onError: (e) => debugPrint('PresenceService delete error: $e'),
      );
    }
  }

  Future<void> _tick() async {
    if (!_active || _paused || _disposed) return;
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase.from('user_locations').upsert({
        'user_id': uid,
        'display_name': _displayName,
        'lat': _currentLat,
        'lon': _currentLon,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await _fetchNearby();
    } catch (e) {
      debugPrint('PresenceService tick error: $e');
    }
  }

  Future<void> _fetchNearby() async {
    if (_disposed) return;
    final uid = _userId;
    if (uid == null) return;
    try {
      final data = await _supabase.rpc('nearby_user_locations', params: {
        'lat': _currentLat,
        'lon': _currentLon,
        'radius_km': 50,
        'limit_count': 50,
      });

      if (_disposed) return;
      if (data is List) {
        _nearbyUsers = data.map((j) => PresenceUser.fromJson(j as Map<String, dynamic>)).toList();
        notifyListeners();
      } else {
        debugPrint('PresenceService unexpected response: ${data.runtimeType}');
      }
    } catch (e) {
      debugPrint('PresenceService fetch error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    stop();
    super.dispose();
  }
}
