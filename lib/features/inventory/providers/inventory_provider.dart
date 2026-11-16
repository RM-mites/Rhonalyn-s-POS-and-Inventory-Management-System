import 'package:flutter/foundation.dart';

import '../../../data/models/inventory_item.dart';
import '../../../data/models/stock_movement.dart';
import '../../../data/repositories/inventory_repository.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider({InventoryRepository? repository})
      : _repository = repository ?? InventoryRepository();

  final InventoryRepository _repository;

  bool _isLoading = false;
  bool _isLoadingMovements = false;
  String? _error;
  String? _movementsError;
  List<InventoryItem> _items = const [];
  List<StockMovement> _movements = const [];
  String? _movementVariantFilter;

  bool get isLoading => _isLoading;
  bool get isLoadingMovements => _isLoadingMovements;
  String? get error => _error;
  String? get movementsError => _movementsError;
  List<InventoryItem> get items => _items;
  List<StockMovement> get movements => _movements;
  String? get movementVariantFilter => _movementVariantFilter;

  int get lowStockCount => _items.where((i) => i.isLowStock).length;

  Future<void> loadAll({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _items = await _repository.fetchInventoryItems();
      _error = null;
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMovements({String? variantId}) async {
    _isLoadingMovements = true;
    _movementsError = null;
    _movementVariantFilter = variantId;
    notifyListeners();
    try {
      _movements = await _repository.fetchMovements(variantId: variantId);
      _movementsError = null;
    } catch (e) {
      _movementsError = _friendly(e);
    } finally {
      _isLoadingMovements = false;
      notifyListeners();
    }
  }

  Future<String?> adjustStock({
    required String variantId,
    required int quantityChange,
    String? notes,
    String movementType = 'adjustment',
  }) async {
    try {
      await _repository.adjustStock(
        variantId: variantId,
        quantityChange: quantityChange,
        notes: notes,
        movementType: movementType,
      );
      await Future.wait([
        loadAll(silent: true),
        loadMovements(variantId: _movementVariantFilter),
      ]);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('Stock cannot go below zero')) {
      return 'Stock cannot go below zero.';
    }
    if (msg.contains('Only inventory managers or admins')) {
      return 'You do not have permission to adjust stock.';
    }
    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. $msg';
  }
}
