import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/profile.dart';
import '../../../data/repositories/auth_repository.dart';

enum AuthStatus { loading, signedOut, signedIn, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _init();
  }

  final AuthRepository _repository;
  StreamSubscription<AuthState>? _authSub;

  AuthStatus _status = AuthStatus.loading;
  Profile? _profile;
  String? _errorMessage;
  bool _isWorking = false;

  AuthStatus get status => _status;
  Profile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isWorking => _isWorking;
  bool get isSignedIn => _status == AuthStatus.signedIn && _profile != null;
  Session? get session => _repository.currentSession;

  Future<void> _init() async {
    try {
      await _loadProfileForCurrentSession();
    } catch (e) {
      _setError(_friendlyMessage(e));
    }
    _authSub = _repository.authStateChanges.listen((event) async {
      final type = event.event;
      if (type == AuthChangeEvent.signedOut) {
        _profile = null;
        _errorMessage = null;
        _status = AuthStatus.signedOut;
        notifyListeners();
        return;
      }
      if (type == AuthChangeEvent.signedIn ||
          type == AuthChangeEvent.tokenRefreshed ||
          type == AuthChangeEvent.initialSession ||
          type == AuthChangeEvent.userUpdated) {
        try {
          await _loadProfileForCurrentSession();
        } catch (e) {
          _setError(_friendlyMessage(e));
        }
      }
    });
  }

  Future<void> _loadProfileForCurrentSession() async {
    final user = _repository.currentUser;
    if (user == null) {
      _profile = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    final profile = await _repository.fetchProfile(user.id);
    if (profile == null) {
      await _repository.signOut();
      _profile = null;
      _status = AuthStatus.error;
      _errorMessage =
          'No profile was found for this account. Contact an administrator.';
      notifyListeners();
      return;
    }
    if (!profile.isActive) {
      await _repository.signOut();
      _profile = null;
      _status = AuthStatus.error;
      _errorMessage = 'This account is inactive. Contact an administrator.';
      notifyListeners();
      return;
    }
    _profile = profile;
    _errorMessage = null;
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.signIn(email.trim(), password);
      await _loadProfileForCurrentSession();
      if (_status == AuthStatus.error) return _errorMessage;
      return null;
    } on AuthException catch (e) {
      final msg = _friendlyAuthMessage(e);
      _errorMessage = msg;
      _status = _repository.currentUser == null
          ? AuthStatus.signedOut
          : AuthStatus.error;
      notifyListeners();
      return msg;
    } catch (e) {
      final msg = _friendlyMessage(e);
      _setError(msg);
      return msg;
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      await _loadProfileForCurrentSession();
    } catch (e) {
      _setError(_friendlyMessage(e));
    }
  }

  Future<void> signOut() async {
    _isWorking = true;
    notifyListeners();
    try {
      await _repository.signOut();
    } finally {
      _profile = null;
      _status = AuthStatus.signedOut;
      _errorMessage = null;
      _isWorking = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error && _repository.currentUser == null) {
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  String _friendlyAuthMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    return e.message;
  }

  String _friendlyMessage(Object e) {
    final text = e.toString();
    if (text.contains('Failed host lookup') ||
        text.contains('SocketException') ||
        text.contains('ClientException')) {
      return 'Could not reach Supabase. Check your internet connection and .env settings.';
    }
    return 'Something went wrong. $text';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
