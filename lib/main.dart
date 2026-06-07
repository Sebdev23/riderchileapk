import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/alert_service.dart';
import 'services/trail_service.dart';
import 'services/recording_service.dart';
import 'services/poi_service.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  runApp(const RideChileApp());
}

class RideChileApp extends StatelessWidget {
  const RideChileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AlertService()),
        ChangeNotifierProvider(create: (_) => TrailService()),
        ChangeNotifierProvider(create: (_) => RecordingService()),
        ChangeNotifierProvider(create: (_) => PoiService()),
      ],
      child: MaterialApp(
        title: 'RideChile MTB',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MapScreen(),
      ),
    );
  }
}
