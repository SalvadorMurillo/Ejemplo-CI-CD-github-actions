import 'package:flutter/material.dart';

// Enums para los tipos de usuario
enum UserRole {
  admin,
  director,
  subdirector,
  socialWorker,
  prefect,
  counselor,
  usaer,
  academicCoordinator,
  medico,
  docente,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.director:
        return 'Director';
      case UserRole.subdirector:
        return 'Subdirector';
      case UserRole.socialWorker:
        return 'Trabajo Social';
      case UserRole.prefect:
        return 'Prefecto';
      case UserRole.counselor:
        return 'Orientador';
      case UserRole.usaer:
        return 'USAER';
      case UserRole.academicCoordinator:
        return 'Coordinador Académico';
      case UserRole.medico:
        return 'Médico';
      case UserRole.docente:
        return 'Docente';
    }
  }
}

// Enums para reportes de conducta
enum ConductReportType { positive, negative }

extension ConductReportTypeExtension on ConductReportType {
  String get displayName {
    switch (this) {
      case ConductReportType.positive:
        return 'Positivo';
      case ConductReportType.negative:
        return 'Negativo';
    }
  }
}

// Enums para gravedad de incidentes
enum IncidentSeverity { mild, moderate, severe, verySevere }

extension IncidentSeverityExtension on IncidentSeverity {
  String get displayName {
    switch (this) {
      case IncidentSeverity.mild:
        return 'Leve';
      case IncidentSeverity.moderate:
        return 'Moderado';
      case IncidentSeverity.severe:
        return 'Grave';
      case IncidentSeverity.verySevere:
        return 'Muy Grave';
    }
  }
}

// Enums para tipos de BAP
enum BAPType {
  learning,
  behavioral,
  social,
  emotional,
  physical,
  intellectual,
  sensory,
}

extension BAPTypeExtension on BAPType {
  String get displayName {
    switch (this) {
      case BAPType.learning:
        return 'Aprendizaje';
      case BAPType.behavioral:
        return 'Conductual';
      case BAPType.social:
        return 'Social';
      case BAPType.emotional:
        return 'Emocional';
      case BAPType.physical:
        return 'Física';
      case BAPType.intellectual:
        return 'Intelectual';
      case BAPType.sensory:
        return 'Sensorial';
    }
  }

  IconData get icon {
    switch (this) {
      case BAPType.learning:
        return Icons.school;
      case BAPType.behavioral:
        return Icons.psychology;
      case BAPType.social:
        return Icons.people;
      case BAPType.emotional:
        return Icons.favorite;
      case BAPType.physical:
        return Icons.accessibility;
      case BAPType.intellectual:
        return Icons.lightbulb;
      case BAPType.sensory:
        return Icons.hearing;
    }
  }

  Color get color {
    switch (this) {
      case BAPType.learning:
        return Colors.blue;
      case BAPType.behavioral:
        return Colors.purple;
      case BAPType.social:
        return Colors.green;
      case BAPType.emotional:
        return Colors.pink;
      case BAPType.physical:
        return Colors.orange;
      case BAPType.intellectual:
        return Colors.amber;
      case BAPType.sensory:
        return Colors.teal;
    }
  }
}

// Enums para grados escolares
enum SchoolGrade { primero, segundo, tercero }

extension SchoolGradeExtension on SchoolGrade {
  String get displayName {
    switch (this) {
      case SchoolGrade.primero:
        return '1 -';
      case SchoolGrade.segundo:
        return '2 -';
      case SchoolGrade.tercero:
        return '3 -';
    }
  }
}

// Enums para tipos sanguíneos
enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

extension BloodTypeExtension on BloodType {
  String get displayName {
    switch (this) {
      case BloodType.aPositive:
        return 'A+';
      case BloodType.aNegative:
        return 'A-';
      case BloodType.bPositive:
        return 'B+';
      case BloodType.bNegative:
        return 'B-';
      case BloodType.abPositive:
        return 'AB+';
      case BloodType.abNegative:
        return 'AB-';
      case BloodType.oPositive:
        return 'O+';
      case BloodType.oNegative:
        return 'O-';
    }
  }
}

// Constantes de la aplicación
class AppConstants {
  static const String appName = 'SControl';
  static const String appVersion = '1.0.0';

  // Límites de archivos
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx'];

  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configuración de base de datos
  static const String studentsTable = 'students';
  static const String usersTable = 'users';
  static const String conductReportsTable = 'conduct_reports';
  static const String medicalRecordsTable = 'medical_records';
  static const String bapRecordsTable = 'bap_records';
  static const String attitudesTable = 'attitudes';
  static const String finalReportsTable = 'final_reports';
  static const String auditLogsTable = 'audit_logs';

  // Rutas de la aplicación
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String studentsRoute = '/students';
  static const String conductRoute = '/conduct';
  static const String attitudesRoute = '/attitudes';
  static const String medicalRoute = '/medical';
  static const String bapRoute = '/bap';
  static const String reportsRoute = '/reports';
  static const String usersRoute = '/users';

  // Mensajes de error comunes
  static const String networkError =
      'Error de conexión. Verifique su conexión a internet.';
  static const String unknownError = 'Ha ocurrido un error inesperado.';
  static const String unauthorizedError =
      'No tiene permisos para realizar esta acción.';
  static const String notFoundError = 'El recurso solicitado no existe.';

  // Formato de fechas
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
}

// Permisos por rol
class RolePermissions {
  static const Map<UserRole, Map<String, List<String>>> permissions = {
    UserRole.admin: {
      'students': ['read', 'write', 'delete'],
      'bap': ['read', 'write', 'delete'],
      'conduct': ['read', 'write', 'delete'],
      'medical': ['read', 'write', 'delete'],
      'users': ['read', 'write', 'delete'],
      'reports': ['read'],
    },
    UserRole.director: {
      'students': ['read', 'write', 'delete'],
      'bap': ['read', 'write'],
      'conduct': ['read', 'write'],
      'medical': ['read', 'write'],
      'users': ['read', 'write', 'delete'],
      'reports': ['read'],
    },
    UserRole.subdirector: {
      'students': ['read', 'write', 'delete'],
      'bap': ['read', 'write'],
      'conduct': ['read', 'write'],
      'medical': ['read', 'write'],
      'users': ['read', 'write', 'delete'],
      'reports': ['read'],
    },
    UserRole.socialWorker: {
      'students': ['read', 'write'],
      'bap': ['read', 'write'],
      'conduct': ['read', 'write'],
      'medical': ['read', 'write'],
      'users': [],
      'reports': ['read'],
    },
    UserRole.prefect: {
      'students': ['read', 'write'],
      'bap': ['read'],
      'conduct': ['read', 'write'],
      'medical': ['read'],
      'users': [],
      'reports': ['read'],
    },
    UserRole.counselor: {
      'students': ['read', 'write'],
      'bap': ['read', 'write'],
      'conduct': ['read', 'write'],
      'medical': ['read'],
      'users': [],
      'reports': ['read'],
    },
    UserRole.usaer: {
      'students': ['read', 'write'],
      'bap': ['read', 'write'],
      'conduct': ['read', 'write'],
      'medical': ['read'],
      'users': [],
      'reports': ['read'],
    },
    UserRole.academicCoordinator: {
      'students': ['read'],
      'bap': ['read'],
      'conduct': ['read'],
      'medical': ['read'],
      'users': [],
      'reports': ['read'],
    },
    UserRole.medico: {
      'students': ['read'],
      'bap': ['read'],
      'conduct': ['read'],
      'medical': ['read', 'write'],
      'users': [],
      'reports': ['read'],
    },
    UserRole.docente: {
      'students': ['read'],
      'bap': ['read'],
      'conduct': ['read'],
      'medical': ['read'],
      'users': [],
      'reports': ['read'],
    },
  };

  static bool hasPermission(UserRole role, String module, String action) {
    final modulePermissions = permissions[role]?[module];
    return modulePermissions?.contains(action) ?? false;
  }
}

// Opciones de talleres disponibles
class TallerOptions {
  static const List<String> talleres = [
    'Carpintería',
    'Electricidad',
    'Electrónica',
    'Informática',
    'Soldadura',
    'Mecánica Automotriz',
    'Dibujo Técnico',
    'Diseño Gráfico',
    'Corte y Confección',
    'Cocina',
    'Repostería',
    'Secretariado',
    'Contabilidad',
    'Estructuras Metálicas',
    'Refrigeración y Climatización',
    'Plomería',
    'Otro',
  ];
}
