import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  SupabaseManager._();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
