import 'package:flutter_test/flutter_test.dart';
import 'package:rhonalyns_pos_inventory/data/models/profile.dart';
import 'package:rhonalyns_pos_inventory/data/models/user_role.dart';

void main() {
  group('UserRole', () {
    test('parses database values', () {
      expect(UserRole.fromDb('admin'), UserRole.admin);
      expect(UserRole.fromDb('cashier'), UserRole.cashier);
      expect(UserRole.fromDb('inventory_manager'), UserRole.inventoryManager);
      expect(UserRole.fromDb('unknown'), isNull);
    });

    test('exposes db and label values', () {
      expect(UserRole.inventoryManager.dbValue, 'inventory_manager');
      expect(UserRole.admin.label, 'Admin');
    });
  });

  group('Profile', () {
    test('fromMap parses a valid profile', () {
      final profile = Profile.fromMap({
        'id': 'u1',
        'full_name': ' Maria Santos ',
        'role': 'cashier',
        'is_active': true,
      });
      expect(profile.id, 'u1');
      expect(profile.displayName, 'Maria Santos');
      expect(profile.role, UserRole.cashier);
      expect(profile.isActive, isTrue);
    });

    test('fromMap falls back for missing name', () {
      final profile = Profile.fromMap({
        'id': 'u2',
        'full_name': null,
        'role': 'admin',
        'is_active': false,
      });
      expect(profile.displayName, 'User');
      expect(profile.isActive, isFalse);
    });

    test('fromMap throws on invalid role', () {
      expect(
        () => Profile.fromMap({'id': 'u3', 'role': 'nope'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
