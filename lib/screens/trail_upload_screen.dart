import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'dart:io';
import '../services/trail_service.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class TrailUploadScreen extends StatefulWidget {
  const TrailUploadScreen({super.key});

  @override
  State<TrailUploadScreen> createState() => _TrailUploadScreenState();
}

class _TrailUploadScreenState extends State<TrailUploadScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _discipline = 'XC';
  String _difficulty = 'Intermedio';
  String? _filePath;
  String? _fileName;
  bool _uploading = false;

  static const _disciplines = ['XC', 'XCM', 'Trail', 'Enduro', 'DH', 'Gravel'];
  static const _difficulties = ['Facil', 'Intermedio', 'Avanzado', 'Experto'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      });
      return const Scaffold(body: Center(child: Text('Debes iniciar sesion')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Subir Ruta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la ruta', border: OutlineInputBorder(), hintText: 'Ej: Cerro San Cristobal - Subida'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _discipline,
              decoration: const InputDecoration(labelText: 'Disciplina', border: OutlineInputBorder()),
              items: _disciplines.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _discipline = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(labelText: 'Dificultad', border: OutlineInputBorder()),
              items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _difficulty = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripcion (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_fileName ?? 'Seleccionar archivo GPX'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            ),
            if (_filePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Archivo: $_fileName', style: const TextStyle(color: Colors.green)),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: const Icon(Icons.cloud_upload),
              label: Text(_uploading ? 'Subiendo...' : 'Subir Ruta'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowedExtensions: ['gpx', 'xml'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path!;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Ingresa un nombre para la ruta');
      return;
    }
    if (_filePath == null) {
      _showError('Selecciona un archivo GPX');
      return;
    }

    setState(() => _uploading = true);
    final trailService = context.read<TrailService>();

    try {
      final file = File(_filePath!);
      final content = await file.readAsString();
      final wkt = _parseGpxToWkt(content);
      final trail = await trailService.uploadTrail(
        name: _nameController.text.trim(),
        discipline: _discipline,
        difficulty: _difficulty,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        gpxContent: wkt,
      );

      if (mounted) {
        if (trail != null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ruta subida correctamente'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          _showError('Error al subir la ruta');
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _parseGpxToWkt(String gpxContent) {
    try {
      final doc = XmlDocument.parse(gpxContent);
      final pts = <String>[];

      for (final trkpt in doc.findAllElements('trkpt')) {
        final lat = trkpt.getAttribute('lat');
        final lon = trkpt.getAttribute('lon');
        if (lat != null && lon != null) {
          pts.add('$lon $lat');
        }
      }

      if (pts.length >= 2) return 'LINESTRING(${pts.join(', ')})';
      if (pts.length == 1) return 'POINT(${pts.first})';
    } catch (_) {}

    return 'POINT(-70.65 -33.44)';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
