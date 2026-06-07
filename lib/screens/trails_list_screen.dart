import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/trail.dart';
import '../services/trail_service.dart';
import '../services/favorites_service.dart';
import '../widgets/elevation_profile.dart';
import 'trail_upload_screen.dart';

class TrailsListScreen extends StatefulWidget {
  const TrailsListScreen({super.key});

  @override
  State<TrailsListScreen> createState() => _TrailsListScreenState();
}

class _TrailsListScreenState extends State<TrailsListScreen> {
  String? _filter;
  bool _favoritesOnly = false;
  final _searchCtrl = TextEditingController();
  final FavoritesService _favs = FavoritesService();

  @override
  void initState() {
    super.initState();
    _favs.load().then((_) {
      Future.microtask(() => context.read<TrailService>().fetchTrails());
    });
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.watch<TrailService>();
    final trails = _favoritesOnly ? ts.trails.where((t) => _favs.isFavorite(t.id)).toList() : ts.trails;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas'),
        actions: [
          IconButton(icon: Icon(_favoritesOnly ? Icons.favorite : Icons.favorite_border), onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly)),
          IconButton(icon: const Icon(Icons.add), onPressed: () async {
            final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => const TrailUploadScreen()));
            if (ok == true && mounted) ts.fetchTrails();
          }),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar ruta por nombre...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); }) : null,
                filled: true, fillColor: AppTheme.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _chip('Todas', null, _filter == null),
              ...['XC', 'XCM', 'Trail', 'Enduro', 'DH', 'Gravel'].map((d) => _chip(d, d, _filter == d)),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ts.loading
                ? const Center(child: CircularProgressIndicator())
                : trails.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.terrain, size: 64, color: Colors.grey[800]),
                          const SizedBox(height: 12),
                          Text(_favoritesOnly ? 'No tienes favoritos' : 'No hay rutas aun', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ts.fetchTrails(discipline: _filter),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: trails.length,
                          itemBuilder: (_, i) => _trailCard(trails[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.textSecondary)),
        selected: selected,
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.card,
        onSelected: (_) { setState(() => _filter = value); context.read<TrailService>().fetchTrails(discipline: _filter); },
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _trailCard(Trail t) {
    final isFav = _favs.isFavorite(t.id);
    final query = _searchCtrl.text.toLowerCase();
    if (query.isNotEmpty && !t.name.toLowerCase().contains(query)) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showDetail(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: _disciplineColor(t.discipline).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(t.discipline, style: TextStyle(color: _disciplineColor(t.discipline), fontWeight: FontWeight.w700, fontSize: 12))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  _tag(t.difficulty),
                  if (t.lengthKm != null) ...[const SizedBox(width: 10), _inlineStat(Icons.straighten, '${t.lengthKm!.toStringAsFixed(1)} km')],
                  if (t.elevationGainM != null) ...[const SizedBox(width: 10), _inlineStat(Icons.trending_up, '+${t.elevationGainM!.toInt()}m')],
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            Column(children: [
              Row(children: [const Icon(Icons.star, size: 14, color: Colors.amber), const SizedBox(width: 2), Text(t.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
              const SizedBox(height: 2),
              Text('${t.timesRidden}x', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? AppTheme.danger : Colors.white38, size: 20),
              onPressed: () { _favs.toggle(t.id); setState(() {}); },
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)));

  Widget _inlineStat(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary), const SizedBox(width: 3),
        Text(text, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11))]);

  void _showDetail(Trail t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _disciplineColor(t.discipline), borderRadius: BorderRadius.circular(8)), child: Text(t.discipline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(child: Text(t.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _tag(t.difficulty),
            if (t.lengthKm != null) ...[const SizedBox(width: 12), _inlineStat(Icons.straighten, '${t.lengthKm!.toStringAsFixed(1)} km')],
            if (t.elevationGainM != null) ...[const SizedBox(width: 12), _inlineStat(Icons.trending_up, '+${t.elevationGainM!.toInt()} m')],
            const Spacer(),
            Text(_fmtDate(t.createdAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          if (t.description != null && t.description!.isNotEmpty) ...[const SizedBox(height: 16), Text(t.description!, style: const TextStyle(fontSize: 14))],
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Color _disciplineColor(String d) => switch (d) {
        'XC' || 'XCM' => AppTheme.blue, 'Trail' => AppTheme.secondary, 'Enduro' => AppTheme.warning, 'DH' => AppTheme.danger, 'Gravel' => Colors.brown, _ => Colors.purple,
      };

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
