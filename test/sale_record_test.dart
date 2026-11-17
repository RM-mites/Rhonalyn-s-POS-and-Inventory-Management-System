import 'package:flutter_test/flutter_test.dart';
import 'package:rhonalyns_pos_inventory/data/models/cart_item.dart';
import 'package:rhonalyns_pos_inventory/data/models/sale_record.dart';

void main() {
  group('CartItem', () {
    test('computes line totals', () {
      final item = CartItem(
        description: 'Oak Chair',
        quantity: 3,
        unitPrice: 2500,
      );
      expect(item.lineTotal, 7500);
    });

    test('builds a sale item payload with made-to-order details', () {
      final item = CartItem(
        description: 'Custom Wardrobe',
        quantity: 1,
        unitPrice: 30000,
        isCustom: true,
        trackStock: false,
        customSpecs: {'finish': 'Walnut'},
        madeToOrder: MadeToOrderInfo(
          targetPrice: 30000,
          depositAmount: 10000,
          dueDate: DateTime(2026, 12, 1),
          deliveryAddress: 'Quezon City',
        ),
      );

      final payload = item.toSaleItem();
      expect(payload['is_custom'], isTrue);
      expect(payload['track_stock'], isFalse);
      expect(payload['custom_specs'], {'finish': 'Walnut'});

      final mto = payload['made_to_order'] as Map<String, dynamic>;
      expect(mto['target_price'], 30000);
      expect(mto['deposit_amount'], 10000);
      expect(mto['due_date'], '2026-12-01');
    });

    test('made-to-order balance never goes negative', () {
      final zero = MadeToOrderInfo(targetPrice: 1000, depositAmount: 1500);
      final partlyPaid =
          MadeToOrderInfo(targetPrice: 1000, depositAmount: 400);
      expect(zero.balanceDue, 0);
      expect(partlyPaid.balanceDue, 600);
    });
  });

  group('SaleRecord', () {
    test('fromMap parses numbers stored as strings and nested names', () {
      final sale = SaleRecord.fromMap({
        'id': 's1',
        'receipt_no': 'R-1',
        'subtotal': '1000.50',
        'discount': 50,
        'total': '950.50',
        'amount_paid': '1000',
        'change_due': '49.50',
        'payment_method': 'cash',
        'status': 'completed',
        'created_at': '2026-11-17T10:00:00Z',
        'customers': {'name': 'Maria Santos'},
        'cashier': {'full_name': 'Admin User'},
      });

      expect(sale.subtotal, 1000.50);
      expect(sale.total, 950.50);
      expect(sale.changeDue, 49.50);
      expect(sale.customerName, 'Maria Santos');
      expect(sale.cashierName, 'Admin User');
      expect(sale.createdAt, DateTime.utc(2026, 11, 17, 10));
      expect(sale.isVoided, isFalse);
    });

    test('fromMap falls back for missing optional fields', () {
      final sale = SaleRecord.fromMap({'id': 's2'});
      expect(sale.receiptNo, '');
      expect(sale.paymentMethod, 'cash');
      expect(sale.status, 'completed');
      expect(sale.subtotal, 0);
    });

    test('fromMap marks voided sales', () {
      final sale = SaleRecord.fromMap({
        'id': 's3',
        'status': 'voided',
        'voided_at': '2026-11-17T11:00:00Z',
      });
      expect(sale.isVoided, isTrue);
      expect(sale.voidedAt, DateTime.utc(2026, 11, 17, 11));
    });
  });

  group('SaleLineDetail', () {
    test('fromMap parses quantities, totals, and custom specs', () {
      final line = SaleLineDetail.fromMap({
        'id': 'l1',
        'description': 'Custom Chair',
        'quantity': '2',
        'unit_price': '1500',
        'line_total': '3000',
        'is_custom': true,
        'custom_specs': {'color': 'Red'},
        'product_name': 'Chair',
        'category_name': 'Seating',
        'variant_label': 'Custom',
      });

      expect(line.quantity, 2);
      expect(line.unitPrice, 1500);
      expect(line.lineTotal, 3000);
      expect(line.isCustom, isTrue);
      expect(line.customSpecs, {'color': 'Red'});
      expect(line.categoryName, 'Seating');
    });
  });

  group('MadeToOrderJobDetail', () {
    test('fromMap parses prices and due date', () {
      final job = MadeToOrderJobDetail.fromMap({
        'id': 'j1',
        'target_price': '30000',
        'deposit_amount': 10000,
        'balance_due': '20000',
        'due_date': '2026-12-01',
        'specs': {'finish': 'Walnut'},
      });

      expect(job.targetPrice, 30000);
      expect(job.depositAmount, 10000);
      expect(job.balanceDue, 20000);
      expect(job.dueDate, DateTime(2026, 12, 1));
      expect(job.specs, {'finish': 'Walnut'});
    });
  });
}
