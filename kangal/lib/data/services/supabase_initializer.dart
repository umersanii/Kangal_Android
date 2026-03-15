import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  static bool _initialized = false;

  static Future<void> initializeRequired({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) {
      return;
    }

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env or --dart-define.',
      );
    }

    final parsedUrl = Uri.tryParse(url);
    final hasValidUrl =
        parsedUrl != null &&
        (parsedUrl.isScheme('https') || parsedUrl.isScheme('http')) &&
        parsedUrl.host.isNotEmpty;
    if (!hasValidUrl) {
      throw StateError(
        'Invalid SUPABASE_URL. Update .env with a valid URL (for example, https://<project-ref>.supabase.co).',
      );
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
