import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../services/recording_service.dart';
import '../services/weather_service.dart';
import '../widgets/elevation_profile.dart';

class RouteSummaryScreen extends StatefulWidget {
  final String name;
  final String discipline;
  final String difficulty;
  final double distanceKm;
  final double elevationGainM;
  final Duration duration;
  final double avgSpeedKph;
  final double maxSpeedKph;
  final List<RecordingPoint> points;
  final List<String> photoPaths;

  const RouteSummaryScreen({
    super.key,
    required this.name,
    required this.discipline,
    required this.difficulty,
    required this.distanceKm,
    required this.elevationGainM,
    required this.duration,
    required this.avgSpeedKph,
    required this.maxSpeedKph,
    required this.points,
    this.photoPaths = const [],
  });

  @override
  State<RouteSummaryScreen> createState() => _RouteSummaryScreenState();
}

class _RouteSummaryScreenState extends State<RouteSummaryScreen> {
  final GlobalKey _cardKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  final WeatherService _weather = WeatherService();
  WeatherInfo? _weatherInfo;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final center = widget.points.isNotEmpty
        ? widget.points[widget.points.length ~/ 2]
        : null;
    if (center != null) {
      final w = await _weather.getWeather(center.lat, center.lon);
      if (mounted) setState(() => _weatherInfo = w);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.points.isNotEmpty
        ? LatLng(widget.points[widget.points.length ~/ 2].lat, widget.points[widget.points.length ~/ 2].lon)
        : const LatLng(-33.4489, -70.6693);

    final bounds = _calculateBounds();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Ruta'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareCard),
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: _addPhoto),
        ],
      ),
      body: RepaintBoundary(
        key: _cardKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 240,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 13,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: ApiConfig.mapboxToken.isNotEmpty ? ApiConfig.mapboxUrl : 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ridechile.app',
                      ),
                      PolylineLayer(polylines: [
                        Polyline(
                          points: widget.points.map((p) => LatLng(p.lat, p.lon)).toList(),
                          color: AppTheme.primary,
                          strokeWidth: 4,
                          borderStrokeWidth: 2,
                          borderColor: Colors.black45,
                        ),
                      ]),
                      MarkerLayer(markers: [
                        if (widget.points.isNotEmpty)
                          Marker(point: LatLng(widget.points.first.lat, widget.points.first.lon), width: 20, height: 20,
                            child: Container(decoration: BoxDecoration(color: AppTheme.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                        if (widget.points.isNotEmpty)
                          Marker(point: LatLng(widget.points.last.lat, widget.points.last.lon), width: 20, height: 20,
                            child: Container(decoration: BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _statsGrid(),
              if (widget.points.isNotEmpty) ...[
                const SizedBox(height: 20),
                ElevationProfile(
                  elevations: widget.points.where((p) => p.elevation != null).map((p) => p.elevation!).toList(),
                  distanceKm: widget.distanceKm,
                ),
              ],
              if (_weatherInfo != null) ...[
                const SizedBox(height: 16),
                _weatherCard(),
              ],
              const SizedBox(height: 20),
              if (widget.photoPaths.isNotEmpty) ...[
                const Text('Fotos de la ruta', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.photoPaths.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(widget.photoPaths[i]), width: 160, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _shareCard,
                  icon: const Icon(Icons.share),
                  label: const Text('COMPARTIR EN REDES'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _quickShare('Instagram', Icons.camera_alt_outlined, Colors.pink.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _quickShare('WhatsApp', Icons.chat, Colors.green.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _quickShare('Stories', Icons.auto_stories, Colors.purple.shade700)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: _disciplineColor(widget.discipline).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(widget.discipline, style: TextStyle(color: _disciplineColor(widget.discipline), fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        const SizedBox(height: 8),
        Text(widget.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(widget.difficulty, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      ],
    );
  }

  Widget _statsGrid() {
    return Row(
      children: [
        Expanded(child: _statCard('Distancia', '${widget.distanceKm.toStringAsFixed(2)}', 'km', Icons.straighten)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Velocidad', widget.avgSpeedKph.toStringAsFixed(1), 'km/h', Icons.speed)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Elevacion', '+${widget.elevationGainM.toStringAsFixed(0)}', 'm', Icons.trending_up)),
      ],
    );
  }

  Widget _statCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(unit, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ]),
    );
  }

  Widget _weatherCard() {
    final w = _weatherInfo!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Text(w.icon, style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${w.temp.toStringAsFixed(0)}°C', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(w.condition, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        const Spacer(),
        Column(children: [
          const Icon(Icons.air, color: Colors.white54, size: 18),
          Text('${w.windSpeed.toStringAsFixed(0)} km/h', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _quickShare(String label, IconData icon, Color color) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () => _shareTo(label),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Future<void> _shareCard() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ridechile_route.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.name}\n${widget.distanceKm.toStringAsFixed(1)} km | +${widget.elevationGainM.toStringAsFixed(0)} m | ${widget.discipline}\n#RideChile #MTB #Chile',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al compartir: $e')));
    }
  }

  Future<void> _shareTo(String platform) async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ridechile_${platform.toLowerCase()}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: 'Mira mi ruta en RideChile MTB! #RideChile');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => widget.photoPaths.add(picked.path));
    }
  }

  LatLngBounds _calculateBounds() {
    if (widget.points.isEmpty) return LatLngBounds(const LatLng(-33.5, -70.7), const LatLng(-33.4, -70.6));
    double minLat = 90, maxLat = -90, minLon = 180, maxLon = -180;
    for (final p in widget.points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }
    return LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
  }

  Color _disciplineColor(String d) => switch (d) {
    'XC' || 'XCM' => AppTheme.blue,
    'Trail' => AppTheme.secondary,
    'Enduro' => AppTheme.warning,
    'DH' => AppTheme.danger,
    'Gravel' => Colors.brown,
    _ => Colors.purple,
  };
}
