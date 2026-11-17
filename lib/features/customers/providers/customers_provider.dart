import 'package:flutter/foundation.dart';

import '../../../data/models/credit_payment.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customers_repository.dart';

class CustomersProvider extends ChangeNotifier {
  CustomersProvider({CustomersRepository? repository})
      : _repository = repository ?? CustomersRepository();

  final CustomersRepository _repository;

  bool _isLoading = false;
  bool _isLoadingPayments = false;
  String? _error;
  String? _paymentsError;
  List<Customer> _customers = const [];
  List<CreditPayment> _payments = const [];
  String? _paymentsCustomerId;

  bool get isLoading => _isLoading;
  bool get isLoadingPayments => _isLoadingPayments;
  String? get error => _error;
  String? get paymentsError => _paymentsError;
  List<Customer> get customers => _customers;
  List<CreditPayment> get payments => _payments;
  String? get paymentsCustomerId => _paymentsCustomerId;

  Future<void> loadCustomers({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _customers = await _repository.fetchCustomers();
      _error = null;
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPayments(String customerId) async {
    _isLoadingPayments = true;
    _paymentsError = null;
    _paymentsCustomerId = customerId;
    notifyListeners();
    try {
      _payments = await _repository.fetchPayments(customerId);
      _paymentsError = null;
    } catch (e) {
      _paymentsError = _friendly(e);
    } finally {
      _isLoadingPayments = false;
      notifyListeners();
    }
  }

  void clearPayments() {
    _payments = const [];
    _paymentsCustomerId = null;
    _paymentsError = null;
    notifyListeners();
  }

  Future<String?> saveCustomer({
    String? id,
    required String name,
    String? phone,
    String? email,
    String? address,
    required double creditLimit,
    String? notes,
    required bool isActive,
  }) async {
    try {
      await _repository.saveCustomer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        creditLimit: creditLimit,
        notes: notes,
        isActive: isActive,
      );
      await loadCustomers(silent: true);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
      if (_paymentsCustomerId == id) clearPayments();
      await loadCustomers(silent: true);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> recordPayment({
    required String customerId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    try {
      await _repository.recordPayment(
        customerId: customerId,
        amount: amount,
        method: method,
        notes: notes,
      );
      await loadCustomers(silent: true);
      if (_paymentsCustomerId == customerId) {
        await loadPayments(customerId);
      }
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('Payment exceeds outstanding balance')) {
      return 'Payment exceeds the outstanding balance.';
    }
    if (msg.contains('Only cashiers or admins')) {
      return 'You do not have permission to record payments.';
    }
    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. $msg';
  }
}
