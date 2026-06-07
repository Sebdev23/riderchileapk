import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const _emergencies = [
    {'name': 'SAMU (Ambulancia)', 'number': '131', 'icon': '🚑', 'desc': 'Servicio de Atencion Medica de Urgencia'},
    {'name': 'Bomberos', 'number': '132', 'icon': '🚒', 'desc': 'Incendios, rescate, accidentes'},
    {'name': 'Carabineros', 'number': '133', 'icon': '🚔', 'desc': 'Policia de Chile'},
    {'name': 'PDI', 'number': '134', 'icon': '🕵️', 'desc': 'Policia de Investigaciones'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergencias')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('En caso de emergencia, llama directamente. Los numeros son gratuitos y funcionan sin saldo.', style: TextStyle(fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 20),
          ..._emergencies.map((e) => _emergencyCard(e['name']!, e['number']!, e['icon']!, e['desc']!)),
          const SizedBox(height: 24),
          const Text('Hospitales y Comisarias Cercanas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.map),
              label: const Text('Ver en el mapa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emergencyCard(String name, String number, String icon, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 32)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(desc, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:$number')),
            icon: const Icon(Icons.phone, size: 16),
            label: Text(number, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          ),
        ),
        onTap: () => launchUrl(Uri.parse('tel:$number')),
      ),
    );
  }
}
