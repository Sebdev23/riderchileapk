import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://qrkaqqhrcfnbdegwllhr.supabase.co';
  static const String anonKey = 'sb_publishable_XzlnANWdNbhG9_TqQVhZuw_F-FpfWbu';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
