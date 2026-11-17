import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/credit_payment.dart';
import '../models/customer.dart';
import '../supabase/supabase_client.dart';

class CustomersRepository {
  CustomersRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  final SupabaseClient _client;

  Future<List<Customer>> fetchCustomers() async {
    final data = await _client.from('customers').select().order('name');
    return (data as List)
        .map((e) => Customer.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Customer> saveCustomer({
    String? id,
    required String name,
    String? phone,
    String? email,
    String? address,
    required double creditLimit,
    String? notes,
    required bool isActive,
  }) async {
    final payload = {
      'name': name.trim(),
      'phone': _nullIfBlank(phone),
      'email': _nullIfBlank(email),
      'address': _nullIfBlank(address),
      'credit_limit': creditLimit,
      'notes': _nullIfBlank(notes),
      'is_active': isActive,
    };
    final row = id == null
        ? await _client.from('customers').insert(payload).select().single()
        : await _client
            .from('customers')
            .update(payload)
            .eq('id', id)
            .select()
            .single();
    return Customer.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  Future<List<CreditPayment>> fetchPayments(String customerId) async {
    final data = await _client
        .from('credit_payments')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => CreditPayment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    await _client.rpc('record_credit_payment', params: {
      'p_customer_id': customerId,
      'p_amount': amount,
      'p_method': method,
      'p_notes': _nullIfBlank(notes),
    });
  }

  static String? _nullIfBlank(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
