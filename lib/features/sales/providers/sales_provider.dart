import 'package:flutter/foundation.dart';

import '../../../data/models/sale_record.dart';
import '../../../data/repositories/sales_repository.dart';

class SalesProvider extends ChangeNotifier {
  SalesProvider({SalesRepository? repository})
      : _repository = repository ?? SalesRepository();

  final SalesRepository _repository;

  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;
  String? _detailError;
  List<SaleRecord> _sales = const [];
  SaleDetail? _selectedDetail;
  String? _selectedId;

  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;
  String? get detailError => _detailError;
  List<SaleRecord> get sales => _sales;
  SaleDetail? get selectedDetail => _selectedDetail;
  String? get selectedId => _selectedId;

  Future<void> loadSales({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _sales = await _repository.fetchSales();
      _error = null;
      if (_selectedId != null && _selectedDetail != null) {
        // keep detail in sync if selected still present
        final exists = _sales.any((s) => s.id == _selectedId);
        if (!exists) {
          _selectedId = null;
          _selectedDetail = null;
        }
      }
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(String saleId) async {
    _isLoadingDetail = true;
    _detailError = null;
    _selectedId = saleId;
    notifyListeners();
    try {
      _selectedDetail = await _repository.fetchSaleDetail(saleId);
      _detailError = null;
    } catch (e) {
      _detailError = _friendly(e);
      _selectedDetail = null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedId = null;
    _selectedDetail = null;
    _detailError = null;
    notifyListeners();
  }

  Future<String?> voidSale(String saleId, {String? reason}) async {
    try {
      await _repository.voidSale(saleId: saleId, reason: reason);
      await loadSales(silent: true);
      if (_selectedId == saleId) {
        await loadDetail(saleId);
      }
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('Only admins can void sales')) {
      return 'Only admins can void sales.';
    }
    if (msg.contains('Sale is already voided')) {
      return 'This sale is already voided.';
    }
    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. $msg';
  }
}
