import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../supabase/supabase_client.dart';

class InventoryRepository {
  InventoryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  final SupabaseClient _client;

  Future<List<InventoryItem>> fetchInventoryItems() async {
    final data = await _client
        .from('product_variants')
        .select('*, products(id, name, low_stock_threshold)')
        .order('label', ascending: true);
    final items = (data as List)
        .map((e) => InventoryItem.fromVariantMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    items.sort((a, b) {
      final pn = a.productName.compareTo(b.productName);
      return pn != 0 ? pn : a.variantLabel.compareTo(b.variantLabel);
    });
    return items;
  }

  Future<List<StockMovement>> fetchMovements({
    String? variantId,
    int limit = 100,
  }) async {
    var query = _client
        .from('stock_movements')
        .select('*, product_variants(label, sku, products(name))');
    if (variantId != null) {
      query = query.eq('variant_id', variantId);
    }
    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List)
        .map((e) => StockMovement.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> adjustStock({
    required String variantId,
    required int quantityChange,
    String? notes,
    String movementType = 'adjustment',
  }) async {
    await _client.rpc('adjust_stock', params: {
      'p_variant_id': variantId,
      'p_quantity_change': quantityChange,
      'p_notes': notes,
      'p_movement_type': movementType,
    });
  }
}
