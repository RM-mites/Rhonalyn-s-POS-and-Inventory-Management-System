class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.receiptNo,
    this.customerId,
    this.cashierId,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.amountPaid,
    required this.changeDue,
    required this.paymentMethod,
    required this.status,
    this.notes,
    this.voidedAt,
    this.voidedBy,
    this.createdAt,
    this.customerName,
    this.cashierName,
  });

  final String id;
  final String receiptNo;
  final String? customerId;
  final String? cashierId;
  final double subtotal;
  final double discount;
  final double total;
  final double amountPaid;
  final double changeDue;
  final String paymentMethod;
  final String status;
  final String? notes;
  final DateTime? voidedAt;
  final String? voidedBy;
  final DateTime? createdAt;
  final String? customerName;
  final String? cashierName;

  bool get isVoided => status == 'voided';

  factory SaleRecord.fromMap(Map<String, dynamic> map) {
    String? relName(dynamic rel) {
      if (rel is Map) return rel['name'] as String? ?? rel['full_name'] as String?;
      return null;
    }

    return SaleRecord(
      id: map['id'] as String,
      receiptNo: (map['receipt_no'] as String?) ?? '',
      customerId: map['customer_id'] as String?,
      cashierId: map['cashier_id'] as String?,
      subtotal: _d(map['subtotal']),
      discount: _d(map['discount']),
      total: _d(map['total']),
      amountPaid: _d(map['amount_paid']),
      changeDue: _d(map['change_due']),
      paymentMethod: (map['payment_method'] as String?) ?? 'cash',
      status: (map['status'] as String?) ?? 'completed',
      notes: map['notes'] as String?,
      voidedAt: map['voided_at'] != null
          ? DateTime.tryParse(map['voided_at'].toString())
          : null,
      voidedBy: map['voided_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      customerName: (map['customer_name'] as String?) ?? relName(map['customers']),
      cashierName: (map['cashier_name'] as String?) ?? relName(map['cashier']),
    );
  }

  static double _d(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class SaleLineDetail {
  const SaleLineDetail({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.isCustom,
    this.customSpecs,
    this.notes,
    this.productName,
    this.categoryName,
    this.variantLabel,
  });

  final String id;
  final String description;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final bool isCustom;
  final Map<String, dynamic>? customSpecs;
  final String? notes;
  final String? productName;
  final String? categoryName;
  final String? variantLabel;

  factory SaleLineDetail.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? specs;
    final raw = map['custom_specs'];
    if (raw is Map) specs = Map<String, dynamic>.from(raw);
    return SaleLineDetail(
      id: map['id'] as String,
      description: (map['description'] as String?) ?? 'Item',
      quantity: (map['quantity'] is int)
          ? map['quantity'] as int
          : int.tryParse(map['quantity']?.toString() ?? '') ?? 0,
      unitPrice: SaleRecord._d(map['unit_price']),
      lineTotal: SaleRecord._d(map['line_total']),
      isCustom: map['is_custom'] == true,
      customSpecs: specs,
      notes: map['notes'] as String?,
      productName: map['product_name'] as String?,
      categoryName: map['category_name'] as String?,
      variantLabel: map['variant_label'] as String?,
    );
  }
}

class MadeToOrderJobDetail {
  const MadeToOrderJobDetail({
    required this.id,
    required this.targetPrice,
    required this.depositAmount,
    required this.balanceDue,
    this.dueDate,
    this.deliveryAddress,
    this.deliveryNotes,
    this.specs,
  });

  final String id;
  final double targetPrice;
  final double depositAmount;
  final double balanceDue;
  final DateTime? dueDate;
  final String? deliveryAddress;
  final String? deliveryNotes;
  final Map<String, dynamic>? specs;

  factory MadeToOrderJobDetail.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? specs;
    final raw = map['specs'];
    if (raw is Map) specs = Map<String, dynamic>.from(raw);
    return MadeToOrderJobDetail(
      id: map['id'] as String,
      targetPrice: SaleRecord._d(map['target_price']),
      depositAmount: SaleRecord._d(map['deposit_amount']),
      balanceDue: SaleRecord._d(map['balance_due']),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      deliveryAddress: map['delivery_address'] as String?,
      deliveryNotes: map['delivery_notes'] as String?,
      specs: specs,
    );
  }
}

class SaleDetail {
  const SaleDetail({
    required this.sale,
    required this.items,
    required this.jobs,
  });

  final SaleRecord sale;
  final List<SaleLineDetail> items;
  final List<MadeToOrderJobDetail> jobs;
}
