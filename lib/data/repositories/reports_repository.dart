import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reports_data.dart';
import '../supabase/supabase_client.dart';

class ReportsRepository {
  ReportsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  final SupabaseClient _client;

  Future<ReportsData> fetchReports({required int rangeDays}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(Duration(days: math.max(rangeDays - 1, 0)));
    final fromIso = from.toUtc().toIso8601String();

    final salesRes = await _client
        .from('sales')
        .select('id, created_at, total, payment_method, status')
        .eq('status', 'completed')
        .gte('created_at', fromIso)
        .order('created_at');

    final itemsRes = await _client
        .from('v_sale_item_details')
        .select(
            'sale_id, created_at, product_name, description, quantity, line_total, is_custom')
        .eq('status', 'completed')
        .gte('created_at', fromIso);

    final lowStockRes = await _client
        .from('v_low_stock')
        .select('product_name, label, sku, stock_qty, threshold')
        .order('stock_qty');

    final sales = (salesRes as List).cast<Map<String, dynamic>>();
    final items = (itemsRes as List).cast<Map<String, dynamic>>();
    final lowStock = (lowStockRes as List)
        .cast<Map<String, dynamic>>()
        .map(LowStockEntry.fromMap)
        .toList();

    final daily = <DateTime, _DailyAccumulator>{};
    for (var i = 0; i < rangeDays; i++) {
      final day = from.add(Duration(days: i));
      daily[DateTime(day.year, day.month, day.day)] = _DailyAccumulator();
    }

    var totalRevenue = 0.0;
    final payments = <String, _PaymentAccumulator>{};
    for (final sale in sales) {
      final total = ReportsData.number(sale['total']);
      totalRevenue += total;
      final method = (sale['payment_method'] as String?) ?? 'cash';
      final payment = payments.putIfAbsent(method, _PaymentAccumulator.new);
      payment.total += total;
      payment.count += 1;

      final created = _parseDate(sale['created_at']);
      if (created == null) continue;
      final key = DateTime(created.year, created.month, created.day);
      final bucket = daily[key];
      if (bucket != null) {
        bucket.total += total;
        bucket.count += 1;
      }
    }

    var itemsSold = 0;
    final products = <String, _ProductAccumulator>{};
    for (final item in items) {
      final qty = ReportsData.integer(item['quantity']);
      final revenue = ReportsData.number(item['line_total']);
      itemsSold += qty;
      final productName = (item['product_name'] as String?)?.trim();
      final description = (item['description'] as String?)?.trim();
      final isCustom = item['is_custom'] == true;
      final displayName = (productName != null && productName.isNotEmpty)
          ? productName
          : (description != null && description.isNotEmpty)
              ? description
              : 'Unnamed item';
      final bucket = products.putIfAbsent(displayName, _ProductAccumulator.new);
      bucket.quantity += qty;
      bucket.revenue += revenue;
      if (isCustom) bucket.customLines += 1;
    }

    final dailyPoints = daily.entries
        .map((e) => DailySalesPoint(
              date: e.key,
              total: e.value.total,
              salesCount: e.value.count,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final topProducts = products.entries
        .map((e) => TopProduct(
              name: e.key,
              quantity: e.value.quantity,
              revenue: e.value.revenue,
            ))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    final paymentBreakdown = payments.entries
        .map((e) => PaymentBreakdown(
              method: e.key,
              total: e.value.total,
              count: e.value.count,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final totalSales = sales.length;
    return ReportsData(
      rangeDays: rangeDays,
      from: from,
      to: today,
      totalRevenue: totalRevenue,
      totalSales: totalSales,
      itemsSold: itemsSold,
      averageSale: totalSales == 0 ? 0 : totalRevenue / totalSales,
      dailySales: dailyPoints,
      topProducts: topProducts.take(8).toList(),
      payments: paymentBreakdown,
      lowStock: lowStock,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }
}

class _DailyAccumulator {
  double total = 0;
  int count = 0;
}

class _PaymentAccumulator {
  double total = 0;
  int count = 0;
}

class _ProductAccumulator {
  int quantity = 0;
  double revenue = 0;
  int customLines = 0;
}
