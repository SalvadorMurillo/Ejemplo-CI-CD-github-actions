import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

/// Navigation item configuration
class NavigationItem {
  final String label;
  final IconData icon;
  final String route;
  final bool requiresPermission;
  final String? permissionModule;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.requiresPermission = false,
    this.permissionModule,
  });
}

/// Main navigation items (excluding Dashboard which is handled separately)
const List<NavigationItem> mainNavigationItems = [
  NavigationItem(
    label: 'Dashboard',
    icon: Icons.dashboard,
    route: AppConstants.dashboardRoute,
  ),
  NavigationItem(
    label: 'Estudiantes',
    icon: Icons.people,
    route: AppConstants.studentsRoute,
  ),
  NavigationItem(
    label: 'Conducta',
    icon: Icons.assignment,
    route: AppConstants.conductRoute,
  ),
  NavigationItem(
    label: 'Médico',
    icon: Icons.medical_services,
    route: AppConstants.medicalRoute,
  ),
  NavigationItem(
    label: 'BAP',
    icon: Icons.psychology,
    route: AppConstants.bapRoute,
  ),
  NavigationItem(
    label: 'Reportes',
    icon: Icons.bar_chart,
    route: AppConstants.reportsRoute,
  ),
  NavigationItem(
    label: 'Usuarios',
    icon: Icons.admin_panel_settings,
    route: AppConstants.usersRoute,
    requiresPermission: true,
    permissionModule: 'users',
  ),
];

/// Adaptive Navigation Scaffold that adjusts based on screen size
class AdaptiveNavigationScaffold extends StatefulWidget {
  final Widget body;
  final String currentRoute;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final bool showNavigation;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    this.appBar,
    this.floatingActionButton,
    this.showNavigation = true,
  });

  @override
  State<AdaptiveNavigationScaffold> createState() =>
      _AdaptiveNavigationScaffoldState();
}

class _AdaptiveNavigationScaffoldState
    extends State<AdaptiveNavigationScaffold> {
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 768;

    // Filter navigation items based on permissions
    final availableItems = mainNavigationItems.where((item) {
      if (item.requiresPermission && item.permissionModule != null) {
        return authService.hasPermission(item.permissionModule!, 'read');
      }
      return true;
    }).toList();

    final currentIndex = availableItems.indexWhere(
      (item) => widget.currentRoute.startsWith(item.route),
    );

    if (!widget.showNavigation) {
      return Scaffold(
        appBar: widget.appBar,
        body: widget.body,
        floatingActionButton: widget.floatingActionButton,
      );
    }

    if (isWideScreen) {
      // Desktop/Tablet: Use side navigation rail or drawer
      return Scaffold(
        appBar: widget.appBar,
        body: Row(
          children: [
            _buildNavigationRail(
              context,
              availableItems,
              currentIndex,
              authService,
            ),
            Expanded(child: widget.body),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
      );
    } else {
      // Mobile: Use bottom navigation
      return Scaffold(
        appBar: widget.appBar,
        drawer: _buildDrawer(context, availableItems, authService),
        body: widget.body,
        bottomNavigationBar: _buildBottomNavigation(
          context,
          availableItems,
          currentIndex,
        ),
        floatingActionButton: widget.floatingActionButton,
      );
    }
  }

  Widget _buildNavigationRail(
    BuildContext context,
    List<NavigationItem> items,
    int currentIndex,
    AuthService authService,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationRail(
      selectedIndex: currentIndex >= 0 ? currentIndex : 0,
      onDestinationSelected: (index) {
        if (index < items.length) {
          context.go(items[index].route);
        }
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      selectedIconTheme: IconThemeData(
        color: isDark ? const Color(0xFFBF0413) : const Color(0xFFBF0413),
        size: 28,
      ),
      unselectedIconTheme: IconThemeData(
        color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6C757D),
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: isDark ? const Color(0xFFBF0413) : const Color(0xFFBF0413),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6C757D),
        fontSize: 12,
      ),
      indicatorColor: const Color(0xFFBF0413).withOpacity(0.15),
      leading: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              authService.currentUser?.fullName.substring(0, 1).toUpperCase() ??
                  'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: themeProvider.isDarkMode
                      ? 'Tema claro'
                      : 'Tema oscuro',
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _handleLogout(context, authService),
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
          ),
        ),
      ),
      destinations: items.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          label: Text(item.label),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    List<NavigationItem> items,
    int currentIndex,
  ) {
    // Limit to 5 items for bottom navigation (excluding Dashboard for mobile)
    final bottomItems = items
        .where((item) => item.route != AppConstants.dashboardRoute)
        .take(5)
        .toList();
    final adjustedIndex = bottomItems.indexWhere(
      (item) => widget.currentRoute.startsWith(item.route),
    );

    return NavigationBar(
      selectedIndex: adjustedIndex >= 0 ? adjustedIndex : 0,
      onDestinationSelected: (index) {
        if (index < bottomItems.length) {
          context.go(bottomItems[index].route);
        }
      },
      destinations: bottomItems.map((item) {
        return NavigationDestination(icon: Icon(item.icon), label: item.label);
      }).toList(),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    List<NavigationItem> items,
    AuthService authService,
  ) {
    final themeProvider = context.watch<ThemeProvider>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authService.currentUser?.fullName ?? 'Usuario',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  authService.currentUser?.role.displayName ?? 'Sin definir',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ...items.map((item) {
            final isSelected = widget.currentRoute.startsWith(item.route);
            return ListTile(
              leading: Icon(
                item.icon,
                color: isSelected ? const Color(0xFFBF0413) : null,
                size: isSelected ? 28 : 24,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFFBF0413) : null,
                ),
              ),
              selected: isSelected,
              selectedTileColor: const Color(0xFFBF0413).withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                context.go(item.route);
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            title: Text(
              themeProvider.isDarkMode ? 'Tema claro' : 'Tema oscuro',
            ),
            onTap: () {
              themeProvider.toggleTheme();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout(context, authService);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    AuthService authService,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authService.signOut();
      if (context.mounted) {
        context.go(AppConstants.loginRoute);
      }
    }
  }
}
