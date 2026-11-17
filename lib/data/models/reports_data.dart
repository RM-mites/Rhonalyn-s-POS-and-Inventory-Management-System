class DailySalesPoint {
  const DailySalesPoint({
    required this.date,
    required this.total,
    required this.salesCount,
  });

  final DateTime date;
  final double total;
  final int salesCount;
}

class TopProduct {
  const TopProduct({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final String name;
  final int quantity;
  final double revenue;
}

class PaymentBreakdown {
  const PaymentBreakdown({
    required this.method,
    required this.total,
    required this.count,
  });

  final String method;
  final double total;
  final int count;

  String get label {
    switch (method) {
      case 'gcash':
        return 'GCash';
      case 'bank_transfer':
        return 'Bank transfer';
      case 'credit':
        return 'Store credit';
      case 'cash':
      default:
        return 'Cash';
    }
  }
}

class LowStockEntry {
  const LowStockEntry({
    required this.productName,
    required this.variantLabel,
    required this.sku,
    required this.stockQty,
    required this.threshold,
  });

  final String productName;
  final String variantLabel;
  final String sku;
  final int stockQty;
  final int threshold;

  factory LowStockEntry.fromMap(Map<String, dynamic> map) {
    return LowStockEntry(
      productName: (map['product_name'] as String?) ?? 'Unknown product',
      variantLabel: (map['label'] as String?) ?? 'Default',
      sku: (map['sku'] as String?) ?? '—',
      stockQty: _i(map['stock_qty']),
      threshold: _i(map['threshold']),
    );
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class ReportsData {
  const ReportsData({
    required this.rangeDays,
    required this.from,
    required this.to,
    required this.totalRevenue,
    required this.totalSales,
    required this.itemsSold,
    required this.averageSale,
    required this.dailySales,
    required this.topProducts,
    required this.payments,
    required this.lowStock,
  });

  final int rangeDays;
  final DateTime from;
  final DateTime to;
  final double totalRevenue;
  final int totalSales;
  final int itemsSold;
  final double averageSale;
  final List<DailySalesPoint> dailySales;
  final List<TopProduct> topProducts;
  final List<PaymentBreakdown> payments;
  final List<LowStockEntry> lowStock;

  bool get hasSales => totalSales > 0;

  static double number(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int integer(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
