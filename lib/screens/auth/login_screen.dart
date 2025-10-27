import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final success = await authService.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go(AppConstants.dashboardRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    // Responsive card width
    double cardWidth;
    if (isDesktop) {
      cardWidth = 500;
    } else if (isTablet) {
      cardWidth = 450;
    } else {
      cardWidth = size.width * 0.9;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return LoadingOverlay(
            isLoading: authService.isLoading,
            child: Stack(
              children: [
                // Background decoration for desktop
                if (isDesktop)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.primaryDark,
                                  AppColors.backgroundDark,
                                ]
                              : [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.background,
                                ],
                        ),
                      ),
                    ),
                  ),

                // Theme toggle button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        onPressed: () => themeProvider.toggleTheme(),
                        tooltip: isDark
                            ? 'Cambiar a tema claro'
                            : 'Cambiar a tema oscuro',
                      );
                    },
                  ),
                ),

                // Main content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                        isDesktop
                            ? AppDimensions.paddingXL
                            : AppDimensions.paddingL,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardWidth),
                          child: Card(
                            elevation: isDesktop
                                ? AppDimensions.elevationL
                                : AppDimensions.elevationM,
                            color: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isDesktop
                                    ? AppDimensions.radiusXL
                                    : AppDimensions.radiusL,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isDesktop
                                    ? AppDimensions.paddingXL * 1.5
                                    : AppDimensions.paddingXL,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Logo image
                                    Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusL,
                                        ),
                                        child: Image.asset(
                                          'assets/images/esima logo.jpg',
                                          height: isDesktop ? 120 : 100,
                                          width: isDesktop ? 120 : 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                // Fallback to icon if image fails
                                                return Icon(
                                                  Icons.school,
                                                  size: isDesktop ? 100 : 80,
                                                  color:
                                                      theme.colorScheme.primary,
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: isDesktop
                                          ? AppDimensions.paddingL
                                          : AppDimensions.paddingM,
                                    ),

                                    // Título
                                    Text(
                                      AppConstants.appName,
                                      style:
                                          (isDesktop
                                                  ? AppTextStyles.headline1
                                                  : AppTextStyles.headline2)
                                              .copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(
                                      height: AppDimensions.paddingS,
                                    ),

                                    Text(
                                      'Sistema de Control Estudiantil',
                                      style: AppTextStyles.bodyText2.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(
                                      height: isDesktop
                                          ? AppDimensions.paddingXL * 1.5
                                          : AppDimensions.paddingXL,
                                    ),

                                    // Email
                                    CustomTextField(
                                      controller: _emailController,
                                      label: 'Correo electrónico',
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: Icons.email,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor ingrese su correo';
                                        }
                                        if (!RegExp(
                                          r'^[^@]+@[^@]+\.[^@]+',
                                        ).hasMatch(value)) {
                                          return 'Ingrese un correo válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(
                                      height: AppDimensions.paddingM,
                                    ),

                                    // Contraseña
                                    CustomTextField(
                                      controller: _passwordController,
                                      label: 'Contraseña',
                                      obscureText: _obscurePassword,
                                      prefixIcon: Icons.lock,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor ingrese su contraseña';
                                        }
                                        if (value.length < 6) {
                                          return 'La contraseña debe tener al menos 6 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(
                                      height: isDesktop
                                          ? AppDimensions.paddingXL
                                          : AppDimensions.paddingL,
                                    ),

                                    // Botón de login
                                    ElevatedButton(
                                      onPressed: authService.isLoading
                                          ? null
                                          : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isDesktop ? 16 : 14,
                                        ),
                                      ),
                                      child: Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          fontSize: isDesktop ? 16 : 14,
                                        ),
                                      ),
                                    ),

                                    // Error message
                                    if (authService.errorMessage != null) ...[
                                      const SizedBox(
                                        height: AppDimensions.paddingM,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppDimensions.paddingM,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(
                                            isDark ? 0.2 : 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusM,
                                          ),
                                          border: Border.all(
                                            color: AppColors.error.withOpacity(
                                              isDark ? 0.5 : 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: AppColors.error,
                                              size: AppDimensions.iconM,
                                            ),
                                            const SizedBox(
                                              width: AppDimensions.paddingS,
                                            ),
                                            Expanded(
                                              child: Text(
                                                authService.errorMessage!,
                                                style: AppTextStyles.bodyText2
                                                    .copyWith(
                                                      color: AppColors.error,
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: AppDimensions.iconS,
                                              ),
                                              onPressed: () =>
                                                  authService.clearError(),
                                              color: AppColors.error,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    SizedBox(
                                      height: isDesktop
                                          ? AppDimensions.paddingXL
                                          : AppDimensions.paddingL,
                                    ),

                                    // Versión
                                    Text(
                                      'Versión ${AppConstants.appVersion}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
