class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.creditLimit,
    required this.balance,
    this.notes,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double creditLimit;
  final double balance;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;

  double get availableCredit =>
      creditLimit <= 0 ? double.infinity : (creditLimit - balance).clamp(0, creditLimit);

  bool get hasBalance => balance > 0;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      creditLimit: _toDouble(map['credit_limit']),
      balance: _toDouble(map['balance']),
      notes: map['notes'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
