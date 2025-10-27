import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as models;
import '../core/constants.dart';
import 'database_service.dart';

class MedicalService {
  final DatabaseService _databaseService = DatabaseService();

  SupabaseClient get _client => _databaseService.client;

  // ***** EXPEDIENTES MÉDICOS *****

  /// Obtener expediente médico por ID de estudiante
  Future<models.MedicalRecord?> getMedicalRecordByStudentId(
    String studentId,
  ) async {
    try {
      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .select('''
            *,
            students!inner(
              id,
              first_name,
              last_name,
              curp,
              enrollment
            )
          ''')
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) return null;
      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener expediente médico: $e');
    }
  }

  /// Obtener expediente médico por ID
  Future<models.MedicalRecord?> getMedicalRecordById(String id) async {
    try {
      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .select('''
            *,
            students!inner(
              id,
              first_name,
              last_name,
              curp,
              enrollment
            )
          ''')
          .eq('id', id)
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener expediente médico: $e');
    }
  }

  /// Listar todos los expedientes médicos con filtros
  Future<List<models.MedicalRecord>> getMedicalRecords({
    String? search,
    String? grade,
    String? group,
    DateTime? startDate,
    DateTime? endDate,
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _client.from(AppConstants.medicalRecordsTable).select('''
        *,
        students!inner(
          id,
          first_name,
          last_name,
          curp,
          enrollment,
          grade,
          group
        )
      ''');

      if (search != null && search.isNotEmpty) {
        // Use or() with proper foreign table reference syntax
        query = query.or(
          'emergency_contact_name.ilike.%$search%,'
          'students.first_name.ilike.%$search%,'
          'students.last_name.ilike.%$search%,'
          'students.curp.ilike.%$search%,'
          'students.enrollment.ilike.%$search%',
        );
      }

      // Filter by grade
      if (grade != null && grade.isNotEmpty) {
        query = query.eq('students.grade', grade);
      }

      // Filter by group
      if (group != null && group.isNotEmpty) {
        query = query.eq('students.group', group);
      }

      // Filter by date range
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map(
            (json) =>
                models.MedicalRecord.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Error al obtener expedientes médicos: $e');
    }
  }

  /// Crear expediente médico
  Future<models.MedicalRecord> createMedicalRecord(
    models.MedicalRecord record,
  ) async {
    try {
      final currentUser = await _databaseService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final recordData = record.toJson();
      recordData['created_by'] = currentUser.id;
      recordData['created_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .insert(recordData)
          .select()
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear expediente médico: $e');
    }
  }

  /// Actualizar expediente médico
  Future<models.MedicalRecord> updateMedicalRecord(
    models.MedicalRecord record,
  ) async {
    try {
      final currentUser = await _databaseService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final recordData = record.toJson();
      recordData['updated_by'] = currentUser.id;
      recordData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .update(recordData)
          .eq('id', record.id)
          .select()
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar expediente médico: $e');
    }
  }

  /// Eliminar expediente médico
  Future<void> deleteMedicalRecord(String id) async {
    try {
      await _client
          .from(AppConstants.medicalRecordsTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar expediente médico: $e');
    }
  }

  // ***** DIAGNÓSTICOS *****

  /// Agregar diagnóstico a un expediente médico
  Future<models.MedicalRecord> addDiagnosis(
    String medicalRecordId,
    models.MedicalDiagnosis diagnosis,
  ) async {
    try {
      // Obtener el expediente actual
      final record = await getMedicalRecordById(medicalRecordId);
      if (record == null) {
        throw Exception('Expediente médico no encontrado');
      }

      // Agregar el nuevo diagnóstico
      final updatedDiagnoses = [...record.diagnoses, diagnosis];

      // Actualizar el campo diagnoses en la base de datos
      final diagnosesJson = updatedDiagnoses.map((d) => d.toJson()).toList();

      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .update({
            'diagnoses': diagnosesJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', medicalRecordId)
          .select()
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al agregar diagnóstico: $e');
    }
  }

  /// Actualizar diagnóstico
  Future<models.MedicalRecord> updateDiagnosis(
    String medicalRecordId,
    models.MedicalDiagnosis diagnosis,
  ) async {
    try {
      final record = await getMedicalRecordById(medicalRecordId);
      if (record == null) {
        throw Exception('Expediente médico no encontrado');
      }

      // Actualizar el diagnóstico específico
      final updatedDiagnoses = record.diagnoses.map((d) {
        return d.id == diagnosis.id ? diagnosis : d;
      }).toList();

      final diagnosesJson = updatedDiagnoses.map((d) => d.toJson()).toList();

      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .update({
            'diagnoses': diagnosesJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', medicalRecordId)
          .select()
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar diagnóstico: $e');
    }
  }

  /// Eliminar diagnóstico
  Future<models.MedicalRecord> deleteDiagnosis(
    String medicalRecordId,
    String diagnosisId,
  ) async {
    try {
      final record = await getMedicalRecordById(medicalRecordId);
      if (record == null) {
        throw Exception('Expediente médico no encontrado');
      }

      final updatedDiagnoses = record.diagnoses
          .where((d) => d.id != diagnosisId)
          .toList();

      final diagnosesJson = updatedDiagnoses.map((d) => d.toJson()).toList();

      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .update({
            'diagnoses': diagnosesJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', medicalRecordId)
          .select()
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al eliminar diagnóstico: $e');
    }
  }

  // ***** SEGUIMIENTOS MÉDICOS *****

  /// Agregar seguimiento médico
  Future<models.MedicalRecord> addFollowUp(
    String medicalRecordId,
    models.MedicalFollowUp followUp,
  ) async {
    try {
      final record = await getMedicalRecordById(medicalRecordId);
      if (record == null) {
        throw Exception('Expediente médico no encontrado');
      }

      final updatedFollowUps = [...record.followUps, followUp];
      final followUpsJson = updatedFollowUps.map((f) => f.toJson()).toList();

      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .update({
            'medical_events': followUpsJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', medicalRecordId)
          .select()
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al agregar seguimiento: $e');
    }
  }

  /// Actualizar seguimiento médico
  Future<models.MedicalRecord> updateFollowUp(
    String medicalRecordId,
    models.MedicalFollowUp followUp,
  ) async {
    try {
      final record = await getMedicalRecordById(medicalRecordId);
      if (record == null) {
        throw Exception('Expediente médico no encontrado');
      }

      final updatedFollowUps = record.followUps.map((f) {
        return f.id == followUp.id ? followUp : f;
      }).toList();

      final followUpsJson = updatedFollowUps.map((f) => f.toJson()).toList();

      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .update({
            'medical_events': followUpsJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', medicalRecordId)
          .select()
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar seguimiento: $e');
    }
  }

  /// Eliminar seguimiento médico
  Future<models.MedicalRecord> deleteFollowUp(
    String medicalRecordId,
    String followUpId,
  ) async {
    try {
      final record = await getMedicalRecordById(medicalRecordId);
      if (record == null) {
        throw Exception('Expediente médico no encontrado');
      }

      final updatedFollowUps = record.followUps
          .where((f) => f.id != followUpId)
          .toList();

      final followUpsJson = updatedFollowUps.map((f) => f.toJson()).toList();

      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .update({
            'medical_events': followUpsJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', medicalRecordId)
          .select()
          .single();

      return models.MedicalRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al eliminar seguimiento: $e');
    }
  }

  // ***** ESTADÍSTICAS Y REPORTES *****

  /// Obtener padecimientos activos de un estudiante
  Future<List<models.MedicalDiagnosis>> getActiveDiagnoses(
    String studentId,
  ) async {
    try {
      final record = await getMedicalRecordByStudentId(studentId);
      if (record == null) return [];

      return record.diagnoses.where((d) => d.isActive).toList();
    } catch (e) {
      throw Exception('Error al obtener diagnósticos activos: $e');
    }
  }

  /// Obtener historial de seguimientos
  Future<List<models.MedicalFollowUp>> getFollowUpHistory(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final record = await getMedicalRecordByStudentId(studentId);
      if (record == null) return [];

      var followUps = record.followUps;

      if (startDate != null) {
        followUps = followUps
            .where((f) => f.followUpDate.isAfter(startDate))
            .toList();
      }

      if (endDate != null) {
        followUps = followUps
            .where((f) => f.followUpDate.isBefore(endDate))
            .toList();
      }

      followUps.sort((a, b) => b.followUpDate.compareTo(a.followUpDate));

      return followUps;
    } catch (e) {
      throw Exception('Error al obtener historial de seguimientos: $e');
    }
  }

  /// Contar expedientes con alergias
  Future<int> countRecordsWithAllergies() async {
    try {
      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .select()
          .not('allergies', 'is', null)
          .not('allergies', 'eq', '');

      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar registros con alergias: $e');
    }
  }

  /// Contar expedientes con condiciones crónicas
  Future<int> countRecordsWithChronicConditions() async {
    try {
      final response = await _client
          .from(AppConstants.medicalRecordsTable)
          .select()
          .not('chronic_conditions', 'is', null)
          .not('chronic_conditions', 'eq', '');

      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar registros con condiciones crónicas: $e');
    }
  }

  /// Obtener próximos seguimientos programados
  Future<List<models.MedicalFollowUp>> getUpcomingFollowUps({
    int daysAhead = 30,
  }) async {
    try {
      final records = await getMedicalRecords(limit: 1000);
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      final upcomingFollowUps = <models.MedicalFollowUp>[];

      for (final record in records) {
        for (final followUp in record.followUps) {
          if (followUp.followUpDate.isAfter(now) &&
              followUp.followUpDate.isBefore(futureDate)) {
            upcomingFollowUps.add(followUp);
          }
        }
      }

      upcomingFollowUps.sort(
        (a, b) => a.followUpDate.compareTo(b.followUpDate),
      );

      return upcomingFollowUps;
    } catch (e) {
      throw Exception('Error al obtener seguimientos próximos: $e');
    }
  }
}
