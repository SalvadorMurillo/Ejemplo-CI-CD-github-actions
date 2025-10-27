import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/adaptive_navigation.dart';
import '../../providers/theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      currentRoute: AppConstants.dashboardRoute,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode
                    ? 'Tema claro'
                    : 'Tema oscuro',
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'logout':
                  await context.read<AuthService>().signOut();
                  if (mounted) {
                    context.go(AppConstants.loginRoute);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return LoadingOverlay(
            isLoading: authService.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo
                  Text(
                    'Bienvenido, ${authService.currentUser?.fullName ?? 'Usuario'}',
                    style: AppTextStyles.headline3,
                  ),
                  Text(
                    'Rol: ${authService.currentUser?.role.displayName ?? 'Sin definir'}',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),

                  // Tarjetas de navegación rápida
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200
                          ? 4
                          : constraints.maxWidth > 768
                          ? 3
                          : 2;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppDimensions.paddingM,
                        mainAxisSpacing: AppDimensions.paddingM,
                        children: [
                          _buildDashboardCard(
                            context,
                            title: 'Estudiantes',
                            icon: Icons.people,
                            color: AppColors.primary,
                            onTap: () => context.go(AppConstants.studentsRoute),
                          ),
                          _buildDashboardCard(
                            context,
                            title: 'Conducta',
                            icon: Icons.assignment,
                            color: AppColors.secondary,
                            onTap: () => context.go(AppConstants.conductRoute),
                          ),
                          _buildDashboardCard(
                            context,
                            title: 'Médico',
                            icon: Icons.medical_services,
                            color: AppColors.accent,
                            onTap: () => context.go(AppConstants.medicalRoute),
                          ),
                          _buildDashboardCard(
                            context,
                            title: 'BAP',
                            icon: Icons.psychology,
                            color: AppColors.warning,
                            onTap: () => context.go(AppConstants.bapRoute),
                          ),
                          _buildDashboardCard(
                            context,
                            title: 'Reportes',
                            icon: Icons.bar_chart,
                            color: AppColors.info,
                            onTap: () => context.go(AppConstants.reportsRoute),
                          ),
                          if (authService.hasPermission('users', 'read'))
                            _buildDashboardCard(
                              context,
                              title: 'Usuarios',
                              icon: Icons.admin_panel_settings,
                              color: AppColors.success,
                              onTap: () => context.go(AppConstants.usersRoute),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: AppDimensions.elevationS,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppDimensions.iconXL, color: color),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                title,
                style: AppTextStyles.headline6.copyWith(color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
