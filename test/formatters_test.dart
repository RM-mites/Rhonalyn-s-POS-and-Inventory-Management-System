import 'package:flutter_test/flutter_test.dart';
import 'package:rhonalyns_pos_inventory/core/utils/formatters.dart';

void main() {
  group('formatPeso', () {
    test('formats whole and decimal amounts with separators', () {
      expect(formatPeso(1234.5), contains('1,234.50'));
      expect(formatPeso(0), contains('0.00'));
    });
  });

  group('tryParseAmount', () {
    test('strips currency symbols and separators', () {
      expect(tryParseAmount('₱1,250.75'), 1250.75);
    });

    test('returns null for blank input', () {
      expect(tryParseAmount('   '), isNull);
    });
  });

  group('nullIfBlank', () {
    test('returns null for whitespace-only values', () {
      expect(nullIfBlank('   '), isNull);
      expect(nullIfBlank(' note '), 'note');
    });
  });
}
