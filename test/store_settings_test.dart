import 'package:flutter_test/flutter_test.dart';
import 'package:rhonalyns_pos_inventory/data/models/store_settings.dart';

void main() {
  group('StoreSettings', () {
    test('fromMap parses and trims values', () {
      final settings = StoreSettings.fromMap({
        'store_name': '  Rhonalyn Furniture  ',
        'address': '  Manila  ',
        'contact': '0917 000 0000',
        'receipt_footer': null,
        'default_low_stock_threshold': 3,
      });

      expect(settings.storeName, 'Rhonalyn Furniture');
      expect(settings.address, 'Manila');
      expect(settings.contact, '0917 000 0000');
      expect(settings.receiptFooter, isNull);
      expect(settings.defaultLowStockThreshold, 3);
    });

    test('fromMap falls back for missing required values', () {
      final settings = StoreSettings.fromMap({});

      expect(settings.storeName, StoreSettings.defaults.storeName);
      expect(
        settings.defaultLowStockThreshold,
        StoreSettings.defaults.defaultLowStockThreshold,
      );
    });

    test('toUpdateMap converts blank optional values to null', () {
      const settings = StoreSettings(
        storeName: '  ',
        address: '  ',
        contact: '',
        receiptFooter: ' Salamat! ',
        defaultLowStockThreshold: 0,
      );

      final map = settings.toUpdateMap();
      expect(map['store_name'], StoreSettings.defaults.storeName);
      expect(map['address'], isNull);
      expect(map['contact'], isNull);
      expect(map['receipt_footer'], 'Salamat!');
      expect(map['default_low_stock_threshold'], 0);
    });
  });
}
