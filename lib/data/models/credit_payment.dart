class CreditPayment {
  const CreditPayment({
    required this.id,
    required this.customerId,
    this.saleId,
    required this.amount,
    required this.method,
    this.receivedBy,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final String? saleId;
  final double amount;
  final String method;
  final String? receivedBy;
  final String? notes;
  final DateTime createdAt;

  factory CreditPayment.fromMap(Map<String, dynamic> map) {
    return CreditPayment(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      saleId: map['sale_id'] as String?,
      amount: _toDouble(map['amount']),
      method: (map['method'] as String?) ?? 'cash',
      receivedBy: map['received_by'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
