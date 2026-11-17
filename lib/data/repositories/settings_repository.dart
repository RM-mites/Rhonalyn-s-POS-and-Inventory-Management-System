import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/store_settings.dart';
import '../supabase/supabase_client.dart';

class SettingsRepository {
  SettingsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  final SupabaseClient _client;

  Future<StoreSettings> fetchSettings() async {
    final res = await _client
        .from('store_settings')
        .select(
            'store_name, address, contact, receipt_footer, default_low_stock_threshold')
        .eq('id', 1)
        .maybeSingle();
    if (res == null) return StoreSettings.defaults;
    return StoreSettings.fromMap(Map<String, dynamic>.from(res));
  }

  Future<void> saveSettings(StoreSettings settings) async {
    await _client
        .from('store_settings')
        .update(settings.toUpdateMap())
        .eq('id', 1);
  }
}
