import 'package:flutter/foundation.dart';

import '../../../data/models/cart_item.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_variant.dart';
import '../../../data/models/sale_record.dart';
import '../../../data/repositories/sales_repository.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({SalesRepository? repository})
      : _repository = repository ?? SalesRepository();

  final SalesRepository _repository;

  final List<CartItem> _items = [];
  Customer? _customer;
  double _discount = 0;
  bool _isCheckingOut = false;

  List<CartItem> get items => List.unmodifiable(_items);
  Customer? get customer => _customer;
  double get discount => _discount;
  bool get isCheckingOut => _isCheckingOut;

  double get subtotal => _items.fold(0.0, (s, i) => s + i.lineTotal);
  double get total => (subtotal - _discount).clamp(0, double.infinity);
  int get itemCount => _items.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty => _items.isEmpty;

  void setCustomer(Customer? c) {
    _customer = c;
    notifyListeners();
  }

  void setDiscount(double value) {
    _discount = value < 0 ? 0 : value;
    notifyListeners();
  }

  String? addVariant(Product product, ProductVariant variant) {
    if (!variant.isActive) return 'This variant is not active.';
    if (variant.trackStock && variant.stockQty <= 0) {
      return 'This variant is out of stock.';
    }
    final idx = _items.indexWhere((i) =>
        i.variantId == variant.id &&
        !i.isCustom &&
        i.madeToOrder == null);
    if (idx >= 0) {
      final item = _items[idx];
      if (variant.trackStock && item.quantity >= variant.stockQty) {
        return 'Only ${variant.stockQty} in stock.';
      }
      item.quantity += 1;
    } else {
      _items.add(CartItem(
        productId: product.id,
        variantId: variant.id,
        description: '${product.name} — ${variant.label}',
        quantity: 1,
        unitPrice: variant.price,
        trackStock: variant.trackStock,
        maxQty: variant.trackStock ? variant.stockQty : null,
      ));
    }
    notifyListeners();
    return null;
  }

  void addCustomItem(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void updateQuantity(int index, int qty) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      if (item.maxQty != null && qty > item.maxQty!) {
        item.quantity = item.maxQty!;
      } else {
        item.quantity = qty;
      }
    }
    notifyListeners();
  }

  void increment(int index) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    updateQuantity(index, item.quantity + 1);
  }

  void decrement(int index) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    updateQuantity(index, item.quantity - 1);
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _customer = null;
    _discount = 0;
    notifyListeners();
  }

  Future<({SaleRecord? sale, String? error})> checkout({
    required String paymentMethod,
    double? amountPaid,
    String? notes,
  }) async {
    if (_items.isEmpty) return (sale: null, error: 'Cart is empty.');
    if (paymentMethod == 'credit' && _customer == null) {
      return (sale: null, error: 'Select a customer for credit sales.');
    }
    _isCheckingOut = true;
    notifyListeners();
    try {
      final sale = await _repository.createSale(
        items: List<CartItem>.from(_items),
        customerId: _customer?.id,
        paymentMethod: paymentMethod,
        discount: _discount,
        amountPaid: amountPaid,
        notes: notes,
      );
      _items.clear();
      _customer = null;
      _discount = 0;
      return (sale: sale, error: null);
    } catch (e) {
      return (sale: null, error: _friendly(e));
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('Insufficient stock')) {
      return _extract(msg) ?? 'Insufficient stock for an item.';
    }
    if (msg.contains('Credit limit exceeded')) {
      return _extract(msg) ?? 'Credit limit exceeded for this customer.';
    }
    if (msg.contains('Credit sales require a customer')) {
      return 'Select a customer for credit sales.';
    }
    if (msg.contains('Amount paid is less')) {
      return 'Amount paid is less than the total.';
    }
    if (msg.contains('Only cashiers or admins')) {
      return 'You do not have permission to record sales.';
    }
    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return _extract(msg) ?? 'Checkout failed. $msg';
  }

  String? _extract(String msg) {
    // PostgrestException often formats as "... message: XYZ, ..."
    final m = RegExp(r'message:\s*([^,}]+)').firstMatch(msg);
    return m?.group(1)?.trim();
  }
}
