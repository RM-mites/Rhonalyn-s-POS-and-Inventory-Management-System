import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await dotenv.load(fileName: '.env');
    if (!Env.isConfigured) {
      initError =
          'Supabase is not configured yet. Open the .env file in the project '
          'root and set SUPABASE_URL and SUPABASE_ANON_KEY, then restart the app.';
    } else {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
    }
  } catch (error) {
    initError = 'The app could not start:\n$error';
  }

  runApp(RhonalynsApp(initError: initError));
}
