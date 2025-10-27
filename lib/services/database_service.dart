import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as models;
import '../core/constants.dart';

class DatabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  SupabaseClient get client => _client;

  // ***** AUTENTICACIÓN *****

  Future<models.User?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final response = await _client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', authUser.id)
        .single();

    final user = models.User.fromJson(response);

    // Check if user is active, if not sign them out
    if (!user.isActive) {
      await _client.auth.signOut();
      return null;
    }

    return user;
  }

  Future<models.User> signIn(String email, String password) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Error de autenticación');
    }

    final userResponse = await _client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', authResponse.user!.id)
        .single();

    final user = models.User.fromJson(userResponse);

    // Check if user is active
    if (!user.isActive) {
      // Sign out the user immediately
      await _client.auth.signOut();
      throw Exception('Usuario inactivo. Contacte al administrador.');
    }

    return user;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ***** USUARIOS *****

  Future<List<models.User>> getUsers({
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
    String? search,
    UserRole? role,
    bool? isActive,
  }) async {
    var query = _client.from(AppConstants.usersTable).select();

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'first_name.ilike.%$search%,last_name.ilike.%$search%,email.ilike.%$search%',
      );
    }

    if (role != null) {
      query = query.eq('role', role.name);
    }

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((json) => models.User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<models.User> createUser(models.User user, String password) async {
    // Crear usuario en Auth
    final authResponse = await _client.auth.admin.createUser(
      AdminUserAttributes(
        email: user.email,
        password: password,
        emailConfirm: true,
      ),
    );

    if (authResponse.user == null) {
      throw Exception('Error al crear usuario en Auth');
    }

    // Crear perfil de usuario
    final userData = user.copyWith(id: authResponse.user!.id).toJson();

    final response = await _client
        .from(AppConstants.usersTable)
        .insert(userData)
        .select()
        .single();

    await _logAudit(
      action: 'INSERT', // Changed from 'create'
      tableName: AppConstants.usersTable,
      recordId: response['id'],
    );

    return models.User.fromJson(response);
  }

  Future<models.User> updateUser(models.User user) async {
    final response = await _client
        .from(AppConstants.usersTable)
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();

    await _logAudit(
      action: 'UPDATE', // Changed from 'update'
      tableName: AppConstants.usersTable,
      recordId: user.id,
    );

    return models.User.fromJson(response);
  }

  Future<void> deleteUser(String userId) async {
    await _client
        .from(AppConstants.usersTable)
        .update({'is_active': false})
        .eq('id', userId);

    await _logAudit(
      action: 'DELETE', // Changed from 'delete'
      tableName: AppConstants.usersTable,
      recordId: userId,
    );
  }

  // ***** ESTUDIANTES *****

  Future<List<models.Student>> getStudents({
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
    String? search,
    SchoolGrade? grade,
    String? group,
    String? schoolYear,
    bool? isActive,
  }) async {
    var query = _client.from(AppConstants.studentsTable).select('''
          *,
          guardians:guardians(*)
        ''');

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'first_name.ilike.%$search%,last_name.ilike.%$search%,curp.ilike.%$search%,institutional_id.ilike.%$search%',
      );
    }

    if (grade != null) {
      query = query.eq('grade', grade.name);
    }

    if (group != null && group.isNotEmpty) {
      query = query.eq('group', group);
    }

    if (schoolYear != null && schoolYear.isNotEmpty) {
      query = query.eq('current_school_year', schoolYear);
    }

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query
        .order('last_name')
        .order('first_name')
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((json) => models.Student.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<models.Student?> getStudentById(String studentId) async {
    final response = await _client
        .from(AppConstants.studentsTable)
        .select('''
          *,
          guardians:guardians(*)
        ''')
        .eq('id', studentId)
        .maybeSingle();

    if (response == null) return null;
    return models.Student.fromJson(response);
  }

  Future<models.Student> createStudent(models.Student student) async {
    final response = await _client
        .from(AppConstants.studentsTable)
        .insert(student.toJson())
        .select()
        .single();

    // Crear tutores
    for (final guardian in student.guardians) {
      await _client.from('guardians').insert({
        ...guardian.toJson(),
        'student_id': response['id'],
      });
    }

    await _logAudit(
      action: 'INSERT', // Changed from 'create'
      tableName: AppConstants.studentsTable,
      recordId: response['id'],
    );

    final createdStudent = await getStudentById(response['id']);
    return createdStudent!;
  }

  Future<models.Student> updateStudent(models.Student student) async {
    final response = await _client
        .from(AppConstants.studentsTable)
        .update(student.toJson())
        .eq('id', student.id)
        .select()
        .single();

    await _logAudit(
      action: 'UPDATE', // Changed from 'update'
      tableName: AppConstants.studentsTable,
      recordId: student.id,
    );

    return models.Student.fromJson(response);
  }

  Future<void> deactivateStudent(String studentId) async {
    await _client
        .from(AppConstants.studentsTable)
        .update({'is_active': false})
        .eq('id', studentId);

    await _logAudit(
      action: 'DELETE', // Changed from 'delete'
      tableName: AppConstants.studentsTable,
      recordId: studentId,
    );
  }

  Future<void> reactivateStudent(String studentId) async {
    await _client
        .from(AppConstants.studentsTable)
        .update({'is_active': true})
        .eq('id', studentId);

    await _logAudit(
      action: 'UPDATE', // Changed from 'update'
      tableName: AppConstants.studentsTable,
      recordId: studentId,
      reason: 'Reactivación de estudiante',
    );
  }

  // ***** REPORTES DE CONDUCTA *****

  Future<List<models.ConductReport>> getConductReports({
    String? studentId,
    ConductReportType? type,
    IncidentSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
  }) async {
    var query = _client.from(AppConstants.conductReportsTable).select('''
          *,
          reporter:users!reporter_id(first_name, last_name),
          student:students!student_id(first_name, last_name),
          parent_agreements:parent_agreements(*)
        ''');

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    if (type != null) {
      query = query.eq('type', type.name);
    }

    if (severity != null) {
      query = query.eq('severity', severity.name);
    }

    if (startDate != null) {
      query = query.gte('incident_date', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('incident_date', endDate.toIso8601String());
    }

    final response = await query
        .order('incident_date', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>).map((json) {
      final reporterData = json['reporter'] as Map<String, dynamic>?;
      final reporterName = reporterData != null
          ? '${reporterData['first_name']} ${reporterData['last_name']}'
          : null;

      final studentData = json['student'] as Map<String, dynamic>?;
      final studentName = studentData != null
          ? '${studentData['first_name']} ${studentData['last_name']}'
          : null;

      return models.ConductReport.fromJson({
        ...json,
        'reporter_name': reporterName,
        'student_name': studentName,
      });
    }).toList();
  }

  Future<models.ConductReport> createConductReport(
    models.ConductReport report,
  ) async {
    final response = await _client
        .from(AppConstants.conductReportsTable)
        .insert(report.toJson())
        .select()
        .single();

    // Actualizar contadores del estudiante
    if (report.type == ConductReportType.positive) {
      await _client.rpc(
        'increment_positive_reports',
        params: {'student_id': report.studentId},
      );
    } else {
      await _client.rpc(
        'increment_negative_reports',
        params: {'student_id': report.studentId},
      );
    }

    await _logAudit(
      action: 'INSERT', // Changed from 'create'
      tableName: AppConstants.conductReportsTable,
      recordId: response['id'],
    );

    return models.ConductReport.fromJson(response);
  }

  Future<models.ConductReport> updateConductReport(
    models.ConductReport report,
  ) async {
    final updateData = {
      ...report.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    updateData.remove('id');
    updateData.remove('created_at');

    final response = await _client
        .from(AppConstants.conductReportsTable)
        .update(updateData)
        .eq('id', report.id)
        .select()
        .single();

    await _logAudit(
      action: 'UPDATE',
      tableName: AppConstants.conductReportsTable,
      recordId: report.id,
    );

    return models.ConductReport.fromJson(response);
  }

  Future<void> deleteConductReport(String reportId) async {
    // Get the report first to decrement counters
    final report = await _client
        .from(AppConstants.conductReportsTable)
        .select('student_id, type')
        .eq('id', reportId)
        .single();

    await _client
        .from(AppConstants.conductReportsTable)
        .delete()
        .eq('id', reportId);

    // Decrement student counters
    final reportType = report['type'] as String;
    if (reportType == 'positive') {
      await _client.rpc(
        'decrement_positive_reports',
        params: {'student_id': report['student_id']},
      );
    } else {
      await _client.rpc(
        'decrement_negative_reports',
        params: {'student_id': report['student_id']},
      );
    }

    await _logAudit(
      action: 'DELETE',
      tableName: AppConstants.conductReportsTable,
      recordId: reportId,
    );
  }

  // ***** BAP RECORDS *****

  Future<List<models.BAPRecord>> getBAPRecords({
    String? studentId,
    BAPType? type,
    String? status,
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
  }) async {
    var query = _client.from(AppConstants.bapRecordsTable).select('''
          *,
          detected_by_user:users!detected_by(first_name, last_name),
          progress_notes
        ''');

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    if (type != null) {
      query = query.eq('type', type.name);
    }

    if (status != null) {
      query = query.eq('current_status', status);
    }

    final response = await query
        .order('detection_date', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>).map((json) {
      final detectedByData = json['detected_by_user'] as Map<String, dynamic>?;
      final detectedByName = detectedByData != null
          ? '${detectedByData['first_name']} ${detectedByData['last_name']}'
          : null;

      // Parse progress notes
      List<models.BAPFollowUp> followUps = [];
      if (json['progress_notes'] != null) {
        final notes = json['progress_notes'] as List<dynamic>;
        followUps = notes
            .map(
              (note) =>
                  models.BAPFollowUp.fromJson(note as Map<String, dynamic>),
            )
            .toList();
      }

      return models.BAPRecord.fromJson({
        ...json,
        'identified_by_name': detectedByName,
        'follow_ups': followUps,
      });
    }).toList();
  }

  Future<models.BAPRecord?> getBAPRecordById(String id) async {
    final response = await _client
        .from(AppConstants.bapRecordsTable)
        .select('''
          *,
          detected_by_user:users!detected_by(first_name, last_name),
          progress_notes
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    final detectedByData =
        response['detected_by_user'] as Map<String, dynamic>?;
    final detectedByName = detectedByData != null
        ? '${detectedByData['first_name']} ${detectedByData['last_name']}'
        : null;

    // Parse progress notes
    List<models.BAPFollowUp> followUps = [];
    if (response['progress_notes'] != null) {
      final notes = response['progress_notes'] as List<dynamic>;
      followUps = notes
          .map(
            (note) => models.BAPFollowUp.fromJson(note as Map<String, dynamic>),
          )
          .toList();
    }

    return models.BAPRecord.fromJson({
      ...response,
      'identified_by_name': detectedByName,
      'follow_ups': followUps,
    });
  }

  Future<List<models.BAPRecord>> getBAPRecordsWithPendingFollowUp() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final response = await _client
        .from(AppConstants.bapRecordsTable)
        .select('''
          *,
          detected_by_user:users!detected_by(first_name, last_name),
          progress_notes
        ''')
        .eq('is_active', true)
        .or('current_status.eq.active,current_status.eq.in_progress');

    final records = (response as List<dynamic>).map((json) {
      final detectedByData = json['detected_by_user'] as Map<String, dynamic>?;
      final detectedByName = detectedByData != null
          ? '${detectedByData['first_name']} ${detectedByData['last_name']}'
          : null;

      List<models.BAPFollowUp> followUps = [];
      if (json['progress_notes'] != null) {
        final notes = json['progress_notes'] as List<dynamic>;
        followUps = notes
            .map(
              (note) =>
                  models.BAPFollowUp.fromJson(note as Map<String, dynamic>),
            )
            .toList();
      }

      return models.BAPRecord.fromJson({
        ...json,
        'identified_by_name': detectedByName,
        'follow_ups': followUps,
      });
    }).toList();

    // Filter records that need follow-up (no follow-up in last 30 days)
    return records.where((record) {
      if (record.followUps.isEmpty) return true;

      final lastFollowUp = record.followUps.reduce(
        (a, b) => a.followUpDate.isAfter(b.followUpDate) ? a : b,
      );

      return lastFollowUp.followUpDate.isBefore(thirtyDaysAgo);
    }).toList();
  }

  Future<models.BAPRecord> createBAPRecord(models.BAPRecord record) async {
    final recordData = {
      'student_id': record.studentId,
      'detected_by': record.identifiedById,
      'type': record.type.name,
      'title': record.title,
      'description': record.description,
      'detection_date': record.detectionDate.toIso8601String(),
      'intervention_strategies': record.interventionStrategies.join('\n'),
      'current_status': record.currentStatus ?? 'active',
      'documents': record.attachmentUrls,
      'is_active': true,
      'progress_notes': [],
    };

    final response = await _client
        .from(AppConstants.bapRecordsTable)
        .insert(recordData)
        .select('''
          *,
          detected_by_user:users!detected_by(first_name, last_name)
        ''')
        .single();

    await _logAudit(
      action: 'INSERT', // Changed from 'create' to match schema constraint
      tableName: AppConstants.bapRecordsTable,
      recordId: response['id'],
    );

    return await getBAPRecordById(response['id']) ?? record;
  }

  Future<models.BAPRecord> updateBAPRecord(models.BAPRecord record) async {
    final updateData = {
      'type': record.type.name,
      'title': record.title,
      'description': record.description,
      'detection_date': record.detectionDate.toIso8601String(),
      'intervention_strategies': record.interventionStrategies.join('\n'),
      'current_status': record.currentStatus,
      'documents': record.attachmentUrls,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client
        .from(AppConstants.bapRecordsTable)
        .update(updateData)
        .eq('id', record.id);

    await _logAudit(
      action: 'UPDATE', // Changed from 'update'
      tableName: AppConstants.bapRecordsTable,
      recordId: record.id,
    );

    return await getBAPRecordById(record.id) ?? record;
  }

  Future<models.BAPRecord> addBAPFollowUp(
    String recordId,
    models.BAPFollowUp followUp,
  ) async {
    // Get current record
    final record = await getBAPRecordById(recordId);
    if (record == null) {
      throw Exception('BAP record not found');
    }

    // Get current progress notes
    final currentNotes = record.followUps.map((f) => f.toJson()).toList();

    // Add new follow-up
    final newFollowUpData = {
      'id': followUp.id,
      'bap_record_id': recordId,
      'follow_up_by_id': followUp.followUpById,
      'follow_up_date': followUp.followUpDate.toIso8601String(),
      'observations': followUp.observations,
      'evolution': followUp.evolution,
      'updated_strategies': followUp.updatedStrategies,
      'next_steps': followUp.nextSteps,
      'next_follow_up_date': followUp.nextFollowUpDate?.toIso8601String(),
      'attachment_urls': followUp.attachmentUrls,
      'created_at': DateTime.now().toIso8601String(),
    };

    currentNotes.add(newFollowUpData);

    // Update record with new progress notes
    await _client
        .from(AppConstants.bapRecordsTable)
        .update({
          'progress_notes': currentNotes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId);

    await _logAudit(
      action: 'UPDATE',
      tableName: AppConstants.bapRecordsTable,
      recordId: recordId,
      reason: 'Seguimiento agregado',
    );

    return await getBAPRecordById(recordId) ?? record;
  }

  Future<void> deleteBAPRecord(String id) async {
    await _client
        .from(AppConstants.bapRecordsTable)
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);

    await _logAudit(
      action: 'DELETE', // Changed from 'delete'
      tableName: AppConstants.bapRecordsTable,
      recordId: id,
    );
  }

  // ***** REGISTROS DE ACTITUDES *****

  Future<List<models.AttitudeRecord>> getAttitudeRecords({
    String? studentId,
    String? attitudeType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
  }) async {
    var query = _client.from(AppConstants.attitudesTable).select('''
          *,
          observer:users!observed_by(first_name, last_name)
        ''');

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    if (attitudeType != null) {
      query = query.eq('attitude_type', attitudeType);
    }

    if (startDate != null) {
      query = query.gte('observation_date', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('observation_date', endDate.toIso8601String());
    }

    final response = await query
        .order('observation_date', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>).map((json) {
      final observerData = json['observer'] as Map<String, dynamic>?;
      final observedByName = observerData != null
          ? '${observerData['first_name']} ${observerData['last_name']}'
          : null;

      return models.AttitudeRecord.fromJson({
        ...json,
        'observed_by_name': observedByName,
      });
    }).toList();
  }

  Future<models.AttitudeRecord> createAttitudeRecord(
    models.AttitudeRecord record,
  ) async {
    final response = await _client
        .from(AppConstants.attitudesTable)
        .insert(record.toJson())
        .select()
        .single();

    await _logAudit(
      action: 'INSERT',
      tableName: AppConstants.attitudesTable,
      recordId: response['id'],
    );

    return models.AttitudeRecord.fromJson(response);
  }

  Future<models.AttitudeRecord> updateAttitudeRecord(
    models.AttitudeRecord record,
  ) async {
    final updateData = record.toJson();
    updateData['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from(AppConstants.attitudesTable)
        .update(updateData)
        .eq('id', record.id)
        .select()
        .single();

    await _logAudit(
      action: 'UPDATE',
      tableName: AppConstants.attitudesTable,
      recordId: record.id,
    );

    return models.AttitudeRecord.fromJson(response);
  }

  Future<void> deleteAttitudeRecord(String id) async {
    await _client.from(AppConstants.attitudesTable).delete().eq('id', id);

    await _logAudit(
      action: 'DELETE',
      tableName: AppConstants.attitudesTable,
      recordId: id,
    );
  }

  // ***** AUDITORÍA *****

  Future<void> _logAudit({
    required String action,
    required String tableName,
    String? recordId,
    String? reason,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return;

    // Map common actions to valid CHECK constraint values
    String validAction;
    switch (action.toLowerCase()) {
      case 'create':
      case 'insert':
        validAction = 'INSERT';
        break;
      case 'update':
      case 'edit':
        validAction = 'UPDATE';
        break;
      case 'delete':
      case 'remove':
        validAction = 'DELETE';
        break;
      default:
        validAction = action.toUpperCase();
    }

    await _client.from(AppConstants.auditLogsTable).insert({
      'user_id': currentUser.id,
      'user_email': currentUser.email,
      'action': validAction, // Must be 'INSERT', 'UPDATE', or 'DELETE'
      'table_name': tableName,
      'record_id': recordId,
      'reason': reason,
    });
  }

  // ***** REPORTES Y ESTADÍSTICAS *****

  Future<Map<String, dynamic>> getDashboardStats() async {
    final stats = <String, dynamic>{};

    try {
      // Total de estudiantes activos
      final studentsResponse = await _client
          .from(AppConstants.studentsTable)
          .select('id')
          .eq('is_active', true);
      stats['total_students'] = (studentsResponse as List).length;

      // Reportes de conducta del mes actual
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final conductReportsResponse = await _client
          .from(AppConstants.conductReportsTable)
          .select('id')
          .gte('created_at', startOfMonth.toIso8601String());
      stats['monthly_conduct_reports'] =
          (conductReportsResponse as List).length;

      // BAP activos
      final bapResponse = await _client
          .from(AppConstants.bapRecordsTable)
          .select('id');
      stats['active_bap'] = (bapResponse as List).length;
    } catch (e) {
      // En caso de error, retornar valores por defecto
      stats['total_students'] = 0;
      stats['monthly_conduct_reports'] = 0;
      stats['active_bap'] = 0;
    }

    return stats;
  }

  // ***** ARCHIVOS *****

  Future<String> uploadFile(String bucket, String path, Uint8List bytes) async {
    try {
      // Upload the file with upsert option to overwrite if exists
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get the public URL
      final url = _client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Error uploading file to $bucket/$path: ${e.toString()}');
    }
  }

  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception(
        'Error deleting file from $bucket/$path: ${e.toString()}',
      );
    }
  }
}
