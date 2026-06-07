import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  bool _loading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isPremium => true;
  bool get loading => _loading;

  AuthService() {
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<void> loginWithEmail(String email) async {
    _loading = true;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: 'ridechile2024',
      );
    } on AuthException catch (_) {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: 'ridechile2024',
        data: {'display_name': email.split('@').first},
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.ridechile.ridechile_app://callback',
    );
  }

  Future<void> loginWithApple() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.ridechile.ridechile_app://callback',
    );
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }
}
