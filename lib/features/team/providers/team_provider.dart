import 'package:flutter/foundation.dart';

import '../../../data/models/profile.dart';
import '../../../data/models/user_role.dart';
import '../../../data/repositories/team_repository.dart';

class TeamProvider extends ChangeNotifier {
  TeamProvider({TeamRepository? repository})
      : _repository = repository ?? TeamRepository();

  final TeamRepository _repository;

  bool _isLoading = false;
  String? _error;
  List<Profile> _members = const [];
  final Set<String> _savingIds = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Profile> get members => _members;
  bool isSaving(String id) => _savingIds.contains(id);

  int get activeAdminCount => _members
      .where((m) => m.isActive && m.role == UserRole.admin)
      .length;

  Future<void> loadMembers({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _members = await _repository.fetchMembers();
      _error = null;
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveMember({
    required Profile member,
    required String fullName,
    required UserRole role,
    required bool isActive,
  }) async {
    _savingIds.add(member.id);
    notifyListeners();
    try {
      await _repository.updateMember(
        id: member.id,
        fullName: fullName,
        role: role,
        isActive: isActive,
      );
      await loadMembers(silent: true);
      return null;
    } catch (e) {
      return _friendly(e);
    } finally {
      _savingIds.remove(member.id);
      notifyListeners();
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('Only admins') || msg.contains('permission denied') ||
        msg.contains('row-level security')) {
      return 'Only admins can manage team members.';
    }
    if (msg.contains('Failed host lookup') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. $msg';
  }
}
