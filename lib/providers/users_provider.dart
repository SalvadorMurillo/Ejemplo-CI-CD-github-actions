import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../core/constants.dart';

class UsersProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  List<User> _users = [];
  User? _selectedUser;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  UserRole? _roleFilter;
  bool? _isActiveFilter = true;
  Map<String, dynamic>? _statistics;

  // Getters
  List<User> get users => _users;
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  UserRole? get roleFilter => _roleFilter;
  bool? get isActiveFilter => _isActiveFilter;
  Map<String, dynamic>? get statistics => _statistics;

  /// Load users
  Future<void> loadUsers(User currentUser) async {
    try {
      _setLoading(true);
      _clearError();

      _users = await _userService.getUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        roleFilter: _roleFilter,
        isActive: _isActiveFilter,
        currentUser: currentUser,
      );

      notifyListeners();
    } catch (e) {
      _setError('Error al cargar usuarios: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load statistics
  Future<void> loadStatistics(User currentUser) async {
    try {
      _statistics = await _userService.getUserStatistics(
        currentUser: currentUser,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set role filter
  void setRoleFilter(UserRole? role) {
    _roleFilter = role;
    notifyListeners();
  }

  /// Set active filter
  void setIsActiveFilter(bool? isActive) {
    _isActiveFilter = isActive;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = '';
    _roleFilter = null;
    _isActiveFilter = true;
    notifyListeners();
  }

  /// Select user
  Future<void> selectUser(String userId, User currentUser) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedUser = await _userService.getUserById(userId, currentUser);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar usuario: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear selected user
  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }

  /// Create user
  Future<bool> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    required User currentUser,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final newUser = await _userService.createUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
        currentUser: currentUser,
        phoneNumber: phoneNumber,
      );

      _users.insert(0, newUser);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear usuario: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user
  Future<bool> updateUser({
    required String userId,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    bool? isActive,
    String? phoneNumber,
    required User currentUser,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedUser = await _userService.updateUser(
        userId: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        isActive: isActive,
        phoneNumber: phoneNumber,
        currentUser: currentUser,
      );

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = updatedUser;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar usuario: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete user
  Future<bool> deleteUser({
    required String userId,
    required User currentUser,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _userService.deleteUser(userId: userId, currentUser: currentUser);

      _users.removeWhere((u) => u.id == userId);

      if (_selectedUser?.id == userId) {
        _selectedUser = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar usuario: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reactivate user
  Future<bool> reactivateUser({
    required String userId,
    required User currentUser,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final reactivatedUser = await _userService.reactivateUser(
        userId: userId,
        currentUser: currentUser,
      );

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = reactivatedUser;
      } else {
        _users.insert(0, reactivatedUser);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = reactivatedUser;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al reactivar usuario: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset user password
  Future<bool> resetUserPassword({
    required String userId,
    required String newPassword,
    required User currentUser,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _userService.resetUserPassword(
        userId: userId,
        newPassword: newPassword,
        currentUser: currentUser,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al restablecer contraseña: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
