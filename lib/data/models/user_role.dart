enum UserRole {
  admin,
  cashier,
  inventoryManager;

  static UserRole? fromDb(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'cashier':
        return UserRole.cashier;
      case 'inventory_manager':
        return UserRole.inventoryManager;
      default:
        return null;
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.cashier:
        return 'cashier';
      case UserRole.inventoryManager:
        return 'inventory_manager';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.inventoryManager:
        return 'Inventory Manager';
    }
  }
}
