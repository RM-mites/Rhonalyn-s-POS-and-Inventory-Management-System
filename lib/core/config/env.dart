import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to the values loaded from the local `.env` file.
class Env {
  Env._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  /// True when both values look like real Supabase credentials.
  static bool get isConfigured {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    return url.startsWith('https://') &&
        !url.contains('your-project') &&
        key.isNotEmpty &&
        key != 'your-anon-public-key';
  }

  static String get projectHost {
    final uri = Uri.tryParse(supabaseUrl);
    return uri?.host.isNotEmpty == true ? uri!.host : supabaseUrl;
  }
}
