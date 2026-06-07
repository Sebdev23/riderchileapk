import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RecordingPoint {
  final double lat;
  final double lon;
  final double? elevation;
  final DateTime timestamp;
  final double? speed;

  RecordingPoint({
    required this.lat,
    required this.lon,
    this.elevation,
    required this.timestamp,
    this.speed,
  });
}

class RecordingStats {
  final double distanceKm;
  final Duration duration;
  final double avgSpeedKph;
  final double maxSpeedKph;
  final double elevationGainM;
  final int points;

  RecordingStats({
    required this.distanceKm,
    required this.duration,
    required this.avgSpeedKph,
    required this.maxSpeedKph,
    required this.elevationGainM,
    required this.points,
  });
}

class RecordingService extends ChangeNotifier {
  List<RecordingPoint> _points = [];
  bool _isRecording = false;
  Timer? _timer;
  DateTime? _startTime;
  double _distanceKm = 0;
  double _elevationGain = 0;
  double _maxSpeed = 0;
  RecordingPoint? _lastPoint;

  List<RecordingPoint> get points => List.unmodifiable(_points);
  bool get isRecording => _isRecording;
  double get distanceKm => _distanceKm;
  Duration get elapsed => _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
  double get avgSpeedKph => elapsed.inSeconds > 0 ? (_distanceKm / elapsed.inSeconds) * 3600 : 0;
  double get maxSpeedKph => _maxSpeed;
  double get elevationGain => _elevationGain;

  RecordingStats get stats => RecordingStats(
        distanceKm: _distanceKm,
        duration: elapsed,
        avgSpeedKph: avgSpeedKph,
        maxSpeedKph: _maxSpeed,
        elevationGainM: _elevationGain,
        points: _points.length,
      );

  Future<void> startRecording() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) throw Exception('Permiso de ubicacion denegado');

    _points = [];
    _isRecording = true;
    _startTime = DateTime.now();
    _distanceKm = 0;
    _elevationGain = 0;
    _maxSpeed = 0;
    _lastPoint = null;
    notifyListeners();

    _recordPoint();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _recordPoint());
  }

  Future<void> _recordPoint() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      );

      final current = RecordingPoint(
        lat: position.latitude,
        lon: position.longitude,
        elevation: position.altitude > 0 ? position.altitude : null,
        timestamp: position.timestamp ?? DateTime.now(),
        speed: position.speed > 0 ? position.speed * 3.6 : null,
      );

      if (current.speed != null && current.speed! > _maxSpeed) {
        _maxSpeed = current.speed!;
      }

      if (_lastPoint != null) {
        final dist = _haversineKm(
          _lastPoint!.lat, _lastPoint!.lon,
          current.lat, current.lon,
        );
        if (dist < 0.003) return;
        _distanceKm += dist;

        final lastElev = _lastPoint!.elevation;
        final currElev = current.elevation;
        if (lastElev != null && currElev != null && currElev > lastElev) {
          _elevationGain += currElev - lastElev;
        }
      }

      _lastPoint = current;
      _points.add(current);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> stopRecording() {
    _timer?.cancel();
    _isRecording = false;
    notifyListeners();
    return Future.value();
  }

  String generateGpx() {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<gpx version="1.1" creator="RideChile MTB">');
    buf.writeln('<trk><name>RideChile Track</name><trkseg>');
    for (final pt in _points) {
      buf.writeln('<trkpt lat="${pt.lat}" lon="${pt.lon}">');
      if (pt.elevation != null) {
        buf.writeln('<ele>${pt.elevation!.toStringAsFixed(1)}</ele>');
      }
      buf.writeln('<time>${pt.timestamp.toUtc().toIso8601String()}</time>');
      buf.writeln('</trkpt>');
    }
    buf.writeln('</trkseg></trk></gpx>');
    return buf.toString();
  }

  String generateWkt() {
    if (_points.isEmpty) return 'POINT(-70.65 -33.44)';
    if (_points.length == 1) return 'POINT(${_points.first.lon} ${_points.first.lat})';
    final coords = _points.map((p) => '${p.lon} ${p.lat}').join(', ');
    return 'LINESTRING($coords)';
  }

  Future<bool> _checkPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}
