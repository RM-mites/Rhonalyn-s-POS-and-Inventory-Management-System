class InventoryItem {
  const InventoryItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantLabel,
    required this.variantSku,
    required this.stockQty,
    required this.threshold,
    required this.trackStock,
    required this.isActive,
  });

  final String variantId;
  final String productId;
  final String productName;
  final String variantLabel;
  final String variantSku;
  final int stockQty;
  final int threshold;
  final bool trackStock;
  final bool isActive;

  bool get isLowStock => trackStock && stockQty <= threshold;

  factory InventoryItem.fromVariantMap(Map<String, dynamic> map) {
    final prod = map['products'];
    String productName = '';
    int productThreshold = 5;
    String productId = map['product_id'] as String? ?? '';
    if (prod is Map<String, dynamic>) {
      productName = (prod['name'] as String?) ?? '';
      productId = (prod['id'] as String?) ?? productId;
      final pt = prod['low_stock_threshold'];
      if (pt is int) {
        productThreshold = pt;
      } else if (pt is num) {
        productThreshold = pt.toInt();
      }
    }
    final override = map['low_stock_threshold'];
    int? overrideInt;
    if (override is int) {
      overrideInt = override;
    } else if (override is num) {
      overrideInt = override.toInt();
    }
    return InventoryItem(
      variantId: map['id'] as String,
      productId: productId,
      productName: productName,
      variantLabel: (map['label'] as String?) ?? '',
      variantSku: (map['sku'] as String?) ?? '',
      stockQty: _toInt(map['stock_qty']),
      threshold: overrideInt ?? productThreshold,
      trackStock: map['track_stock'] as bool? ?? true,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
