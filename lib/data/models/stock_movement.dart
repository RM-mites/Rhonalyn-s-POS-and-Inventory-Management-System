class StockMovement {
  const StockMovement({
    required this.id,
    required this.variantId,
    required this.movementType,
    required this.quantityChange,
    this.referenceId,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.variantLabel,
    this.variantSku,
    this.productName,
  });

  final String id;
  final String variantId;
  final String movementType;
  final int quantityChange;
  final String? referenceId;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final String? variantLabel;
  final String? variantSku;
  final String? productName;

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    final pv = map['product_variants'];
    String? label;
    String? sku;
    String? productName;
    if (pv is Map<String, dynamic>) {
      label = pv['label'] as String?;
      sku = pv['sku'] as String?;
      final prod = pv['products'];
      if (prod is Map<String, dynamic>) {
        productName = prod['name'] as String?;
      }
    }
    return StockMovement(
      id: map['id'] as String,
      variantId: map['variant_id'] as String,
      movementType: (map['movement_type'] as String?) ?? 'adjustment',
      quantityChange: _toInt(map['quantity_change']),
      referenceId: map['reference_id'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      variantLabel: label,
      variantSku: sku,
      productName: productName,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
