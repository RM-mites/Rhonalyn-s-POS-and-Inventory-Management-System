class StoreSettings {
  const StoreSettings({
    required this.storeName,
    this.address,
    this.contact,
    this.receiptFooter,
    required this.defaultLowStockThreshold,
  });

  final String storeName;
  final String? address;
  final String? contact;
  final String? receiptFooter;
  final int defaultLowStockThreshold;

  static const defaults = StoreSettings(
    storeName: "Rhonalyn's Furniture",
    receiptFooter: 'Thank you for your purchase!',
    defaultLowStockThreshold: 5,
  );

  factory StoreSettings.fromMap(Map<String, dynamic> map) {
    return StoreSettings(
      storeName: _text(map['store_name']) ?? defaults.storeName,
      address: _text(map['address']),
      contact: _text(map['contact']),
      receiptFooter: _text(map['receipt_footer']),
      defaultLowStockThreshold:
          _int(map['default_low_stock_threshold']) ??
              defaults.defaultLowStockThreshold,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'store_name': storeName.trim().isEmpty ? defaults.storeName : storeName.trim(),
      'address': _text(address),
      'contact': _text(contact),
      'receipt_footer': _text(receiptFooter),
      'default_low_stock_threshold': defaultLowStockThreshold,
    };
  }

  static String? _text(dynamic raw) {
    final value = raw?.toString().trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  static int? _int(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }
}
