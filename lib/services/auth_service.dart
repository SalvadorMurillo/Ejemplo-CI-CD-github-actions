import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as models;
import '../core/constants.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Constructor
  AuthService() {
    _init();
  }

  void _init() {
    // Escuchar cambios de autenticación
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        _loadUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });

    // Cargar usuario actual si existe sesión
    if (Supabase.instance.client.auth.currentUser != null) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await _databaseService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      _currentUser = await _databaseService.signIn(email, password);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error de autenticación: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _databaseService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Error al cerrar sesión: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      _setLoading(true);
      _clearError();

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return true;
    } catch (e) {
      _setError('Error al cambiar contraseña: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _setError('Error al enviar email de recuperación: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool hasPermission(String module, String action) {
    if (_currentUser == null) return false;

    return RolePermissions.hasPermission(_currentUser!.role, module, action);
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
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
