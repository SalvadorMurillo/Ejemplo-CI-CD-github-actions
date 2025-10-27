import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as user_model;
import '../core/constants.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get all users filtered by current user's role
  /// Admin can see all users
  /// Director/Subdirector can see all users except admin
  Future<List<user_model.User>> getUsers({
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
    String? search,
    UserRole? roleFilter,
    bool? isActive,
    required user_model.User currentUser,
  }) async {
    var query = _client.from(AppConstants.usersTable).select();

    // Filter out admin users if the current user is not admin
    if (currentUser.role != UserRole.admin) {
      query = query.neq('role', UserRole.admin.name);
    }

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'first_name.ilike.%$search%,last_name.ilike.%$search%,email.ilike.%$search%',
      );
    }

    if (roleFilter != null) {
      query = query.eq('role', roleFilter.name);
    }

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((json) => user_model.User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single user by ID
  Future<user_model.User?> getUserById(
    String userId,
    user_model.User currentUser,
  ) async {
    final response = await _client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    final user = user_model.User.fromJson(response);

    // Prevent non-admin users from seeing admin users
    if (currentUser.role != UserRole.admin && user.role == UserRole.admin) {
      throw Exception('No tiene permisos para ver este usuario');
    }

    return user;
  }

  /// Create a new user using the database function
  /// Admin can create any role
  /// Director/Subdirector cannot create admin users
  Future<user_model.User> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    required user_model.User currentUser,
    String? phoneNumber,
  }) async {
    // Validate permissions on client side (also validated in DB function)
    if (currentUser.role != UserRole.admin) {
      if (role == UserRole.admin) {
        throw Exception(
          'No tiene permisos para crear usuarios administradores',
        );
      }
      if (currentUser.role != UserRole.director &&
          currentUser.role != UserRole.subdirector) {
        throw Exception('No tiene permisos para crear usuarios');
      }
    }

    try {
      // Call the database function to create the user
      final response = await _client.rpc(
        'create_app_user',
        params: {
          'p_email': email,
          'p_password': password,
          'p_first_name': firstName,
          'p_last_name': lastName,
          'p_role': role.name,
          'p_phone_number': phoneNumber,
        },
      );

      // The function returns JSON, convert it to User model
      return user_model.User.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // Handle Postgres-specific errors
      throw Exception('Error al crear usuario: ${e.message}');
    } catch (e) {
      throw Exception('Error al crear usuario: ${e.toString()}');
    }
  }

  /// Update an existing user
  /// Admin can update any user
  /// Director/Subdirector cannot update admin users
  Future<user_model.User> updateUser({
    required String userId,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    bool? isActive,
    String? phoneNumber,
    required user_model.User currentUser,
  }) async {
    // Get the user to update
    final existingUser = await getUserById(userId, currentUser);
    if (existingUser == null) {
      throw Exception('Usuario no encontrado');
    }

    // Prevent non-admin from updating admin users
    if (currentUser.role != UserRole.admin &&
        existingUser.role == UserRole.admin) {
      throw Exception(
        'No tiene permisos para modificar usuarios administradores',
      );
    }

    // Prevent non-admin from changing role to admin
    if (currentUser.role != UserRole.admin && role == UserRole.admin) {
      throw Exception('No tiene permisos para asignar el rol de administrador');
    }

    // Prevent users from deactivating themselves
    if (userId == currentUser.id && isActive == false) {
      throw Exception('No puede desactivarse a sí mismo');
    }

    // Build update data
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': currentUser.id,
    };

    if (email != null) updateData['email'] = email;
    if (firstName != null) updateData['first_name'] = firstName;
    if (lastName != null) updateData['last_name'] = lastName;
    if (role != null) updateData['role'] = role.name;
    if (isActive != null) updateData['is_active'] = isActive;
    if (phoneNumber != null) updateData['phone_number'] = phoneNumber;

    // Update user
    final response = await _client
        .from(AppConstants.usersTable)
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

    // Log the action
    await _logAudit(
      action: 'UPDATE',
      tableName: AppConstants.usersTable,
      recordId: userId,
      oldValues: existingUser.toJson(),
      newValues: updateData,
    );

    return user_model.User.fromJson(response);
  }

  /// Delete (deactivate) a user
  /// Admin can delete any user
  /// Director/Subdirector cannot delete admin users
  Future<void> deleteUser({
    required String userId,
    required user_model.User currentUser,
  }) async {
    // Get the user to delete
    final existingUser = await getUserById(userId, currentUser);
    if (existingUser == null) {
      throw Exception('Usuario no encontrado');
    }

    // Prevent non-admin from deleting admin users
    if (currentUser.role != UserRole.admin &&
        existingUser.role == UserRole.admin) {
      throw Exception(
        'No tiene permisos para eliminar usuarios administradores',
      );
    }

    // Prevent users from deleting themselves
    if (userId == currentUser.id) {
      throw Exception('No puede eliminarse a sí mismo');
    }

    // Soft delete (deactivate)
    await _client
        .from(AppConstants.usersTable)
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': currentUser.id,
        })
        .eq('id', userId);

    // Log the action
    await _logAudit(
      action: 'DELETE',
      tableName: AppConstants.usersTable,
      recordId: userId,
      oldValues: existingUser.toJson(),
    );
  }

  /// Reactivate a deactivated user
  Future<user_model.User> reactivateUser({
    required String userId,
    required user_model.User currentUser,
  }) async {
    // Get the user to reactivate
    final existingUser = await _client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existingUser == null) {
      throw Exception('Usuario no encontrado');
    }

    final user = user_model.User.fromJson(existingUser);

    // Prevent non-admin from reactivating admin users
    if (currentUser.role != UserRole.admin && user.role == UserRole.admin) {
      throw Exception(
        'No tiene permisos para reactivar usuarios administradores',
      );
    }

    // Reactivate
    final response = await _client
        .from(AppConstants.usersTable)
        .update({
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': currentUser.id,
        })
        .eq('id', userId)
        .select()
        .single();

    // Log the action
    await _logAudit(
      action: 'UPDATE',
      tableName: AppConstants.usersTable,
      recordId: userId,
      oldValues: user.toJson(),
      newValues: {'is_active': true},
    );

    return user_model.User.fromJson(response);
  }

  /// Reset user password using database function
  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
    required user_model.User currentUser,
  }) async {
    // Get the user
    final existingUser = await getUserById(userId, currentUser);
    if (existingUser == null) {
      throw Exception('Usuario no encontrado');
    }

    // Prevent non-admin from resetting admin passwords
    if (currentUser.role != UserRole.admin &&
        existingUser.role == UserRole.admin) {
      throw Exception(
        'No tiene permisos para cambiar la contraseña de administradores',
      );
    }

    try {
      // Call the database function to reset password
      await _client.rpc(
        'reset_user_password',
        params: {'p_user_id': userId, 'p_new_password': newPassword},
      );

      // Log the action
      await _logAudit(
        action: 'UPDATE',
        tableName: AppConstants.usersTable,
        recordId: userId,
        newValues: {'password': '***RESET***'},
      );
    } catch (e) {
      throw Exception('Error al restablecer contraseña: ${e.toString()}');
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics({
    required user_model.User currentUser,
  }) async {
    var query = _client.from(AppConstants.usersTable).select('role, is_active');

    // Filter out admin users if the current user is not admin
    if (currentUser.role != UserRole.admin) {
      query = query.neq('role', UserRole.admin.name);
    }

    final response = await query;
    final users = response as List<dynamic>;

    final totalUsers = users.length;
    final activeUsers = users.where((u) => u['is_active'] == true).length;
    final inactiveUsers = totalUsers - activeUsers;

    // Count by role
    final roleCount = <String, int>{};
    for (final user in users) {
      final role = user['role'] as String;
      roleCount[role] = (roleCount[role] ?? 0) + 1;
    }

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': inactiveUsers,
      'roleCount': roleCount,
    };
  }

  Future<void> _logAudit({
    required String action,
    required String tableName,
    required String recordId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      await _client.from(AppConstants.auditLogsTable).insert({
        'table_name': tableName,
        'record_id': recordId,
        'action': action,
        'old_values': oldValues,
        'new_values': newValues,
        'user_id': currentUser.id,
        'user_email': currentUser.email,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't fail the main operation
      print('Error logging audit: $e');
    }
  }
}
