import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../supabase/supabase_client.dart';

class CatalogRepository {
  CatalogRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  final SupabaseClient _client;

  Future<List<Category>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .order('name', ascending: true);
    return (data as List)
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Category> saveCategory({
    String? id,
    required String name,
    String? description,
  }) async {
    final payload = {
      'name': name.trim(),
      'description': _nullIfBlank(description),
    };
    final row = id == null
        ? await _client.from('categories').insert(payload).select().single()
        : await _client
            .from('categories')
            .update(payload)
            .eq('id', id)
            .select()
            .single();
    return Category.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  Future<List<Product>> fetchProducts() async {
    final data = await _client
        .from('products')
        .select('*, categories(*), product_variants(*)')
        .order('name', ascending: true);
    final products = (data as List)
        .map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    for (final p in products) {
      p.variants.sort((a, b) => a.label.compareTo(b.label));
    }
    return products;
  }

  Future<String> saveProduct({
    String? id,
    required String name,
    required String sku,
    String? categoryId,
    String? description,
    required double basePrice,
    required bool isMadeToOrder,
    required int lowStockThreshold,
    String? imageUrl,
    required bool isActive,
  }) async {
    final payload = {
      'name': name.trim(),
      'sku': sku.trim(),
      'category_id': _nullIfBlank(categoryId),
      'description': _nullIfBlank(description),
      'base_price': basePrice,
      'is_made_to_order': isMadeToOrder,
      'low_stock_threshold': lowStockThreshold,
      'image_url': _nullIfBlank(imageUrl),
      'is_active': isActive,
    };
    final row = id == null
        ? await _client.from('products').insert(payload).select('id').single()
        : await _client
            .from('products')
            .update(payload)
            .eq('id', id)
            .select('id')
            .single();
    return (row['id'] as String);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  Future<void> saveVariant(String productId, VariantDraft draft) async {
    final map = draft.toMap(productId);
    if (draft.id == null) {
      map.remove('id');
      await _client.from('product_variants').insert(map);
    } else {
      await _client
          .from('product_variants')
          .update(map..remove('id'))
          .eq('id', draft.id!);
    }
  }

  Future<void> deleteVariant(String id) async {
    await _client.from('product_variants').delete().eq('id', id);
  }

  static String? _nullIfBlank(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
