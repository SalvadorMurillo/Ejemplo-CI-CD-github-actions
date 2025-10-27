import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: Consumer2<AuthService, ThemeProvider>(
        builder: (context, authService, themeProvider, child) {
          return ListTileTheme(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            textColor: colorScheme.onSurface,
            iconColor: colorScheme.onSurface,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: colorScheme.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        authService.currentUser?.fullName ?? 'Usuario',
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.85),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        authService.currentUser?.role.displayName ??
                            'Sin definir',
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.75),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppConstants.dashboardRoute);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Estudiantes'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppConstants.studentsRoute);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Conducta'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppConstants.conductRoute);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Expediente Médico'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppConstants.medicalRoute);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.psychology),
                  title: const Text('BAP'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppConstants.bapRoute);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Reportes'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppConstants.reportsRoute);
                  },
                ),
                if (authService.hasPermission('users', 'read'))
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Usuarios'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppConstants.usersRoute);
                    },
                  ),
                const Divider(),
                // Theme toggle
                SwitchListTile(
                  value: themeProvider.isDarkMode,
                  title: const Text('Tema oscuro'),
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  onChanged: (val) {
                    themeProvider.toggleTheme();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar Sesión'),
                  onTap: () async {
                    Navigator.pop(context);
                    await authService.signOut();
                    if (context.mounted) {
                      context.go(AppConstants.loginRoute);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
