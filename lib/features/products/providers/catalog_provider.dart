import 'package:flutter/foundation.dart' hide Category;

import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_variant.dart';
import '../../../data/repositories/catalog_repository.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider({CatalogRepository? repository})
      : _repository = repository ?? CatalogRepository();

  final CatalogRepository _repository;

  bool _isLoading = false;
  String? _error;
  List<Category> _categories = const [];
  List<Product> _products = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Category> get categories => _categories;
  List<Product> get products => _products;

  Future<void> loadAll({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        _repository.fetchCategories(),
        _repository.fetchProducts(),
      ]);
      _categories = results[0] as List<Category>;
      _products = results[1] as List<Product>;
      _error = null;
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveCategory({
    String? id,
    required String name,
    String? description,
  }) async {
    try {
      await _repository.saveCategory(id: id, name: name, description: description);
      await loadAll(silent: true);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      await loadAll(silent: true);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> saveProduct({
    String? id,
    required String name,
    required String sku,
    String? categoryId,
    String? description,
    required double basePrice,
    required bool isMadeToOrder,
    required int lowStockThreshold,
    String? imageUrl,
    required bool isActive,
    required List<VariantDraft> variants,
    required List<String> deletedVariantIds,
  }) async {
    try {
      final productId = await _repository.saveProduct(
        id: id,
        name: name,
        sku: sku,
        categoryId: categoryId,
        description: description,
        basePrice: basePrice,
        isMadeToOrder: isMadeToOrder,
        lowStockThreshold: lowStockThreshold,
        imageUrl: imageUrl,
        isActive: isActive,
      );
      for (final vid in deletedVariantIds) {
        await _repository.deleteVariant(vid);
      }
      for (final v in variants) {
        await _repository.saveVariant(productId, v);
      }
      await loadAll(silent: true);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadAll(silent: true);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('duplicate key') || msg.contains('unique constraint')) {
      return 'A record with the same SKU or name already exists.';
    }
    if (msg.contains('violates foreign key') || msg.contains('23503')) {
      return 'Cannot delete: this record is still in use.';
    }
    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. $msg';
  }
}
