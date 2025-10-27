import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/student.dart';
import '../core/constants.dart';
import 'database_service.dart';
import 'file_service.dart';

class StudentService {
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();

  /// Obtiene la lista completa de estudiantes
  Future<List<Student>> getAllStudents() async {
    try {
      final response = await _databaseService.client
          .from(AppConstants.studentsTable)
          .select('''
            *,
            guardians (*)
          ''')
          .order('last_name', ascending: true);

      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all students: $e');
      rethrow;
    }
  }

  /// Obtiene estudiantes por filtros
  Future<List<Student>> getStudentsByFilter({
    SchoolGrade? grade,
    String? group,
    String? currentSchoolYear,
    bool? isActive,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _databaseService.client
          .from(AppConstants.studentsTable)
          .select('''
            *,
            guardians (*)
          ''');

      // Aplicar filtros
      if (grade != null) {
        query = query.eq('grade', grade.name);
      }

      if (group != null) {
        query = query.eq('group', group);
      }

      if (currentSchoolYear != null) {
        query = query.eq('current_school_year', currentSchoolYear);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      // Búsqueda por texto
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'first_name.ilike.%$searchQuery%,'
          'last_name.ilike.%$searchQuery%,'
          'middle_name.ilike.%$searchQuery%,'
          'curp.ilike.%$searchQuery%,'
          'institutional_id.ilike.%$searchQuery%,'
          'enrollment.ilike.%$searchQuery%',
        );
      }

      // Ordenamiento
      query = query.order('last_name', ascending: true);

      // Paginación
      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(
          offset,
          offset + (limit ?? AppConstants.defaultPageSize) - 1,
        );
      }

      final response = await query;

      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting students by filter: $e');
      rethrow;
    }
  }

  /// Obtiene un estudiante por ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final response = await _databaseService.client
          .from(AppConstants.studentsTable)
          .select('''
            *,
            guardians (*)
          ''')
          .eq('id', studentId)
          .single();

      return Student.fromJson(response);
    } catch (e) {
      debugPrint('Error getting student by ID: $e');
      return null;
    }
  }

  /// Crea un nuevo estudiante
  Future<Student> createStudent(Student student) async {
    try {
      final studentData = student.toJson();
      studentData.remove('guardians'); // Los tutores se manejan por separado

      // Remove fields that should be handled by database or set to null
      studentData.remove('id'); // Let database generate
      studentData.remove('created_at');
      studentData.remove('updated_at');

      // Set user tracking fields - get current user ID or set to null
      final currentUser = _databaseService.client.auth.currentUser;
      studentData['created_by'] = currentUser?.id;
      studentData['updated_by'] = currentUser?.id;

      final response = await _databaseService.client
          .from(AppConstants.studentsTable)
          .insert(studentData)
          .select()
          .single();

      final newStudent = Student.fromJson(response);

      // Crear tutores si existen
      if (student.guardians.isNotEmpty) {
        await _createGuardians(newStudent.id, student.guardians);
      }

      return await getStudentById(newStudent.id) ?? newStudent;
    } catch (e) {
      debugPrint('Error creating student: $e');
      rethrow;
    }
  }

  /// Actualiza un estudiante existente
  Future<Student> updateStudent(Student student) async {
    try {
      final studentData = student.toJson();
      studentData.remove('guardians'); // Los tutores se manejan por separado

      final response = await _databaseService.client
          .from(AppConstants.studentsTable)
          .update(studentData)
          .eq('id', student.id)
          .select()
          .single();

      // Actualizar tutores
      await _updateGuardians(student.id, student.guardians);

      return await getStudentById(student.id) ?? Student.fromJson(response);
    } catch (e) {
      debugPrint('Error updating student: $e');
      rethrow;
    }
  }

  /// Elimina un estudiante (marca como inactivo)
  Future<void> deleteStudent(String studentId) async {
    try {
      await _databaseService.client
          .from(AppConstants.studentsTable)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', studentId);
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }

  /// Actualiza la foto de perfil de un estudiante
  Future<String?> updateStudentProfileImage(
    String studentId,
    XFile imageFile,
  ) async {
    try {
      final imageUrl = await _fileService.uploadStudentProfileImage(
        imageFile,
        studentId,
      );

      if (imageUrl != null) {
        await _databaseService.client
            .from(AppConstants.studentsTable)
            .update({
              'profile_image_url': imageUrl,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', studentId);
      }

      return imageUrl;
    } catch (e) {
      debugPrint('Error updating student profile image: $e');
      rethrow;
    }
  }

  /// Actualiza la foto de perfil de un estudiante para un grado específico
  Future<String?> updateStudentGradeProfileImage(
    String studentId,
    XFile imageFile,
    SchoolGrade grade,
  ) async {
    try {
      final imageUrl = await _fileService.uploadStudentGradeProfileImage(
        imageFile,
        studentId,
        grade,
      );

      if (imageUrl != null) {
        String columnName;
        switch (grade) {
          case SchoolGrade.primero:
            columnName = 'profile_image_url_grade1';
            break;
          case SchoolGrade.segundo:
            columnName = 'profile_image_url_grade2';
            break;
          case SchoolGrade.tercero:
            columnName = 'profile_image_url_grade3';
            break;
        }

        await _databaseService.client
            .from(AppConstants.studentsTable)
            .update({
              columnName: imageUrl,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', studentId);
      }

      return imageUrl;
    } catch (e) {
      debugPrint('Error updating student grade profile image: $e');
      rethrow;
    }
  }

  /// Elimina la foto de perfil de un estudiante para un grado específico
  Future<void> removeStudentGradeProfileImage(
    String studentId,
    SchoolGrade grade,
  ) async {
    try {
      String columnName;
      switch (grade) {
        case SchoolGrade.primero:
          columnName = 'profile_image_url_grade1';
          break;
        case SchoolGrade.segundo:
          columnName = 'profile_image_url_grade2';
          break;
        case SchoolGrade.tercero:
          columnName = 'profile_image_url_grade3';
          break;
      }

      await _databaseService.client
          .from(AppConstants.studentsTable)
          .update({
            columnName: null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', studentId);
    } catch (e) {
      debugPrint('Error removing student grade profile image: $e');
      rethrow;
    }
  }

  /// Elimina la foto de perfil de un estudiante
  Future<void> removeStudentProfileImage(String studentId) async {
    try {
      await _databaseService.client
          .from(AppConstants.studentsTable)
          .update({
            'profile_image_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', studentId);
    } catch (e) {
      debugPrint('Error removing student profile image: $e');
      rethrow;
    }
  }

  /// Obtiene estadísticas de reportes de un estudiante
  Future<Map<String, int>> getStudentReportsStats(String studentId) async {
    try {
      final positiveQuery = _databaseService.client
          .from(AppConstants.conductReportsTable)
          .select('id')
          .eq('student_id', studentId)
          .eq('type', ConductReportType.positive.name);

      final negativeQuery = _databaseService.client
          .from(AppConstants.conductReportsTable)
          .select('id')
          .eq('student_id', studentId)
          .eq('type', ConductReportType.negative.name);

      final results = await Future.wait([positiveQuery, negativeQuery]);

      return {
        'positive': (results[0] as List).length,
        'negative': (results[1] as List).length,
      };
    } catch (e) {
      debugPrint('Error getting student reports stats: $e');
      return {'positive': 0, 'negative': 0};
    }
  }

  /// Valida si un CURP ya existe
  Future<bool> isCurpUnique(String curp, {String? excludeStudentId}) async {
    try {
      dynamic query = _databaseService.client
          .from(AppConstants.studentsTable)
          .select('id')
          .eq('curp', curp);

      if (excludeStudentId != null) {
        query = query.neq('id', excludeStudentId);
      }

      final response = await query;
      return (response as List).isEmpty;
    } catch (e) {
      debugPrint('Error checking CURP uniqueness: $e');
      return false;
    }
  }

  /// Valida si una matrícula ya existe
  Future<bool> isEnrollmentUnique(
    String enrollment, {
    String? excludeStudentId,
  }) async {
    try {
      dynamic query = _databaseService.client
          .from(AppConstants.studentsTable)
          .select('id')
          .eq('enrollment', enrollment);

      if (excludeStudentId != null) {
        query = query.neq('id', excludeStudentId);
      }

      final response = await query;
      return (response as List).isEmpty;
    } catch (e) {
      debugPrint('Error checking enrollment uniqueness: $e');
      return false;
    }
  }

  /// Métodos privados para manejar tutores

  Future<void> _createGuardians(
    String studentId,
    List<Guardian> guardians,
  ) async {
    try {
      for (final guardian in guardians) {
        final guardianData = guardian.toJson();
        guardianData['student_id'] = studentId;

        await _databaseService.client.from('guardians').insert(guardianData);
      }
    } catch (e) {
      debugPrint('Error creating guardians: $e');
      rethrow;
    }
  }

  Future<void> _updateGuardians(
    String studentId,
    List<Guardian> guardians,
  ) async {
    try {
      // Eliminar tutores existentes
      await _databaseService.client
          .from('guardians')
          .delete()
          .eq('student_id', studentId);

      // Crear nuevos tutores
      await _createGuardians(studentId, guardians);
    } catch (e) {
      debugPrint('Error updating guardians: $e');
      rethrow;
    }
  }

  /// Obtiene estudiantes por grado y grupo
  Future<List<Student>> getStudentsByGradeAndGroup(
    SchoolGrade grade,
    String group,
  ) async {
    try {
      final response = await _databaseService.client
          .from(AppConstants.studentsTable)
          .select('''
            *,
            guardians (*)
          ''')
          .eq('grade', grade.name)
          .eq('group', group)
          .eq('is_active', true)
          .order('numero_lista', ascending: true);

      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting students by grade and group: $e');
      rethrow;
    }
  }

  /// Exporta la lista de estudiantes a CSV
  Future<String> exportStudentsToCSV(List<Student> students) async {
    try {
      final StringBuffer csv = StringBuffer();

      // Encabezados
      csv.writeln(
        'CURP,Folio Institucional,Matrícula,Nombres,Apellidos,Grado,Grupo,Ciclo Escolar,Reportes Positivos,Reportes Negativos,Activo',
      );

      // Datos
      for (final student in students) {
        csv.writeln(
          [
            student.curp,
            student.institutionalId,
            student.enrollment,
            student.firstName,
            '${student.lastName}${student.middleName != null ? ' ${student.middleName}' : ''}',
            student.grade.displayName,
            student.group,
            student.currentSchoolYear,
            student.positiveReportsCount,
            student.negativeReportsCount,
            student.isActive ? 'Sí' : 'No',
          ].map((field) => '"$field"').join(','),
        );
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Error exporting students to CSV: $e');
      rethrow;
    }
  }
}
