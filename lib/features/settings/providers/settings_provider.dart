import 'package:flutter/foundation.dart';

import '../../../data/models/store_settings.dart';
import '../../../data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  StoreSettings? _settings;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  StoreSettings? get settings => _settings;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _settings = await _repository.fetchSettings();
      _error = null;
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save(StoreSettings settings) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.saveSettings(settings);
      _settings = settings;
      _error = null;
      return null;
    } catch (e) {
      return _friendly(e);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('Only admins') || msg.contains('permission denied') ||
        msg.contains('row-level security')) {
      return 'Only admins can update store settings.';
    }
    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. $msg';
  }
}
