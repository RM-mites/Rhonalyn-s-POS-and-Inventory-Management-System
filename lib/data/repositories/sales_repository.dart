import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/sale_record.dart';
import '../supabase/supabase_client.dart';

class SalesRepository {
  SalesRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  final SupabaseClient _client;

  Future<SaleRecord> createSale({
    required List<CartItem> items,
    String? customerId,
    required String paymentMethod,
    required double discount,
    double? amountPaid,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'customer_id': customerId,
      'payment_method': paymentMethod,
      'discount': discount,
      'amount_paid': amountPaid,
      'notes': notes,
      'items': items.map((i) => i.toSaleItem()).toList(),
    };
    final res = await _client.rpc('create_sale', params: {'payload': payload});
    final map = Map<String, dynamic>.from(res as Map);
    return SaleRecord.fromMap(map);
  }

  Future<List<SaleRecord>> fetchSales({int limit = 200}) async {
    final res = await _client
        .from('sales')
        .select(
            'id, receipt_no, customer_id, cashier_id, subtotal, discount, total, amount_paid, change_due, payment_method, status, notes, voided_at, voided_by, created_at, customers(name), cashier:profiles!sales_cashier_id_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(SaleRecord.fromMap).toList();
  }

  Future<SaleDetail> fetchSaleDetail(String saleId) async {
    final saleRes = await _client
        .from('sales')
        .select(
            'id, receipt_no, customer_id, cashier_id, subtotal, discount, total, amount_paid, change_due, payment_method, status, notes, voided_at, voided_by, created_at, customers(name), cashier:profiles!sales_cashier_id_fkey(full_name)')
        .eq('id', saleId)
        .single();
    final sale = SaleRecord.fromMap(Map<String, dynamic>.from(saleRes as Map));

    final itemsRes = await _client
        .from('v_sale_item_details')
        .select('*')
        .eq('sale_id', saleId)
        .order('id');
    final items = (itemsRes as List)
        .cast<Map<String, dynamic>>()
        .map(SaleLineDetail.fromMap)
        .toList();

    List<MadeToOrderJobDetail> jobs = const [];
    try {
      final jobsRes = await _client
          .from('made_to_order_jobs')
          .select(
              'id, target_price, deposit_amount, balance_due, due_date, delivery_address, delivery_notes, specs')
          .eq('sale_id', saleId);
      jobs = (jobsRes as List)
          .cast<Map<String, dynamic>>()
          .map(MadeToOrderJobDetail.fromMap)
          .toList();
    } catch (_) {
      // jobs are optional/detail-only; ignore if unavailable
    }

    return SaleDetail(sale: sale, items: items, jobs: jobs);
  }

  Future<void> voidSale({required String saleId, String? reason}) async {
    await _client.rpc('void_sale', params: {
      'p_sale_id': saleId,
      'p_reason': (reason != null && reason.trim().isNotEmpty) ? reason.trim() : null,
    });
  }
}
