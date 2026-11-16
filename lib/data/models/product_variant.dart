class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.label,
    this.size,
    this.color,
    this.material,
    required this.price,
    required this.stockQty,
    this.lowStockThreshold,
    required this.trackStock,
    required this.isActive,
  });

  final String id;
  final String productId;
  final String sku;
  final String label;
  final String? size;
  final String? color;
  final String? material;
  final double price;
  final int stockQty;
  final int? lowStockThreshold;
  final bool trackStock;
  final bool isActive;

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      sku: (map['sku'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
      size: map['size'] as String?,
      color: map['color'] as String?,
      material: map['material'] as String?,
      price: _toDouble(map['price']),
      stockQty: _toInt(map['stock_qty']),
      lowStockThreshold: map['low_stock_threshold'] == null
          ? null
          : _toInt(map['low_stock_threshold']),
      trackStock: map['track_stock'] as bool? ?? true,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class VariantDraft {
  VariantDraft({
    this.id,
    this.sku = '',
    this.label = '',
    this.size,
    this.color,
    this.material,
    this.price = 0,
    this.stockQty = 0,
    this.lowStockThreshold,
    this.trackStock = true,
    this.isActive = true,
  });

  String? id;
  String sku;
  String label;
  String? size;
  String? color;
  String? material;
  double price;
  int stockQty;
  int? lowStockThreshold;
  bool trackStock;
  bool isActive;

  factory VariantDraft.fromVariant(ProductVariant v) => VariantDraft(
        id: v.id,
        sku: v.sku,
        label: v.label,
        size: v.size,
        color: v.color,
        material: v.material,
        price: v.price,
        stockQty: v.stockQty,
        lowStockThreshold: v.lowStockThreshold,
        trackStock: v.trackStock,
        isActive: v.isActive,
      );

  Map<String, dynamic> toMap(String productId) => {
        if (id != null) 'id': id,
        'product_id': productId,
        'sku': sku.trim(),
        'label': label.trim(),
        'size': _nullIfBlank(size),
        'color': _nullIfBlank(color),
        'material': _nullIfBlank(material),
        'price': price,
        'stock_qty': stockQty,
        'low_stock_threshold': lowStockThreshold,
        'track_stock': trackStock,
        'is_active': isActive,
      };

  static String? _nullIfBlank(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
