import 'package:flutter/foundation.dart';

import '../../../data/models/reports_data.dart';
import '../../../data/repositories/reports_repository.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider({ReportsRepository? repository})
      : _repository = repository ?? ReportsRepository();

  final ReportsRepository _repository;

  int _rangeDays = 30;
  bool _isLoading = false;
  String? _error;
  ReportsData? _data;

  int get rangeDays => _rangeDays;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ReportsData? get data => _data;

  Future<void> load({int? rangeDays, bool silent = false}) async {
    if (rangeDays != null) _rangeDays = rangeDays;
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _data = await _repository.fetchReports(rangeDays: _rangeDays);
      _error = null;
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setRange(int days) {
    if (days == _rangeDays && _data != null && !_isLoading) {
      return Future.value();
    }
    return load(rangeDays: days);
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    if (msg.contains('permission denied') || msg.contains('row-level security')) {
      return 'You do not have permission to view reports.';
    }
    return 'Something went wrong. $msg';
  }
}
