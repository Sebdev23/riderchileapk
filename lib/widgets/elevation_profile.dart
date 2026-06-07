import 'package:flutter/material.dart';
import '../config/theme.dart';

class ElevationProfile extends StatelessWidget {
  final List<double> elevations;
  final double distanceKm;

  const ElevationProfile({super.key, required this.elevations, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    if (elevations.isEmpty) return const SizedBox.shrink();

    final min = elevations.reduce((a, b) => a < b ? a : b);
    final max = elevations.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    final gain = _calculateGain();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Perfil de Elevacion', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          Text('+${gain.toStringAsFixed(0)} m', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Text('${max.toStringAsFixed(0)}m', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const Spacer(),
          Text('${distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            size: const Size(double.infinity, 100),
            painter: _ElevationPainter(elevations: elevations, min: min, range: range, color: AppTheme.primary),
          ),
        ),
        Row(children: [
          Text('${min.toStringAsFixed(0)}m', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ],
    );
  }

  double _calculateGain() {
    double g = 0;
    for (int i = 1; i < elevations.length; i++) {
      final d = elevations[i] - elevations[i - 1];
      if (d > 0) g += d;
    }
    return g;
  }
}

class _ElevationPainter extends CustomPainter {
  final List<double> elevations;
  final double min;
  final double range;
  final Color color;

  _ElevationPainter({required this.elevations, required this.min, required this.range, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (elevations.length < 2) return;

    final fillPaint = Paint()..color = color.withValues(alpha: 0.15);
    final linePaint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;

    final path = Path();
    final fillPath = Path();
    final n = elevations.length - 1;

    for (int i = 0; i <= n; i++) {
      final x = (i / n) * size.width;
      final y = size.height - ((elevations[i] - min) / (range == 0 ? 1 : range)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
