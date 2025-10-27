class FinalReport {
  final String id;
  final String studentId;
  final String schoolYear;
  final String generatedById; // ID de quien generó el reporte
  final DateTime generationDate;

  // Resumen de datos generales
  final StudentSummary studentSummary;

  // Historial conductual del ciclo
  final ConductualSummary conductualSummary;

  // Resumen de BAP y su evolución
  final BAPSummary bapSummary;

  // Situación médica actual
  final MedicalSummary medicalSummary;

  // Actitudes predominantes
  final AttitudesSummary attitudesSummary;

  // Recomendaciones y observaciones
  final String recommendations;
  final String opportunities;
  final String strengths;

  // Carta de conducta
  final ConductLetter conductLetter;

  // PDF URLs
  final String? pdfUrl;
  final String? fichaPedagogicaPdfUrl;

  final DateTime createdAt;
  final DateTime? updatedAt;

  FinalReport({
    required this.id,
    required this.studentId,
    required this.schoolYear,
    required this.generatedById,
    required this.generationDate,
    required this.studentSummary,
    required this.conductualSummary,
    required this.bapSummary,
    required this.medicalSummary,
    required this.attitudesSummary,
    required this.recommendations,
    required this.opportunities,
    required this.strengths,
    required this.conductLetter,
    this.pdfUrl,
    this.fichaPedagogicaPdfUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory FinalReport.fromJson(Map<String, dynamic> json) {
    return FinalReport(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      schoolYear: json['school_year'] as String,
      generatedById: json['generated_by_id'] as String,
      generationDate: DateTime.parse(json['generation_date'] as String),
      studentSummary: StudentSummary.fromJson(
        json['student_summary'] as Map<String, dynamic>,
      ),
      conductualSummary: ConductualSummary.fromJson(
        json['conductual_summary'] as Map<String, dynamic>,
      ),
      bapSummary: BAPSummary.fromJson(
        json['bap_summary'] as Map<String, dynamic>,
      ),
      medicalSummary: MedicalSummary.fromJson(
        json['medical_summary'] as Map<String, dynamic>,
      ),
      attitudesSummary: AttitudesSummary.fromJson(
        json['attitudes_summary'] as Map<String, dynamic>,
      ),
      recommendations: json['recommendations'] as String,
      opportunities: json['opportunities'] as String,
      strengths: json['strengths'] as String,
      conductLetter: ConductLetter.fromJson(
        json['conduct_letter'] as Map<String, dynamic>,
      ),
      pdfUrl: json['pdf_url'] as String?,
      fichaPedagogicaPdfUrl: json['ficha_pedagogica_pdf_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'school_year': schoolYear,
      'generated_by_id': generatedById,
      'generation_date': generationDate.toIso8601String(),
      'student_summary': studentSummary.toJson(),
      'conductual_summary': conductualSummary.toJson(),
      'bap_summary': bapSummary.toJson(),
      'medical_summary': medicalSummary.toJson(),
      'attitudes_summary': attitudesSummary.toJson(),
      'recommendations': recommendations,
      'opportunities': opportunities,
      'strengths': strengths,
      'conduct_letter': conductLetter.toJson(),
      'pdf_url': pdfUrl,
      'ficha_pedagogica_pdf_url': fichaPedagogicaPdfUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class StudentSummary {
  final String fullName;
  final String curp;
  final String institutionalId;
  final String enrollment;
  final String grade;
  final String group;
  final String? profileImageUrl;

  StudentSummary({
    required this.fullName,
    required this.curp,
    required this.institutionalId,
    required this.enrollment,
    required this.grade,
    required this.group,
    this.profileImageUrl,
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      fullName: json['full_name'] as String,
      curp: json['curp'] as String,
      institutionalId: json['institutional_id'] as String,
      enrollment: json['enrollment'] as String,
      grade: json['grade'] as String,
      group: json['group'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'curp': curp,
      'institutional_id': institutionalId,
      'enrollment': enrollment,
      'grade': grade,
      'group': group,
      'profile_image_url': profileImageUrl,
    };
  }
}

class ConductualSummary {
  final int totalPositiveReports;
  final int totalNegativeReports;
  final List<HighlightedIncident> highlightedIncidents;
  final Map<String, int> severityBreakdown; // mild: 2, moderate: 1, etc.

  ConductualSummary({
    required this.totalPositiveReports,
    required this.totalNegativeReports,
    required this.highlightedIncidents,
    required this.severityBreakdown,
  });

  factory ConductualSummary.fromJson(Map<String, dynamic> json) {
    return ConductualSummary(
      totalPositiveReports: json['total_positive_reports'] as int,
      totalNegativeReports: json['total_negative_reports'] as int,
      highlightedIncidents: (json['highlighted_incidents'] as List<dynamic>)
          .map((i) => HighlightedIncident.fromJson(i as Map<String, dynamic>))
          .toList(),
      severityBreakdown: Map<String, int>.from(
        json['severity_breakdown'] as Map,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_positive_reports': totalPositiveReports,
      'total_negative_reports': totalNegativeReports,
      'highlighted_incidents': highlightedIncidents
          .map((i) => i.toJson())
          .toList(),
      'severity_breakdown': severityBreakdown,
    };
  }
}

class HighlightedIncident {
  final String title;
  final String description;
  final DateTime date;
  final String severity;
  final String type; // positive or negative

  HighlightedIncident({
    required this.title,
    required this.description,
    required this.date,
    required this.severity,
    required this.type,
  });

  factory HighlightedIncident.fromJson(Map<String, dynamic> json) {
    return HighlightedIncident(
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      severity: json['severity'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'severity': severity,
      'type': type,
    };
  }
}

class BAPSummary {
  final int totalActiveBAP;
  final Map<String, int> bapTypeBreakdown;
  final List<BAPEvolution> evolutionSummary;

  BAPSummary({
    required this.totalActiveBAP,
    required this.bapTypeBreakdown,
    required this.evolutionSummary,
  });

  factory BAPSummary.fromJson(Map<String, dynamic> json) {
    return BAPSummary(
      totalActiveBAP: json['total_active_bap'] as int,
      bapTypeBreakdown: Map<String, int>.from(
        json['bap_type_breakdown'] as Map,
      ),
      evolutionSummary: (json['evolution_summary'] as List<dynamic>)
          .map((e) => BAPEvolution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_active_bap': totalActiveBAP,
      'bap_type_breakdown': bapTypeBreakdown,
      'evolution_summary': evolutionSummary.map((e) => e.toJson()).toList(),
    };
  }
}

class BAPEvolution {
  final String title;
  final String type;
  final String currentStatus;
  final int followUpCount;

  BAPEvolution({
    required this.title,
    required this.type,
    required this.currentStatus,
    required this.followUpCount,
  });

  factory BAPEvolution.fromJson(Map<String, dynamic> json) {
    return BAPEvolution(
      title: json['title'] as String,
      type: json['type'] as String,
      currentStatus: json['current_status'] as String,
      followUpCount: json['follow_up_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'current_status': currentStatus,
      'follow_up_count': followUpCount,
    };
  }
}

class MedicalSummary {
  final String? bloodType;
  final List<String> activeConditions;
  final List<String> currentMedications;
  final List<String> activeAllergies;

  MedicalSummary({
    this.bloodType,
    required this.activeConditions,
    required this.currentMedications,
    required this.activeAllergies,
  });

  factory MedicalSummary.fromJson(Map<String, dynamic> json) {
    return MedicalSummary(
      bloodType: json['blood_type'] as String?,
      activeConditions: (json['active_conditions'] as List<dynamic>)
          .map((c) => c as String)
          .toList(),
      currentMedications: (json['current_medications'] as List<dynamic>)
          .map((m) => m as String)
          .toList(),
      activeAllergies: (json['active_allergies'] as List<dynamic>)
          .map((a) => a as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blood_type': bloodType,
      'active_conditions': activeConditions,
      'current_medications': currentMedications,
      'active_allergies': activeAllergies,
    };
  }
}

class AttitudesSummary {
  final List<PredominantAttitude> positiveAttitudes;
  final List<PredominantAttitude> negativeAttitudes;
  final Map<String, int> frequencyAnalysis;

  AttitudesSummary({
    required this.positiveAttitudes,
    required this.negativeAttitudes,
    required this.frequencyAnalysis,
  });

  factory AttitudesSummary.fromJson(Map<String, dynamic> json) {
    return AttitudesSummary(
      positiveAttitudes: (json['positive_attitudes'] as List<dynamic>)
          .map((a) => PredominantAttitude.fromJson(a as Map<String, dynamic>))
          .toList(),
      negativeAttitudes: (json['negative_attitudes'] as List<dynamic>)
          .map((a) => PredominantAttitude.fromJson(a as Map<String, dynamic>))
          .toList(),
      frequencyAnalysis: Map<String, int>.from(
        json['frequency_analysis'] as Map,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positive_attitudes': positiveAttitudes.map((a) => a.toJson()).toList(),
      'negative_attitudes': negativeAttitudes.map((a) => a.toJson()).toList(),
      'frequency_analysis': frequencyAnalysis,
    };
  }
}

class PredominantAttitude {
  final String title;
  final String description;
  final int frequency;

  PredominantAttitude({
    required this.title,
    required this.description,
    required this.frequency,
  });

  factory PredominantAttitude.fromJson(Map<String, dynamic> json) {
    return PredominantAttitude(
      title: json['title'] as String,
      description: json['description'] as String,
      frequency: json['frequency'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'frequency': frequency};
  }
}

class ConductLetter {
  final String classification; // Excelente, Buena, Regular, Requiere atención
  final String summary;
  final String pdfUrl;

  ConductLetter({
    required this.classification,
    required this.summary,
    required this.pdfUrl,
  });

  factory ConductLetter.fromJson(Map<String, dynamic> json) {
    return ConductLetter(
      classification: json['classification'] as String,
      summary: json['summary'] as String,
      pdfUrl: json['pdf_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classification': classification,
      'summary': summary,
      'pdf_url': pdfUrl,
    };
  }
}
