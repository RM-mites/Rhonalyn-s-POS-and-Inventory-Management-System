import 'category.dart';
import 'product_variant.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.categoryId,
    this.category,
    this.description,
    required this.basePrice,
    required this.isMadeToOrder,
    required this.lowStockThreshold,
    this.imageUrl,
    required this.isActive,
    this.variants = const [],
  });

  final String id;
  final String name;
  final String sku;
  final String? categoryId;
  final Category? category;
  final String? description;
  final double basePrice;
  final bool isMadeToOrder;
  final int lowStockThreshold;
  final String? imageUrl;
  final bool isActive;
  final List<ProductVariant> variants;

  int get totalStock =>
      variants.where((v) => v.trackStock).fold(0, (sum, v) => sum + v.stockQty);

  factory Product.fromMap(Map<String, dynamic> map) {
    final catMap = map['categories'];
    final variantsRaw = map['product_variants'];
    return Product(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      sku: (map['sku'] as String?) ?? '',
      categoryId: map['category_id'] as String?,
      category: catMap is Map<String, dynamic> ? Category.fromMap(catMap) : null,
      description: map['description'] as String?,
      basePrice: _toDouble(map['base_price']),
      isMadeToOrder: map['is_made_to_order'] as bool? ?? false,
      lowStockThreshold: _toInt(map['low_stock_threshold'], fallback: 5),
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      variants: variantsRaw is List
          ? variantsRaw
              .whereType<Map<String, dynamic>>()
              .map(ProductVariant.fromMap)
              .toList()
          : const [],
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}
