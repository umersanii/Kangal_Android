import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  static bool _initialized = false;

  static Future<void> initializeIfConfigured() async {
    if (_initialized) {
      return;
    }

    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      return;
    }

    try {
      Supabase.instance;
      _initialized = true;
      return;
    } catch (_) {
      // Supabase not initialized yet in this isolate.
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
  }
}