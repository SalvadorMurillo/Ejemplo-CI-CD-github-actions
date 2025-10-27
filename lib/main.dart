import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode and kIsWeb
import 'dart:io'; // Import for Platform

import 'config/theme.dart';
import 'config/router.dart';
import 'core/constants.dart';
import 'services/auth_service.dart';
import 'providers/students_provider.dart';
import 'providers/conduct_provider.dart';
import 'providers/bap_provider.dart';
import 'providers/medical_provider.dart';
import 'providers/attitude_provider.dart';
import 'providers/users_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Cargar variables de entorno
    await dotenv.load();

    // Get the appropriate Supabase URL
    String supabaseUrl = getSupabaseUrl();
    String anonKey = dotenv.env['ANON_KEY']!;

    // Debug prints
    print(
      'Platform: ${kIsWeb ? 'Web' : (Platform.isAndroid
                ? 'Android'
                : Platform.isIOS
                ? 'iOS'
                : 'Unknown')}',
    );
    print('Debug Mode: $kDebugMode');
    print('Using SUPABASE_URL: $supabaseUrl');
    print(
      'ANON_KEY: ${anonKey.substring(0, 20)}...',
    ); // Only print first 20 chars for security

    // Ensure previous instance is closed (in case of hot restart)
    try {
      await Supabase.instance.dispose();
    } catch (e) {
      print('No previous Supabase instance to dispose');
    }

    // Inicializar Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: kDebugMode,
    );

    print('Supabase initialized successfully');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
    runApp(ErrorApp(error: e.toString()));
  }
}

String getSupabaseUrl() {
  if (kDebugMode) {
    // Check if running on web
    if (kIsWeb) {
      final url = dotenv.env['SUPABASE_URL']!;
      print('Selected URL for Web: $url');
      return url;
    } else {
      // For mobile devices (Android/iOS) - always use the phone-specific URL
      final url = dotenv.env['SUPABASE_URL_Phone'];
      if (url == null || url.isEmpty) {
        throw Exception('SUPABASE_URL_Phone is not set in .env file');
      }
      print('Selected URL for Physical Device: $url');
      return url;
    }
  }
  // Production URL
  final prodUrl =
      dotenv.env['SUPABASE_URL_PROD'] ?? dotenv.env['SUPABASE_URL']!;
  print('Selected URL for Production: $prodUrl');
  return prodUrl;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider (must be first to be available to other providers)
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Servicios
        ChangeNotifierProvider(create: (_) => AuthService()),

        // Providers de datos
        ChangeNotifierProvider(create: (_) => StudentsProvider()),
        ChangeNotifierProvider(create: (_) => ConductProvider()),
        ChangeNotifierProvider(create: (_) => BAPProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProvider()),
        ChangeNotifierProvider(create: (_) => AttitudeProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
      ],
      child: Consumer2<AuthService, ThemeProvider>(
        builder: (context, authService, themeProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.createRouter(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// Error app to show initialization errors
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error de Inicialización',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
