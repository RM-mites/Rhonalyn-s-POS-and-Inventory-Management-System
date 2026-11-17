class CartItem {
  CartItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.variantId,
    this.isCustom = false,
    this.trackStock = true,
    Map<String, dynamic>? customSpecs,
    this.notes,
    this.madeToOrder,
    this.maxQty,
  }) : customSpecs = customSpecs ?? {};

  final String? productId;
  final String? variantId;
  String description;
  int quantity;
  double unitPrice;
  bool isCustom;
  bool trackStock;
  Map<String, dynamic> customSpecs;
  String? notes;
  MadeToOrderInfo? madeToOrder;
  final int? maxQty; // null = unlimited (custom/MTO)

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toSaleItem() {
    final map = <String, dynamic>{
      'product_id': productId,
      'variant_id': variantId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'is_custom': isCustom,
      'track_stock': trackStock,
      'custom_specs': customSpecs.isEmpty ? null : customSpecs,
      'notes': notes,
    };
    if (madeToOrder != null) {
      map['made_to_order'] = madeToOrder!.toMap();
    }
    return map;
  }
}

class MadeToOrderInfo {
  MadeToOrderInfo({
    required this.targetPrice,
    required this.depositAmount,
    this.dueDate,
    this.deliveryAddress,
    this.deliveryNotes,
    Map<String, dynamic>? specs,
  }) : specs = specs ?? {};

  double targetPrice;
  double depositAmount;
  DateTime? dueDate;
  String? deliveryAddress;
  String? deliveryNotes;
  Map<String, dynamic> specs;

  double get balanceDue => (targetPrice - depositAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
        'target_price': targetPrice,
        'deposit_amount': depositAmount,
        'due_date': dueDate?.toIso8601String().substring(0, 10),
        'delivery_address': deliveryAddress,
        'delivery_notes': deliveryNotes,
        'specs': specs.isEmpty ? null : specs,
      };
}
