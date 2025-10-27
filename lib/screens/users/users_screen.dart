import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/users_provider.dart';
import '../../services/auth_service.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../../widgets/adaptive_navigation.dart';
import 'widgets/user_form_dialog.dart';
import 'widgets/user_details_dialog.dart';
import 'widgets/password_reset_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authService = context.read<AuthService>();
    final usersProvider = context.read<UsersProvider>();

    if (authService.currentUser != null) {
      usersProvider.loadUsers(authService.currentUser!);
      usersProvider.loadStatistics(authService.currentUser!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel the previous timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Create a new timer that will trigger search after 500ms of inactivity
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final authService = context.read<AuthService>();
      final usersProvider = context.read<UsersProvider>();

      if (authService.currentUser != null) {
        usersProvider.setSearchQuery(query);
        usersProvider.loadUsers(authService.currentUser!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final usersProvider = context.watch<UsersProvider>();
    final currentUser = authService.currentUser;

    // Check permissions - only admin, director, and subdirector can access
    if (currentUser == null ||
        (currentUser.role != UserRole.admin &&
            currentUser.role != UserRole.director &&
            currentUser.role != UserRole.subdirector)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Usuarios')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Acceso Denegado',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'No tiene permisos para acceder a este módulo',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final appBarWidget = AppBar(
      title: const Text('Gestión de Usuarios'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Actualizar',
        ),
      ],
    );

    final bodyWidget = SingleChildScrollView(
      child: Column(
        children: [
          // Statistics cards
          if (usersProvider.statistics != null)
            _buildStatisticsCards(usersProvider.statistics!),

          // Search and filters
          _buildSearchAndFilters(usersProvider, currentUser),

          // Users list
          usersProvider.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : usersProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          usersProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            usersProvider.clearError();
                            _loadData();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : usersProvider.users.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay usuarios',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildUsersList(usersProvider, currentUser),
        ],
      ),
    );

    final fabWidget = FloatingActionButton.extended(
      onPressed: () => _showUserFormDialog(context, currentUser),
      icon: const Icon(Icons.person_add),
      label: const Text('Nuevo Usuario'),
    );

    return AdaptiveNavigationScaffold(
      currentRoute: AppConstants.usersRoute,
      appBar: appBarWidget,
      body: bodyWidget,
      floatingActionButton: fabWidget,
    );
  }

  Widget _buildStatisticsCards(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          // Both mobile and desktop use the same horizontal row layout
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['totalUsers'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  'Activos',
                  stats['activeUsers'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  'Inactivos',
                  stats['inactiveUsers'].toString(),
                  Icons.cancel,
                  Colors.orange,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 24 : 32),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: isSmallScreen ? 11 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(UsersProvider provider, User currentUser) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            // Filters row - responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;

                if (isSmallScreen) {
                  // Mobile layout - stacked vertically
                  return Column(
                    children: [
                      // Role filter
                      DropdownButtonFormField<UserRole?>(
                        initialValue: provider.roleFilter,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos'),
                          ),
                          // Show all roles except admin if user is not admin
                          ...UserRole.values
                              .where(
                                (role) =>
                                    currentUser.role == UserRole.admin ||
                                    role != UserRole.admin,
                              )
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.displayName),
                                ),
                              ),
                        ],
                        onChanged: (value) {
                          provider.setRoleFilter(value);
                          provider.loadUsers(currentUser);
                        },
                      ),
                      const SizedBox(height: 12),
                      // Status filter
                      DropdownButtonFormField<bool?>(
                        initialValue: provider.isActiveFilter,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: true, child: Text('Activos')),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Inactivos'),
                          ),
                        ],
                        onChanged: (value) {
                          provider.setIsActiveFilter(value);
                          provider.loadUsers(currentUser);
                        },
                      ),
                      const SizedBox(height: 12),
                      // Clear filters button - full width on mobile
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            provider.clearFilters();
                            provider.loadUsers(currentUser);
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Limpiar Filtros'),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Desktop/Tablet layout - horizontal
                  return Row(
                    children: [
                      // Role filter
                      Expanded(
                        child: DropdownButtonFormField<UserRole?>(
                          initialValue: provider.roleFilter,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            // Show all roles except admin if user is not admin
                            ...UserRole.values
                                .where(
                                  (role) =>
                                      currentUser.role == UserRole.admin ||
                                      role != UserRole.admin,
                                )
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role.displayName),
                                  ),
                                ),
                          ],
                          onChanged: (value) {
                            provider.setRoleFilter(value);
                            provider.loadUsers(currentUser);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status filter
                      Expanded(
                        child: DropdownButtonFormField<bool?>(
                          initialValue: provider.isActiveFilter,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Activos'),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text('Inactivos'),
                            ),
                          ],
                          onChanged: (value) {
                            provider.setIsActiveFilter(value);
                            provider.loadUsers(currentUser);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Clear filters button
                      ElevatedButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          provider.clearFilters();
                          provider.loadUsers(currentUser);
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Limpiar'),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(UsersProvider provider, User currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...provider.users.map((user) => _buildUserCard(user, currentUser)),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildUserCard(User user, User currentUser) {
    final isCurrentUser = user.id == currentUser.id;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: isSmallScreen
          ? _buildMobileUserCard(user, currentUser, isCurrentUser)
          : _buildDesktopUserCard(user, currentUser, isCurrentUser),
    );
  }

  Widget _buildMobileUserCard(User user, User currentUser, bool isCurrentUser) {
    return InkWell(
      onTap: () => _showUserDetailsDialog(context, user, currentUser),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with avatar, name, and menu
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.isActive ? Colors.green : Colors.grey,
                  radius: 24,
                  child: Text(
                    user.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: user.isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleUserAction(value, user, currentUser),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 8),
                          Text('Ver detalles'),
                        ],
                      ),
                    ),
                    if (user.isActive) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'password',
                        child: Row(
                          children: [
                            Icon(Icons.lock_reset, size: 20),
                            SizedBox(width: 8),
                            Text('Restablecer contraseña'),
                          ],
                        ),
                      ),
                      if (!isCurrentUser)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Desactivar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ] else ...[
                      const PopupMenuItem(
                        value: 'reactivate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Reactivar',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Chips row - wrapped for mobile
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    user.role.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRoleTextColor(user.role),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: _getRoleColor(user.role),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isActive
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.green[100]!
                                : Colors.green[900]!)
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[300]!
                                : Colors.grey[800]!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: user.isActive
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[800]!
                            : Colors.green[100]!)
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (isCurrentUser)
                  Chip(
                    label: Text('Tú', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue,
                    // make label color respect current theme's onPrimary color
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopUserCard(
    User user,
    User currentUser,
    bool isCurrentUser,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.isActive ? Colors.green : Colors.grey,
        child: Text(
          user.firstName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        user.fullName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: user.isActive ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          const SizedBox(height: 4),
          Row(
            children: [
              Chip(
                label: Text(
                  user.role.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRoleTextColor(user.role),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: _getRoleColor(user.role),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  user.isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 12,
                    color: user.isActive
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[100]!
                              : Colors.green[900]!)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]!
                              : Colors.grey[800]!),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: user.isActive
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.green[800]!
                          : Colors.green[100]!)
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[300]!),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text('Tú', style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue,
                  // make label color respect current theme's onPrimary color
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleUserAction(value, user, currentUser),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 8),
                Text('Ver detalles'),
              ],
            ),
          ),
          if (user.isActive) ...[
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'password',
              child: Row(
                children: [
                  Icon(Icons.lock_reset, size: 20),
                  SizedBox(width: 8),
                  Text('Restablecer contraseña'),
                ],
              ),
            ),
            if (!isCurrentUser)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Desactivar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ] else ...[
            const PopupMenuItem(
              value: 'reactivate',
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Reactivar', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ],
        ],
      ),
      onTap: () => _showUserDetailsDialog(context, user, currentUser),
    );
  }

  Color _getRoleColor(UserRole role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (role) {
      case UserRole.admin:
        return isDark ? Colors.red[800]! : Colors.red[100]!;
      case UserRole.director:
        return isDark ? Colors.purple[800]! : Colors.purple[100]!;
      case UserRole.subdirector:
        return isDark ? Colors.deepPurple[800]! : Colors.deepPurple[100]!;
      case UserRole.socialWorker:
        return isDark ? Colors.blue[800]! : Colors.blue[100]!;
      case UserRole.prefect:
        return isDark ? Colors.cyan[800]! : Colors.cyan[100]!;
      case UserRole.counselor:
        return isDark ? Colors.teal[800]! : Colors.teal[100]!;
      case UserRole.usaer:
        return isDark ? Colors.green[800]! : Colors.green[100]!;
      case UserRole.academicCoordinator:
        return isDark ? Colors.amber[800]! : Colors.amber[100]!;
      case UserRole.medico:
        return isDark ? Colors.pink[800]! : Colors.pink[100]!;
      case UserRole.docente:
        return isDark ? Colors.orange[800]! : Colors.orange[100]!;
    }
  }

  Color _getRoleTextColor(UserRole role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (role) {
      case UserRole.admin:
        return isDark ? Colors.red[100]! : Colors.red[900]!;
      case UserRole.director:
        return isDark ? Colors.purple[100]! : Colors.purple[900]!;
      case UserRole.subdirector:
        return isDark ? Colors.deepPurple[100]! : Colors.deepPurple[900]!;
      case UserRole.socialWorker:
        return isDark ? Colors.blue[100]! : Colors.blue[900]!;
      case UserRole.prefect:
        return isDark ? Colors.cyan[100]! : Colors.cyan[900]!;
      case UserRole.counselor:
        return isDark ? Colors.teal[100]! : Colors.teal[900]!;
      case UserRole.usaer:
        return isDark ? Colors.green[100]! : Colors.green[900]!;
      case UserRole.academicCoordinator:
        return isDark ? Colors.amber[100]! : Colors.amber[900]!;
      case UserRole.medico:
        return isDark ? Colors.pink[100]! : Colors.pink[900]!;
      case UserRole.docente:
        return isDark ? Colors.orange[100]! : Colors.orange[900]!;
    }
  }

  void _handleUserAction(String action, User user, User currentUser) {
    switch (action) {
      case 'view':
        _showUserDetailsDialog(context, user, currentUser);
        break;
      case 'edit':
        _showUserFormDialog(context, currentUser, userToEdit: user);
        break;
      case 'password':
        _showPasswordResetDialog(context, user, currentUser);
        break;
      case 'delete':
        _confirmDeleteUser(context, user, currentUser);
        break;
      case 'reactivate':
        _confirmReactivateUser(context, user, currentUser);
        break;
    }
  }

  void _showUserFormDialog(
    BuildContext context,
    User currentUser, {
    User? userToEdit,
  }) {
    showDialog(
      context: context,
      builder: (context) =>
          UserFormDialog(currentUser: currentUser, userToEdit: userToEdit),
    );
  }

  void _showUserDetailsDialog(
    BuildContext context,
    User user,
    User currentUser,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          UserDetailsDialog(user: user, currentUser: currentUser),
    );
  }

  void _showPasswordResetDialog(
    BuildContext context,
    User user,
    User currentUser,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          PasswordResetDialog(user: user, currentUser: currentUser),
    );
  }

  void _confirmDeleteUser(BuildContext context, User user, User currentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar desactivación'),
        content: Text(
          '¿Está seguro de que desea desactivar al usuario ${user.fullName}?\n\n'
          'El usuario no podrá acceder al sistema pero sus datos se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<UsersProvider>();
              final success = await provider.deleteUser(
                userId: user.id,
                currentUser: currentUser,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario desactivado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                provider.loadStatistics(currentUser);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _confirmReactivateUser(
    BuildContext context,
    User user,
    User currentUser,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar reactivación'),
        content: Text(
          '¿Está seguro de que desea reactivar al usuario ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<UsersProvider>();
              final success = await provider.reactivateUser(
                userId: user.id,
                currentUser: currentUser,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario reactivado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                provider.loadStatistics(currentUser);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }
}
