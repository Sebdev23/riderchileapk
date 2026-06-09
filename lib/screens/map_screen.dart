import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../models/alert.dart';
import '../models/trail.dart';
import '../models/poi.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/recording_service.dart';
import '../services/trail_service.dart';
import '../services/poi_service.dart';
import '../services/weather_service.dart';
import '../services/presence_service.dart';
import 'auth_screen.dart';
import 'trails_list_screen.dart';
import 'profile_screen.dart';
import 'route_summary_screen.dart';
import 'emergency_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final MapController _mapCtrl = MapController();
  final LocationService _loc = LocationService();
  final ImagePicker _picker = ImagePicker();
  LatLng _center = const LatLng(-33.4489, -70.6693);
  LatLng? _userLocation;
  bool _ready = false;
  int _tab = 0;
  final List<String> _photoPaths = [];
  final WeatherService _weatherService = WeatherService();
  WeatherInfo? _weather;
  String _mapLayer = 'mapbox';
  Timer? _presenceTimer;
  int _prevAlertCount = 0;

  static final Map<String, Map<String, String>> _layers = {
    'osm': {
      'name': 'OpenStreetMap',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'attribution': '© OpenStreetMap',
    },
    'topo': {
      'name': 'Topografico',
      'url': 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
      'attribution': '© OpenTopoMap',
    },
    'satellite': {
      'name': 'Satelital',
      'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'attribution': '© Esri',
    },
    'mapbox': {
      'name': 'Mapbox (tipo Strava)',
      'url': ApiConfig.mapboxUrl,
      'attribution': '© Mapbox',
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final presence = context.read<PresenceService>();
    if (state == AppLifecycleState.paused) {
      presence.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (context.read<AuthService>().isAuthenticated) {
        presence.resume();
      }
      if (_userLocation != null) {
        context.read<AlertService>().fetchNearby(_userLocation!.latitude, _userLocation!.longitude);
      }
    }
  }

  Future<void> _init() async {
    await Future.wait([
      _locate(),
      context.read<TrailService>().fetchTrails(),
      context.read<PoiService>().fetchNearby(_center.latitude, _center.longitude),
    ]);
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    final auth = context.read<AuthService>();
    final presence = context.read<PresenceService>();
    if (auth.isAuthenticated && _userLocation != null) {
      presence.start(_userLocation!.latitude, _userLocation!.longitude);
    }
    _prevAlertCount = context.read<AlertService>().alerts.length;
    _presenceTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _periodicTick();
    });
  }

  Future<void> _periodicTick() async {
    if (!mounted) return;
    try {
      final p = await _loc.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _center = LatLng(p.latitude, p.longitude);
        _userLocation = LatLng(p.latitude, p.longitude);
      });
      final presence = context.read<PresenceService>();
      presence.updatePosition(p.latitude, p.longitude);
      if (!presence.isActive && context.read<AuthService>().isAuthenticated) {
        presence.start(p.latitude, p.longitude);
      }
      final alertService = context.read<AlertService>();
      await alertService.fetchNearby(p.latitude, p.longitude);
      if (mounted && alertService.alerts.length > _prevAlertCount && _prevAlertCount >= 0) {
        final latest = alertService.alerts.first;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${latest.typeIcon} Nueva alerta: ${latest.typeLabel} - ${latest.description}'),
          backgroundColor: AppTheme.warning,
          duration: const Duration(seconds: 5),
        ));
      }
      _prevAlertCount = alertService.alerts.length;
    } catch (e) {
      debugPrint('_periodicTick error: $e');
    }
  }

  Future<void> _locate() async {
    try {
      final p = await _loc.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _center = LatLng(p.latitude, p.longitude);
        _userLocation = LatLng(p.latitude, p.longitude);
        _ready = true;
      });
      _mapCtrl.move(_center, 14);
      context.read<AlertService>().fetchNearby(p.latitude, p.longitude);
      _loadWeather(p.latitude, p.longitude);
    } catch (_) {
      if (mounted) {
        setState(() => _ready = true);
        context.read<AlertService>().fetchNearby(_center.latitude, _center.longitude);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener ubicacion. Mostrando vista general.'), duration: Duration(seconds: 3)),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    context.read<PresenceService>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertService>();
    final trails = context.watch<TrailService>();
    final rec = context.watch<RecordingService>();
    final auth = context.watch<AuthService>();
    final bottom = MediaQuery.of(context).padding.bottom;
    final navBarH = 56.0 + bottom;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(alerts, trails, rec),
          if (!_ready) const Center(child: CircularProgressIndicator()),
          if (rec.isRecording) _recordingOverlay(rec, bottom),
          if (!rec.isRecording) ...[
            SafeArea(child: Column(children: [
              _topBarContent(),
              _poiFilterRow(),
              if (_weather != null) _weatherBadge(),
            ])),
            _alertSheet(alerts, navBarH),
            _fabColumn(auth, rec, navBarH, alerts),
          ],
        ],
      ),
      bottomNavigationBar: _bottomNav(auth, trails),
    );
  }

  Widget _buildMap(AlertService alerts, TrailService trails, RecordingService rec) {
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 12,
        onMapEvent: (e) {
          if (e is MapEventMoveEnd) {
            final c = e.camera.center;
            alerts.fetchNearby(c.latitude, c.longitude);
          }
        },
      ),
      children: [
              TileLayer(
                urlTemplate: _layers[_mapLayer]!['url']!,
                userAgentPackageName: 'com.MRIDER.app',
              ),
        PolylineLayer(polylines: [
          for (final t in trails.trails.where((t) => t.coordinates.length >= 2))
            Polyline(
              points: t.coordinates.map((c) => LatLng(c[0], c[1])).toList(),
              color: _disciplineColor(t.discipline),
              strokeWidth: 3,
              borderStrokeWidth: 1,
              borderColor: Colors.black54,
            ),
          if (rec.isRecording)
            Polyline(
              points: rec.points.map((p) => LatLng(p.lat, p.lon)).toList(),
              color: AppTheme.primary,
              strokeWidth: 4,
            ),
        ]),
        MarkerLayer(markers: [
          if (_userLocation != null) _userDotMarker(),
          for (final u in context.watch<PresenceService>().nearbyUsers) _presenceMarker(u),
          for (final a in alerts.alerts) _alertMarker(a),
          for (final t in trails.trails.where((t) => t.coordinates.isNotEmpty)) _trailMarker(t),
          for (final p in context.watch<PoiService>().pois) _poiMarker(p),
        ]),
      ],
    );
  }

  Marker _userDotMarker() {
    return Marker(
      point: _userLocation!,
      width: 20, height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.blue.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AppTheme.blue, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  Marker _presenceMarker(PresenceUser u) => Marker(
        point: LatLng(u.lat, u.lon),
        width: 70, height: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
              ),
              child: const Icon(Icons.pedal_bike, size: 14, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(u.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Marker _alertMarker(Alert a) => Marker(
        point: LatLng(a.lat, a.lon),
        width: 36, height: 36,
        child: GestureDetector(
          onTap: () => _showAlertDetail(a),
          child: Container(
            decoration: BoxDecoration(
              color: a.active ? AppTheme.danger : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
            ),
            child: Center(child: Text(a.typeIcon, style: const TextStyle(fontSize: 16))),
          ),
        ),
      );

  Marker _trailMarker(Trail t) {
    final start = t.coordinates.first;
    return Marker(
      point: LatLng(start[0], start[1]),
      width: 80, height: 28,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _disciplineColor(t.discipline).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _topBarContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.layers, size: 20), onPressed: _showLayerPicker, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrailsListScreen())),
              child: const Text('MRIDER', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
            )),
            IconButton(icon: const Icon(Icons.add_location, size: 20), onPressed: _showAddPoi, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
            IconButton(icon: const Icon(Icons.my_location, size: 20), onPressed: _locate, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          ],
        ),
      ),
    );
  }

  Widget _weatherBadge() {
    final w = _weather!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(w.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('${w.temp.toStringAsFixed(0)}°C ${w.condition}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            Icon(Icons.air, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text('${w.windSpeed.toStringAsFixed(0)} km/h', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  Widget _alertSheet(AlertService alerts, double navBarH) {
    if (alerts.alerts.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: EdgeInsets.only(bottom: navBarH),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32, height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: [
                const Text('Alertas cercanas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Text('${alerts.alerts.length}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            ),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: alerts.alerts.length,
                itemBuilder: (_, i) {
                  final a = alerts.alerts[i];
                  return GestureDetector(
                    onTap: () => _showAlertDetail(a),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(a.typeIcon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(a.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                            if (a.verifiedCount > 0) ...[
                              Icon(Icons.verified, size: 12, color: AppTheme.success),
                              const SizedBox(width: 2),
                              Text('${a.verifiedCount}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Expanded(child: Text(a.description, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordingOverlay(RecordingService rec, double bottom) {
    return Column(
      children: [
        SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _pulsingDot(),
                const SizedBox(width: 8),
                const Text('GRABANDO', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Text(_fmtDuration(rec.elapsed), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bigStat('${rec.distanceKm.toStringAsFixed(2)}', 'km', Icons.straighten),
                  _bigStat(rec.avgSpeedKph.toStringAsFixed(1), 'km/h', Icons.speed),
                  _bigStat('+${rec.elevationGain.toStringAsFixed(0)}', 'm', Icons.trending_up),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _smallStat('Max', '${rec.maxSpeedKph.toStringAsFixed(1)} km/h'),
                  _smallStat('Puntos', '${rec.points.length}'),
                  _smallStat('Fotos', '${_photoPaths.length}'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 44, height: 44,
                child: IconButton(
                  onPressed: _takePhoto,
                  icon: Icon(Icons.camera_alt, color: AppTheme.primary),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.card),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _finishRecording(rec),
                  icon: const Icon(Icons.stop),
                  label: const Text('DETENER Y GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pulsingDot() {
    return const _PulsingDotWidget();
  }

  Widget _fabColumn(AuthService auth, RecordingService rec, double navBarH, AlertService alerts) {
    return Positioned(
      right: 16,
      bottom: alerts.alerts.isNotEmpty ? 120 : navBarH + 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fab(Icons.fiber_manual_record, AppTheme.primary, 'record', () => _toggleRecord(rec, auth)),
          const SizedBox(height: 12),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.card,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: IconButton(
              icon: Icon(Icons.add_alert, color: AppTheme.warning, size: 22),
              onPressed: () => _reportAlert(auth),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: auth.isAuthenticated ? AppTheme.secondary : AppTheme.card,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: IconButton(
              icon: Icon(auth.isAuthenticated ? Icons.person : Icons.login, size: 22, color: Colors.white),
              onPressed: () => _goProfile(auth),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fab(IconData icon, Color color, String hero, VoidCallback onTap) {
    return SizedBox(
      width: 56, height: 56,
      child: FloatingActionButton(
        heroTag: hero,
        onPressed: onTap,
        backgroundColor: color,
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _bottomNav(AuthService auth, TrailService trails) {
    return BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) {
        if (i == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TrailsListScreen())).then((_) => trails.fetchTrails());
        } else if (i == 2) {
          _goProfile(auth);
        }
        setState(() => _tab = 0);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.terrain_outlined), activeIcon: Icon(Icons.terrain), label: 'Rutas'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }

  Widget _bigStat(String value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        Text(unit, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _smallStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Future<void> _loadWeather(double lat, double lon) async {
    final w = await _weatherService.getWeather(lat, lon);
    if (mounted) setState(() => _weather = w);
  }

  void _showLayerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Tipo de Mapa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ..._layers.entries.map((e) => ListTile(
              leading: Icon(e.key == _mapLayer ? Icons.check_circle : Icons.circle_outlined, color: e.key == _mapLayer ? AppTheme.primary : Colors.grey),
              title: Text(e.value['name']!),
              onTap: () { setState(() => _mapLayer = e.key); Navigator.pop(context); },
            )),
          ],
        ),
      ),
    );
  }

  void _showAddPoi() {
    String cat = 'food';
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Agregar Servicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cat,
              items: const [
                DropdownMenuItem(value: 'food', child: Text('Comida')),
                DropdownMenuItem(value: 'workshop', child: Text('Taller')),
                DropdownMenuItem(value: 'hydration', child: Text('Agua')),
                DropdownMenuItem(value: 'parking', child: Text('Estacionamiento')),
                DropdownMenuItem(value: 'shop', child: Text('Tienda')),
              ],
              onChanged: (v) => setSt(() => cat = v!),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripcion (opcional)')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefono (opcional)')),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Direccion (opcional)')),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresa un nombre'))); return; }
                Navigator.pop(ctx);
                await context.read<PoiService>().createPoi(
                  cat, nameCtrl.text.trim(), descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                  _center.latitude, _center.longitude,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Servicio agregado!'), backgroundColor: AppTheme.success));
                  context.read<PoiService>().fetchNearby(_center.latitude, _center.longitude);
                }
              }, child: const Text('Guardar')),
            ),
          ]),
        ),
      ),
    );
  }

  void _toggleRecord(RecordingService rec, AuthService auth) {
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }
    if (rec.isRecording) {
      _finishRecording(rec);
    } else {
      _photoPaths.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grabacion iniciada. Sal a rodar!'), backgroundColor: AppTheme.primary, duration: Duration(seconds: 2)),
      );
      rec.startRecording().catchError((e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        setState(() => _photoPaths.add(photo.path));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  void _finishRecording(RecordingService rec) {
    rec.stopRecording();
    if (rec.points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Muy pocos puntos para guardar')));
      return;
    }
    _showSaveDialog(rec);
  }

  void _showSaveDialog(RecordingService rec) {
    final nameCtrl = TextEditingController();
    String disc = 'XC', diff = 'Intermedio';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Guardar Ruta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(children: [Text('${rec.distanceKm.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), Text('Distancia', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))]),
                  Column(children: [Text('+${rec.elevationGain.toStringAsFixed(0)} m', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), Text('Elevacion', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))]),
                  Column(children: [Text(_fmtDuration(rec.elapsed), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), Text('Tiempo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))]),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la ruta', hintText: 'Ej: Cerro San Cristobal subida'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: disc,
                    items: ['XC', 'Trail', 'Enduro', 'DH', 'Gravel'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (v) => setSt(() => disc = v!),
                    decoration: const InputDecoration(labelText: 'Disciplina'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: diff,
                    items: ['Facil', 'Intermedio', 'Avanzado', 'Experto'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (v) => setSt(() => diff = v!),
                    decoration: const InputDecoration(labelText: 'Dificultad'),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresa un nombre'))); return; }
                    Navigator.pop(ctx);
                    await _checkSimilarAndSave(rec, name, disc, diff);
                  },
                  child: const Text('Guardar Ruta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkSimilarAndSave(RecordingService rec, String name, String disc, String diff) async {
    final trailService = context.read<TrailService>();
    try {
      final similar = await trailService.findSimilar(_center.latitude, _center.longitude, name: name);

      if (similar.isNotEmpty && mounted) {
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ruta similar encontrada'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ya existe "${similar.first.name}" en esta zona (${similar.first.lengthKm?.toStringAsFixed(1) ?? "?"} km).'),
                const SizedBox(height: 8),
                const Text('Que quieres hacer?', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, 'new'), child: const Text('Crear nueva')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, 'ride'), child: Text('Solo registrar que la hice (mejora ${similar.first.name})')),
            ],
          ),
        );

        if (choice == 'ride' && mounted) {
          final wkt = rec.generateWkt();
          await trailService.uploadTrail(name: name, discipline: disc, difficulty: diff, gpxContent: wkt, canonicalTrailId: similar.first.id);
          _navigateToSummary(name, disc, diff, rec);
          return;
        }
        if (choice != 'new') return;
      }
    } catch (e) {
      debugPrint('Error checking similar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al verificar rutas: $e'), backgroundColor: Colors.red));
      }
      return;
    }

    try {
      final wkt = rec.generateWkt();
      await trailService.uploadTrail(name: name, discipline: disc, difficulty: diff, gpxContent: wkt);
      if (mounted) _navigateToSummary(name, disc, diff, rec);
    } catch (e) {
      debugPrint('Error saving trail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar ruta: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _navigateToSummary(String name, String disc, String diff, RecordingService rec) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RouteSummaryScreen(
      name: name, discipline: disc, difficulty: diff,
      distanceKm: rec.distanceKm, elevationGainM: rec.elevationGain,
      duration: rec.elapsed, avgSpeedKph: rec.avgSpeedKph, maxSpeedKph: rec.maxSpeedKph,
      points: rec.points.map((p) => RecordingPoint(lat: p.lat, lon: p.lon, timestamp: p.timestamp, elevation: p.elevation, speed: p.speed)).toList(),
      photoPaths: List.from(_photoPaths),
    )));
    _photoPaths.clear();
    context.read<TrailService>().fetchTrails();
  }

  void _reportAlert(AuthService auth) {
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String type = 'obstaculo';
        final desc = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSt) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Reportar Alerta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'porton', child: Text('🚪 Porton Cerrado')),
                    DropdownMenuItem(value: 'robo', child: Text('⚠️ Robo')),
                    DropdownMenuItem(value: 'obstaculo', child: Text('🚧 Obstaculo')),
                    DropdownMenuItem(value: 'barro', child: Text('💧 Barro')),
                    DropdownMenuItem(value: 'talco', child: Text('🌫️ Talco')),
                    DropdownMenuItem(value: 'arbol_caido', child: Text('🌲 Arbol Caido')),
                  ],
                  onChanged: (v) => setSt(() => type = v!),
                  decoration: const InputDecoration(labelText: 'Tipo de alerta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: desc,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Descripcion', hintText: 'Describe lo que encontraste...'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (desc.text.trim().length < 10) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Minimo 10 caracteres'))); return; }
                      Navigator.pop(ctx);
                      final ok = await context.read<AlertService>().createAlert(type, desc.text.trim(), _center.latitude, _center.longitude);
                      if (mounted && ok != null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta reportada!'), backgroundColor: AppTheme.success));
                        context.read<AlertService>().fetchNearby(_center.latitude, _center.longitude);
                      }
                    },
                    child: const Text('Reportar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goProfile(AuthService auth) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => auth.isAuthenticated ? const ProfileScreen() : const AuthScreen(),
    ));
  }

  Widget _poiFilterRow() {
    final poi = context.watch<PoiService>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
          _poiChip('Todos', null, poi.activeCategory == null),
          _poiChip('Emergencia', 'emergency', poi.activeCategory == 'emergency'),
          _poiChip('Comida', 'food', poi.activeCategory == 'food'),
          _poiChip('Taller', 'workshop', poi.activeCategory == 'workshop'),
          _poiChip('Agua', 'hydration', poi.activeCategory == 'hydration'),
          _poiChip('Tienda', 'shop', poi.activeCategory == 'shop'),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            avatar: const Icon(Icons.phone, size: 14, color: Colors.white),
            backgroundColor: AppTheme.danger,
            labelStyle: const TextStyle(color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
          ),
        ]),
    );
  }

  Widget _poiChip(String label, String? category, bool selected) {
    final poi = context.read<PoiService>();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.textSecondary)),
        selected: selected,
        selectedColor: category == 'emergency' ? AppTheme.danger : AppTheme.primary,
        backgroundColor: AppTheme.card,
        onSelected: (_) => poi.fetchNearby(_center.latitude, _center.longitude, category: category),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Marker _poiMarker(Poi p) {
    return Marker(
      point: LatLng(p.lat, p.lon),
      width: 30, height: 30,
      child: GestureDetector(
        onTap: () => _showPoiDetail(p),
        child: Container(
          decoration: BoxDecoration(
            color: _poiColor(p.category).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
          ),
          child: Center(child: Text(p.categoryIcon, style: const TextStyle(fontSize: 14))),
        ),
      ),
    );
  }

  void _showPoiDetail(Poi p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(p.categoryIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _poiColor(p.category).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Text(p.categoryLabel, style: TextStyle(color: _poiColor(p.category), fontSize: 12, fontWeight: FontWeight.w600))),
              const Spacer(),
              if (p.phone != null) ...[
                IconButton(
                  icon: const Icon(Icons.phone, color: AppTheme.success),
                  onPressed: () => launchUrl(Uri.parse('tel:${p.phone}')),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            if (p.description != null) ...[const SizedBox(height: 4), Text(p.description!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14))],
            if (p.address != null) ...[const SizedBox(height: 4), Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(p.address!, style: const TextStyle(color: Colors.grey, fontSize: 12)))])],
            if (p.promotion != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
                child: Row(children: [const Icon(Icons.local_offer, color: Colors.amber, size: 16), const SizedBox(width: 8), Expanded(child: Text(p.promotion!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))) ]),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Color _poiColor(String category) => switch (category) {
    'emergency' => AppTheme.danger,
    'food' => AppTheme.warning,
    'workshop' => AppTheme.blue,
    'hydration' => const Color(0xFF00BCD4),
    'parking' => AppTheme.success,
    'shop' => Colors.purple,
    _ => Colors.grey,
  };

  void _showAlertDetail(Alert a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(a.typeIcon, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(child: Text(a.typeLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 16),
            Text(a.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.verified, size: 18, color: a.verifiedCount > 0 ? AppTheme.success : Colors.grey),
              const SizedBox(width: 4),
              Text('${a.verifiedCount} verificaciones', style: TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              Text(_fmtDate(a.createdAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Color _disciplineColor(String d) => switch (d) {
    'XC' || 'XCM' => AppTheme.blue,
    'Trail' => AppTheme.secondary,
    'Enduro' => AppTheme.warning,
    'DH' => AppTheme.danger,
    'Gravel' => Colors.brown,
    _ => Colors.purple,
  };

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _PulsingDotWidget extends StatefulWidget {
  const _PulsingDotWidget();

  @override
  State<_PulsingDotWidget> createState() => _PulsingDotWidgetState();
}

class _PulsingDotWidgetState extends State<_PulsingDotWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary.withValues(alpha: _animation.value),
        ),
      ),
    );
  }
}
