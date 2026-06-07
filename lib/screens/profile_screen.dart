import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String get _displayName {
    final user = AuthService().user;
    final meta = user?.userMetadata;
    return meta?['display_name'] ?? meta?['full_name'] ?? user?.email?.split('@').first ?? 'Rider';
  }

  String get _email => AuthService().user?.email ?? '';
  bool get _isPremium => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(_displayName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ),
                const SizedBox(height: 12),
                Text(_displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_email, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPremium ? Colors.amber.withValues(alpha: 0.15) : AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isPremium ? 'PREMIUM' : 'FREE',
                    style: TextStyle(
                      color: _isPremium ? Colors.amber : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _sectionTitle('Actividad'),
          const SizedBox(height: 8),
          _menuCard(Icons.terrain, 'Mis Rutas', 'Rutas grabadas y subidas', () {}),
          _menuCard(Icons.notifications_active, 'Mis Alertas', 'Reportes que has hecho', () {}),
          _menuCard(Icons.verified, 'Verificaciones', 'Alertas que has confirmado', () {}),
          if (!_isPremium) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.amber.shade800, Colors.orange.shade700]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    const Text('Hazte Premium', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Mapas offline \u2022 GPS turn-by-turn \u2022 Sin anuncios \u2022 Rutas ilimitadas', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Ver planes desde \$3.990/mes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _sectionTitle('Configuracion'),
          const SizedBox(height: 8),
          _menuCard(Icons.info_outline, 'Acerca de RideChile', 'Version 1.0.0', () {}),
          _menuCard(Icons.help_outline, 'Ayuda y Soporte', 'Contactanos', () {}),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthService>().logout(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar Sesion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(text, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }

  Widget _menuCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
