import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../core/constants.dart';
import 'database_service.dart';
import 'pdf_report_service.dart';

class FinalReportService {
  final DatabaseService _databaseService = DatabaseService();
  final PDFReportService _pdfReportService = PDFReportService();

  /// Get all final reports with optional filters
  Future<List<FinalReport>> getFinalReports({
    String? studentId,
    String? schoolYear,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _databaseService.client
          .from(AppConstants.finalReportsTable)
          .select('*');

      if (studentId != null) {
        query = query.eq('student_id', studentId);
      }

      if (schoolYear != null) {
        query = query.eq('school_year', schoolYear);
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;
      return (response as List).map((json) => _parseFinalReport(json)).toList();
    } catch (e) {
      debugPrint('Error getting final reports: $e');
      rethrow;
    }
  }

  /// Get a specific final report by ID
  Future<FinalReport?> getFinalReportById(String reportId) async {
    try {
      final response = await _databaseService.client
          .from(AppConstants.finalReportsTable)
          .select('*')
          .eq('id', reportId)
          .single();

      return _parseFinalReport(response);
    } catch (e) {
      debugPrint('Error getting final report by ID: $e');
      return null;
    }
  }

  /// Get final report for a student in a specific school year
  Future<FinalReport?> getFinalReportByStudentAndYear(
    String studentId,
    String schoolYear,
  ) async {
    try {
      final response = await _databaseService.client
          .from(AppConstants.finalReportsTable)
          .select('*')
          .eq('student_id', studentId)
          .eq('school_year', schoolYear)
          .maybeSingle();

      if (response == null) return null;
      return _parseFinalReport(response);
    } catch (e) {
      debugPrint('Error getting final report by student and year: $e');
      return null;
    }
  }

  /// Generate a new final report for a student
  Future<FinalReport> generateFinalReport(
    String studentId,
    String schoolYear,
  ) async {
    try {
      // Get student data
      final student = await _databaseService.getStudentById(studentId);
      if (student == null) {
        throw Exception('Student not found');
      }

      // Get conduct reports for the school year
      final conductReports = await _databaseService.getConductReports(
        studentId: studentId,
      );

      // Get BAP records
      final bapRecords = await _databaseService.getBAPRecords(
        studentId: studentId,
      );

      // Get medical record
      final medicalRecord = await _getMedicalRecord(studentId);

      // Get attitude records
      final attitudeRecords = await _databaseService.getAttitudeRecords(
        studentId: studentId,
      );

      // Build summaries
      final conductualSummary = _buildConductualSummary(conductReports);
      final bapSummary = _buildBAPSummary(bapRecords);
      final medicalSummary = _buildMedicalSummary(medicalRecord);
      final attitudesSummary = _buildAttitudesSummary(attitudeRecords);

      // Calculate conduct classification
      final conductClassification = _calculateConductClassification(
        conductualSummary.totalPositiveReports,
        conductualSummary.totalNegativeReports,
      );

      // Calculate índice de robustez (BMI-like calculation)
      double? indiceRobustez;
      if (student.peso != null &&
          student.estatura != null &&
          student.estatura! > 0) {
        // Simple robustness index: peso / estatura
        indiceRobustez = student.peso! / student.estatura!;
      }

      // Prepare report data
      final currentUser = _databaseService.client.auth.currentUser;
      final reportData = {
        'student_id': studentId,
        'school_year': schoolYear,

        // Conduct data
        'conduct_summary': _generateConductSummary(conductReports),
        'total_positive_reports': conductualSummary.totalPositiveReports,
        'total_negative_reports': conductualSummary.totalNegativeReports,
        // Convert to JSONB array
        'highlighted_incidents': conductualSummary.highlightedIncidents
            .map((i) => i.toJson())
            .toList(),
        'severity_breakdown': conductualSummary.severityBreakdown,

        // BAP data
        'bap_summary': _generateBAPSummary(bapRecords),
        'total_active_bap': bapSummary.totalActiveBAP,
        'bap_type_breakdown': bapSummary.bapTypeBreakdown,
        // Convert to JSONB array
        'bap_evolution_summary': bapSummary.evolutionSummary
            .map((e) => e.toJson())
            .toList(),

        // Medical data
        'medical_summary': _generateMedicalSummary(medicalRecord),
        // Convert list to text (comma-separated) or keep as array if JSONB
        'active_conditions': medicalSummary.activeConditions.isEmpty
            ? null
            : medicalSummary.activeConditions.join(', '),
        // Convert to JSONB array
        'current_medications': medicalSummary.currentMedications,
        // Convert to JSONB array
        'active_allergies': medicalSummary.activeAllergies,
        'blood_type': medicalSummary.bloodType,

        // Attitudes data
        'predominant_attitudes': _generateAttitudesSummary(attitudeRecords),
        // Convert to JSONB array
        'positive_attitudes': attitudesSummary.positiveAttitudes
            .map((a) => a.toJson())
            .toList(),
        // Convert to JSONB array
        'negative_attitudes': attitudesSummary.negativeAttitudes
            .map((a) => a.toJson())
            .toList(),
        'frequency_analysis': attitudesSummary.frequencyAnalysis,

        // Recommendations
        'recommendations': _generateRecommendations(
          conductReports,
          bapRecords,
          attitudeRecords,
        ),
        'areas_of_opportunity': _generateAreasOfOpportunity(
          conductReports,
          attitudeRecords,
        ),
        'identified_strengths': _generateStrengths(
          conductReports,
          attitudeRecords,
        ),

        'conduct_classification': conductClassification,

        // Student summary (denormalized)
        'student_full_name': student.fullName,
        'student_curp': student.curp,
        'student_institutional_id': student.institutionalId,
        'student_enrollment': student.enrollment,
        'student_grade': student.grade.displayName,
        'student_group': student.group,
        'student_profile_image_url': student.profileImageUrl,

        // Ficha Pedagógica fields
        'student_birth_date': student.birthDate?.toIso8601String(),
        'student_sexo': student.sexo,
        'student_tutor': student.tutor,
        'student_calle': student.calle,
        'student_numero': student.numero,
        'student_colonia': student.colonia,
        'student_localidad': student.localidad,
        'student_municipio': student.municipio,
        'student_codigo_postal': student.codigoPostal,
        'student_telefono': student.telefono,
        'student_peso': student.peso,
        'student_estatura': student.estatura,
        'student_indice_robustez': indiceRobustez,

        // Additional fields
        'situacion_socioeconomica': student.situacion,
        'conducta_alumno': _generateConductDescription(conductClassification),

        'generated_by': currentUser?.id,
        'generation_date': DateTime.now().toIso8601String(),
      };

      final response = await _databaseService.client
          .from(AppConstants.finalReportsTable)
          .insert(reportData)
          .select()
          .single();

      return _parseFinalReport(response);
    } catch (e) {
      debugPrint('Error generating final report: $e');
      rethrow;
    }
  }

  /// Update an existing final report
  Future<FinalReport> updateFinalReport(
    String reportId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _databaseService.client
          .from(AppConstants.finalReportsTable)
          .update(updates)
          .eq('id', reportId)
          .select()
          .single();

      return _parseFinalReport(response);
    } catch (e) {
      debugPrint('Error updating final report: $e');
      rethrow;
    }
  }

  /// Delete a final report
  Future<void> deleteFinalReport(String reportId) async {
    try {
      await _databaseService.client
          .from(AppConstants.finalReportsTable)
          .delete()
          .eq('id', reportId);
    } catch (e) {
      debugPrint('Error deleting final report: $e');
      rethrow;
    }
  }

  /// Generate PDF for final report (Informe Final)
  Future<String> generateFinalReportPDF(String reportId) async {
    try {
      final report = await getFinalReportById(reportId);
      if (report == null) {
        throw Exception('Report not found');
      }

      // Generate PDF using PDFReportService
      final pdfUrl = await _pdfReportService.generateFinalReportPDF(report);

      // Update report with PDF URL
      await updateFinalReport(reportId, {'pdf_url': pdfUrl});

      return pdfUrl;
    } catch (e) {
      debugPrint('Error generating final report PDF: $e');
      rethrow;
    }
  }

  /// Generate PDF for Ficha Pedagógica
  Future<String> generateFichaPedagogicaPDF(String reportId) async {
    try {
      final report = await getFinalReportById(reportId);
      if (report == null) {
        throw Exception('Report not found');
      }

      // Generate PDF using PDFReportService
      final pdfUrl = await _pdfReportService.generateFichaPedagogicaPDF(report);

      // Update report with Ficha Pedagógica PDF URL
      await updateFinalReport(reportId, {'ficha_pedagogica_pdf_url': pdfUrl});

      return pdfUrl;
    } catch (e) {
      debugPrint('Error generating Ficha Pedagógica PDF: $e');
      rethrow;
    }
  }

  // Private helper methods

  Future<MedicalRecord?> _getMedicalRecord(String studentId) async {
    try {
      final response = await _databaseService.client
          .from(AppConstants.medicalRecordsTable)
          .select('*')
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) return null;
      return MedicalRecord.fromJson(response);
    } catch (e) {
      debugPrint('Error getting medical record: $e');
      return null;
    }
  }

  ConductualSummary _buildConductualSummary(List<ConductReport> reports) {
    final positiveReports = reports
        .where((r) => r.type == ConductReportType.positive)
        .toList();
    final negativeReports = reports
        .where((r) => r.type == ConductReportType.negative)
        .toList();

    // Get severity breakdown
    final severityBreakdown = <String, int>{};
    for (final report in negativeReports) {
      if (report.severity != null) {
        final key = report.severity!.name;
        severityBreakdown[key] = (severityBreakdown[key] ?? 0) + 1;
      }
    }

    // Get highlighted incidents (most severe or recent)
    final highlighted = negativeReports
        .where(
          (r) =>
              r.severity == IncidentSeverity.severe ||
              r.severity == IncidentSeverity.verySevere,
        )
        .take(5)
        .map(
          (r) => HighlightedIncident(
            title: r.title,
            description: r.description,
            date: r.incidentDate,
            severity: r.severity?.name ?? 'unknown',
            type: r.type.name,
          ),
        )
        .toList();

    return ConductualSummary(
      totalPositiveReports: positiveReports.length,
      totalNegativeReports: negativeReports.length,
      highlightedIncidents: highlighted,
      severityBreakdown: severityBreakdown,
    );
  }

  BAPSummary _buildBAPSummary(List<BAPRecord> records) {
    final activeRecords = records
        .where((r) => r.currentStatus == 'active' || r.currentStatus == null)
        .toList();

    final typeBreakdown = <String, int>{};
    for (final record in activeRecords) {
      final key = record.type.name;
      typeBreakdown[key] = (typeBreakdown[key] ?? 0) + 1;
    }

    final evolution = activeRecords
        .map(
          (r) => BAPEvolution(
            title: r.title,
            type: r.type.name,
            currentStatus: r.currentStatus ?? 'active',
            followUpCount: r.followUps.length,
          ),
        )
        .toList();

    return BAPSummary(
      totalActiveBAP: activeRecords.length,
      bapTypeBreakdown: typeBreakdown,
      evolutionSummary: evolution,
    );
  }

  MedicalSummary _buildMedicalSummary(MedicalRecord? record) {
    if (record == null) {
      return MedicalSummary(
        activeConditions: [],
        currentMedications: [],
        activeAllergies: [],
      );
    }

    return MedicalSummary(
      bloodType: record.bloodType?.displayName,
      activeConditions: record.chronicConditions.isNotEmpty
          ? record.chronicConditions
          : [],
      currentMedications: record.currentMedications.isNotEmpty
          ? record.currentMedications
          : [],
      activeAllergies: record.knownAllergies.isNotEmpty
          ? record.knownAllergies
          : [],
    );
  }

  AttitudesSummary _buildAttitudesSummary(List<AttitudeRecord> records) {
    final positiveRecords = records
        .where((r) => r.attitudeType == 'positive')
        .toList();
    final negativeRecords = records
        .where((r) => r.attitudeType == 'negative')
        .toList();

    // Group by title and count frequency
    final positiveFreq = <String, List<AttitudeRecord>>{};
    for (final record in positiveRecords) {
      positiveFreq.putIfAbsent(record.title, () => []).add(record);
    }

    final negativeFreq = <String, List<AttitudeRecord>>{};
    for (final record in negativeRecords) {
      negativeFreq.putIfAbsent(record.title, () => []).add(record);
    }

    final positiveAttitudes =
        positiveFreq.entries
            .map(
              (e) => PredominantAttitude(
                title: e.key,
                description: e.value.first.description,
                frequency: e.value.length,
              ),
            )
            .toList()
          ..sort((a, b) => b.frequency.compareTo(a.frequency));

    final negativeAttitudes =
        negativeFreq.entries
            .map(
              (e) => PredominantAttitude(
                title: e.key,
                description: e.value.first.description,
                frequency: e.value.length,
              ),
            )
            .toList()
          ..sort((a, b) => b.frequency.compareTo(a.frequency));

    final frequencyAnalysis = <String, int>{
      'total_positive': positiveRecords.length,
      'total_negative': negativeRecords.length,
    };

    return AttitudesSummary(
      positiveAttitudes: positiveAttitudes.take(5).toList(),
      negativeAttitudes: negativeAttitudes.take(5).toList(),
      frequencyAnalysis: frequencyAnalysis,
    );
  }

  String _calculateConductClassification(int positive, int negative) {
    if (negative == 0 && positive >= 5) return 'excellent';
    if (negative <= 2 && positive >= 3) return 'good';
    if (negative <= 5) return 'regular';
    return 'needs_attention';
  }

  String _generateConductSummary(List<ConductReport> reports) {
    final positive = reports
        .where((r) => r.type == ConductReportType.positive)
        .length;
    final negative = reports
        .where((r) => r.type == ConductReportType.negative)
        .length;

    return 'Durante el ciclo escolar, el estudiante registró $positive reportes positivos y $negative reportes negativos. '
        '${negative == 0
            ? 'Ha mantenido una conducta ejemplar durante todo el periodo.'
            : negative <= 2
            ? 'Ha mostrado un comportamiento generalmente apropiado con algunas áreas de mejora.'
            : 'Requiere seguimiento continuo en aspectos conductuales.'}';
  }

  String _generateBAPSummary(List<BAPRecord> records) {
    final active = records
        .where((r) => r.currentStatus == 'active' || r.currentStatus == null)
        .length;
    if (active == 0) {
      return 'No se registraron barreras de aprendizaje activas durante el ciclo escolar.';
    }

    final types = records.map((r) => r.type.displayName).toSet().join(', ');
    return 'Se identificaron $active barreras de aprendizaje activas en las áreas de: $types. '
        'Se han implementado estrategias de intervención y seguimiento continuo.';
  }

  String _generateMedicalSummary(MedicalRecord? record) {
    if (record == null) {
      return 'No se registró información médica durante el ciclo escolar.';
    }

    final conditions = <String>[];
    if (record.chronicConditions.isNotEmpty) {
      conditions.add(
        'condiciones crónicas: ${record.chronicConditions.join(", ")}',
      );
    }
    if (record.knownAllergies.isNotEmpty) {
      conditions.add('alergias: ${record.knownAllergies.join(", ")}');
    }

    if (conditions.isEmpty) {
      return 'El estudiante no reporta condiciones médicas significativas.';
    }

    return 'Información médica relevante: ${conditions.join("; ")}. '
        '${record.currentMedications.isNotEmpty ? "Medicación actual: ${record.currentMedications.join(", ")}." : ""}';
  }

  String _generateAttitudesSummary(List<AttitudeRecord> records) {
    if (records.isEmpty) {
      return 'No se registraron actitudes predominantes durante el ciclo escolar.';
    }

    final positive = records
        .where((r) => r.attitudeType == 'positive')
        .toList();
    final negative = records
        .where((r) => r.attitudeType == 'negative')
        .toList();

    final parts = <String>[];
    if (positive.isNotEmpty) {
      parts.add(
        'Se observaron actitudes positivas como: ${positive.take(3).map((r) => r.title).join(", ")}',
      );
    }
    if (negative.isNotEmpty) {
      parts.add(
        'Actitudes que requieren atención: ${negative.take(3).map((r) => r.title).join(", ")}',
      );
    }

    return '${parts.join('. ')}.';
  }

  String _generateRecommendations(
    List<ConductReport> conductReports,
    List<BAPRecord> bapRecords,
    List<AttitudeRecord> attitudeRecords,
  ) {
    final recommendations = <String>[];

    // Conduct recommendations
    final negative = conductReports
        .where((r) => r.type == ConductReportType.negative)
        .length;
    if (negative > 3) {
      recommendations.add(
        'Mantener seguimiento cercano en aspectos conductuales',
      );
      recommendations.add('Reforzar valores de convivencia y respeto');
    }

    // BAP recommendations
    if (bapRecords
        .where((r) => r.currentStatus == 'active' || r.currentStatus == null)
        .isNotEmpty) {
      recommendations.add('Continuar con estrategias de apoyo personalizadas');
      recommendations.add('Mantener comunicación constante con familia');
    }

    // Attitude recommendations
    final negativeAttitudes = attitudeRecords
        .where((r) => r.attitudeType == 'negative')
        .length;
    if (negativeAttitudes > 2) {
      recommendations.add(
        'Trabajar en el desarrollo de habilidades socioemocionales',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Continuar fomentando el desarrollo integral del estudiante',
      );
    }

    return recommendations.join('\n• ');
  }

  String _generateAreasOfOpportunity(
    List<ConductReport> conductReports,
    List<AttitudeRecord> attitudeRecords,
  ) {
    final areas = <String>[];

    // From conduct reports
    final negativeReports = conductReports
        .where((r) => r.type == ConductReportType.negative)
        .toList();
    for (final report in negativeReports.take(3)) {
      areas.add(report.title);
    }

    // From negative attitudes
    final negativeAttitudes = attitudeRecords
        .where((r) => r.attitudeType == 'negative')
        .toList();
    for (final attitude in negativeAttitudes.take(3)) {
      if (!areas.contains(attitude.title)) {
        areas.add(attitude.title);
      }
    }

    if (areas.isEmpty) {
      return 'El estudiante ha demostrado un desempeño consistente sin áreas críticas identificadas.';
    }

    return '• ${areas.take(5).join('\n• ')}';
  }

  String _generateStrengths(
    List<ConductReport> conductReports,
    List<AttitudeRecord> attitudeRecords,
  ) {
    final strengths = <String>[];

    // From positive conduct reports
    final positiveReports = conductReports
        .where((r) => r.type == ConductReportType.positive)
        .toList();
    for (final report in positiveReports.take(3)) {
      strengths.add(report.title);
    }

    // From positive attitudes
    final positiveAttitudes = attitudeRecords
        .where((r) => r.attitudeType == 'positive')
        .toList();
    for (final attitude in positiveAttitudes.take(3)) {
      if (!strengths.contains(attitude.title)) {
        strengths.add(attitude.title);
      }
    }

    if (strengths.isEmpty) {
      return 'Disposición para el aprendizaje y colaboración con compañeros.';
    }

    return '• ${strengths.take(5).join('\n• ')}';
  }

  String _generateConductDescription(String classification) {
    switch (classification) {
      case 'excellent':
        return 'Conducta ejemplar, muestra respeto constante hacia compañeros y docentes, cumple consistentemente con las normas escolares.';
      case 'good':
        return 'Buena conducta en general, ocasionalmente requiere recordatorios sobre normas de convivencia.';
      case 'regular':
        return 'Conducta regular, presenta algunas situaciones que requieren atención y seguimiento continuo.';
      case 'needs_attention':
        return 'Conducta que requiere atención prioritaria, se recomienda implementar plan de intervención específico.';
      default:
        return 'Conducta en evaluación.';
    }
  }

  FinalReport _parseFinalReport(Map<String, dynamic> json) {
    return FinalReport(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      schoolYear: json['school_year'] as String,
      generatedById: json['generated_by'] as String,
      generationDate: DateTime.parse(json['generation_date'] as String),
      studentSummary: StudentSummary(
        fullName: json['student_full_name'] as String? ?? '',
        curp: json['student_curp'] as String? ?? '',
        institutionalId: json['student_institutional_id'] as String? ?? '',
        enrollment: json['student_enrollment'] as String? ?? '',
        grade: json['student_grade'] as String? ?? '',
        group: json['student_group'] as String? ?? '',
        profileImageUrl: json['student_profile_image_url'] as String?,
      ),
      conductualSummary: ConductualSummary(
        totalPositiveReports: json['total_positive_reports'] as int? ?? 0,
        totalNegativeReports: json['total_negative_reports'] as int? ?? 0,
        highlightedIncidents:
            (json['highlighted_incidents'] as List<dynamic>?)
                ?.map(
                  (i) =>
                      HighlightedIncident.fromJson(i as Map<String, dynamic>),
                )
                .toList() ??
            [],
        severityBreakdown: Map<String, int>.from(
          json['severity_breakdown'] as Map? ?? {},
        ),
      ),
      bapSummary: BAPSummary(
        totalActiveBAP: json['total_active_bap'] as int? ?? 0,
        bapTypeBreakdown: Map<String, int>.from(
          json['bap_type_breakdown'] as Map? ?? {},
        ),
        evolutionSummary:
            (json['bap_evolution_summary'] as List<dynamic>?)
                ?.map((e) => BAPEvolution.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      ),
      medicalSummary: MedicalSummary(
        bloodType: json['blood_type'] as String?,
        activeConditions:
            (json['active_conditions'] as List<dynamic>?)
                ?.map((c) => c as String)
                .toList() ??
            [],
        currentMedications:
            (json['current_medications'] as List<dynamic>?)
                ?.map((m) => m as String)
                .toList() ??
            [],
        activeAllergies:
            (json['active_allergies'] as List<dynamic>?)
                ?.map((a) => a as String)
                .toList() ??
            [],
      ),
      attitudesSummary: AttitudesSummary(
        positiveAttitudes:
            (json['positive_attitudes'] as List<dynamic>?)
                ?.map(
                  (a) =>
                      PredominantAttitude.fromJson(a as Map<String, dynamic>),
                )
                .toList() ??
            [],
        negativeAttitudes:
            (json['negative_attitudes'] as List<dynamic>?)
                ?.map(
                  (a) =>
                      PredominantAttitude.fromJson(a as Map<String, dynamic>),
                )
                .toList() ??
            [],
        frequencyAnalysis: Map<String, int>.from(
          json['frequency_analysis'] as Map? ?? {},
        ),
      ),
      recommendations: json['recommendations'] as String? ?? '',
      opportunities: json['areas_of_opportunity'] as String? ?? '',
      strengths: json['identified_strengths'] as String? ?? '',
      conductLetter: ConductLetter(
        classification: json['conduct_classification'] as String? ?? 'regular',
        summary: json['conduct_summary'] as String? ?? '',
        pdfUrl: json['pdf_url'] as String? ?? '',
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
