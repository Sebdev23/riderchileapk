import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.pedal_bike, size: 44, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              const Text('RideChile MTB', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('La comunidad de MTB en Chile', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
              const SizedBox(height: 48),

              if (auth.loading)
                const CircularProgressIndicator()
              else ...[
                _socialButton('Continuar con Google', 'assets/google.png', Icons.g_mobiledata, Colors.white, () => _loginGoogle(context)),
                const SizedBox(height: 12),
                _socialButton('Continuar con Apple', 'assets/apple.png', Icons.apple, Colors.white, () => _loginApple(context)),
                const SizedBox(height: 24),
                Row(children: [
                  const Expanded(child: Divider(color: Colors.white12)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('o', style: TextStyle(color: AppTheme.textSecondary))),
                  const Expanded(child: Divider(color: Colors.white12)),
                ]),
                const SizedBox(height: 24),
                _emailLogin(context),
              ],

              const SizedBox(height: 24),
              Text('Sin cuenta puedes ver el mapa. Para reportar alertas o grabar rutas necesitas iniciar sesion.',
                textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String text, String asset, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22, color: AppTheme.textPrimary),
        label: Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _emailLogin(BuildContext context) {
    final emailCtrl = TextEditingController();

    return Column(
      children: [
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 15),
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'tu@email.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa tu email')));
                return;
              }
              context.read<AuthService>().loginWithEmail(email).then((_) {
                if (context.mounted && context.read<AuthService>().isAuthenticated) {
                  Navigator.of(context).pop();
                }
              });
            },
            child: const Text('Entrar con Email'),
          ),
        ),
      ],
    );
  }

  void _loginGoogle(BuildContext context) {
    try {
      context.read<AuthService>().loginWithGoogle().then((_) {
        if (context.mounted && context.read<AuthService>().isAuthenticated) {
          Navigator.of(context).pop();
        }
      }).catchError((e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In no configurado aun. Usa email por ahora.')));
    }
  }

  void _loginApple(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In requiere configuracion en Apple Developer. Usa email.')),
    );
  }
}
