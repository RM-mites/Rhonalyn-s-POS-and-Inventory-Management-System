import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/user_role.dart';
import '../supabase/supabase_client.dart';

class TeamRepository {
  TeamRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  final SupabaseClient _client;

  Future<List<Profile>> fetchMembers() async {
    final res = await _client
        .from('profiles')
        .select('id, full_name, role, is_active, created_at, updated_at')
        .order('full_name', ascending: true);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(Profile.fromMap)
        .toList();
  }

  Future<void> updateMember({
    required String id,
    required String fullName,
    required UserRole role,
    required bool isActive,
  }) async {
    await _client.from('profiles').update({
      'full_name': fullName.trim().isEmpty ? null : fullName.trim(),
      'role': role.dbValue,
      'is_active': isActive,
    }).eq('id', id);
  }
}
