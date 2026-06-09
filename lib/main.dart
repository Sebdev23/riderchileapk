import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/alert_service.dart';
import 'services/trail_service.dart';
import 'services/recording_service.dart';
import 'services/poi_service.dart';
import 'services/presence_service.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true;
  };
  await SupabaseConfig.initialize();

  runApp(const MRIDERApp());
}

class MRIDERApp extends StatelessWidget {
  const MRIDERApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AlertService()),
        ChangeNotifierProvider(create: (_) => TrailService()),
        ChangeNotifierProvider(create: (_) => RecordingService()),
        ChangeNotifierProvider(create: (_) => PoiService()),
        ChangeNotifierProvider(create: (_) => PresenceService()),
      ],
      child: MaterialApp(
        title: 'MRIDER',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MapScreen(),
      ),
    );
  }
}
