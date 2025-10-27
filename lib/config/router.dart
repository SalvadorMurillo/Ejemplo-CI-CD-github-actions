import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/students/students_list_screen.dart';
import '../screens/students/student_detail_screen.dart';
import '../screens/students/add_student_screen.dart';
import '../screens/conduct/conduct_list_screen.dart';
import '../screens/conduct/add_conduct_report_screen.dart';
import '../screens/attitudes/attitude_list_screen.dart';
import '../screens/attitudes/add_attitude_screen.dart';
import '../screens/attitudes/attitude_analytics_screen.dart';
import '../screens/medical/medical_records_screen.dart';
import '../screens/bap/bap_records_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/users/users_screen.dart';

class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: AppConstants.loginRoute,
      redirect: (context, state) {
        final authService = context.read<AuthService>();
        final isAuthenticated = authService.isAuthenticated;
        final isLoggingIn = state.matchedLocation == AppConstants.loginRoute;

        // Si no está autenticado y no está en login, redirigir a login
        if (!isAuthenticated && !isLoggingIn) {
          return AppConstants.loginRoute;
        }

        // Si está autenticado y está en login, redirigir a dashboard
        if (isAuthenticated && isLoggingIn) {
          return AppConstants.dashboardRoute;
        }

        return null; // No redireccionar
      },
      routes: [
        // ***** AUTENTICACIÓN *****
        GoRoute(
          path: AppConstants.loginRoute,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),

        // ***** DASHBOARD *****
        GoRoute(
          path: AppConstants.dashboardRoute,
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),

        // ***** ESTUDIANTES *****
        GoRoute(
          path: AppConstants.studentsRoute,
          name: 'students',
          builder: (context, state) => const StudentsListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'add-student',
              builder: (context, state) => const AddStudentScreen(),
            ),
            GoRoute(
              path: ':studentId',
              name: 'student-detail',
              builder: (context, state) {
                final studentId = state.pathParameters['studentId']!;
                return StudentDetailScreen(studentId: studentId);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'edit-student',
                  builder: (context, state) {
                    final studentId = state.pathParameters['studentId']!;
                    return AddStudentScreen(studentId: studentId);
                  },
                ),
              ],
            ),
          ],
        ),

        // ***** CONDUCTA *****
        GoRoute(
          path: AppConstants.conductRoute,
          name: 'conduct',
          builder: (context, state) => const ConductListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'add-conduct-report',
              builder: (context, state) {
                final studentId = state.uri.queryParameters['studentId'];
                return AddConductReportScreen(studentId: studentId);
              },
            ),
            GoRoute(
              path: 'student/:studentId',
              name: 'student-conduct',
              builder: (context, state) {
                final studentId = state.pathParameters['studentId']!;
                return ConductListScreen(studentId: studentId);
              },
            ),
          ],
        ),

        // ***** ACTITUDES *****
        GoRoute(
          path: AppConstants.attitudesRoute,
          name: 'attitudes',
          builder: (context, state) => const AttitudeListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'add-attitude',
              builder: (context, state) {
                final studentId = state.uri.queryParameters['studentId'];
                return AddAttitudeScreen(studentId: studentId);
              },
            ),
            GoRoute(
              path: 'student/:studentId',
              name: 'student-attitudes',
              builder: (context, state) {
                final studentId = state.pathParameters['studentId']!;
                return AttitudeListScreen(studentId: studentId);
              },
              routes: [
                GoRoute(
                  path: 'analytics',
                  name: 'student-attitudes-analytics',
                  builder: (context, state) {
                    final studentId = state.pathParameters['studentId']!;
                    return AttitudeAnalyticsScreen(studentId: studentId);
                  },
                ),
              ],
            ),
          ],
        ),

        // ***** EXPEDIENTE MÉDICO *****
        GoRoute(
          path: AppConstants.medicalRoute,
          name: 'medical',
          builder: (context, state) => const MedicalRecordsScreen(),
          routes: [
            GoRoute(
              path: 'student/:studentId',
              name: 'student-medical',
              builder: (context, state) {
                final studentId = state.pathParameters['studentId']!;
                return MedicalRecordsScreen(studentId: studentId);
              },
            ),
          ],
        ),

        // ***** BAP *****
        GoRoute(
          path: AppConstants.bapRoute,
          name: 'bap',
          builder: (context, state) => const BAPRecordsScreen(),
          routes: [
            GoRoute(
              path: 'student/:studentId',
              name: 'student-bap',
              builder: (context, state) {
                final studentId = state.pathParameters['studentId']!;
                return BAPRecordsScreen(studentId: studentId);
              },
            ),
          ],
        ),

        // ***** REPORTES *****
        GoRoute(
          path: AppConstants.reportsRoute,
          name: 'reports',
          builder: (context, state) => const ReportsScreen(),
        ),

        // ***** USUARIOS *****
        GoRoute(
          path: AppConstants.usersRoute,
          name: 'users',
          builder: (context, state) => const UsersScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Página no encontrada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'La página "${state.matchedLocation}" no existe.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppConstants.dashboardRoute),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
