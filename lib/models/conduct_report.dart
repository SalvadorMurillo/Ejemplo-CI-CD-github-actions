import '../core/constants.dart';

class ConductReport {
  final String id;
  final String studentId;
  final String reporterId;
  final ConductReportType type;
  final IncidentSeverity? severity;
  final String title;
  final String description;
  final DateTime incidentDate;
  final String? context;
  final String? witnesses; // Changed from List<String> to String
  final String? immediateActions;
  final List<String> attachments; // Changed from attachmentUrls
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Parent agreement fields (from conduct_reports table)
  final String? parentAgreement;
  final String? parentSignatureUrl;
  final DateTime? agreementDate;
  final DateTime? followUpDate;

  // Información del reportero (cargada mediante join)
  final String? reporterName;

  // Información del estudiante (cargada mediante join)
  final String? studentName;

  // Parent agreements from separate table
  final List<ParentAgreement> parentAgreements;

  ConductReport({
    required this.id,
    required this.studentId,
    required this.reporterId,
    required this.type,
    this.severity,
    required this.title,
    required this.description,
    required this.incidentDate,
    this.context,
    this.witnesses,
    this.immediateActions,
    this.attachments = const [],
    required this.createdAt,
    this.updatedAt,
    this.parentAgreement,
    this.parentSignatureUrl,
    this.agreementDate,
    this.followUpDate,
    this.reporterName,
    this.studentName,
    this.parentAgreements = const [],
  });

  bool get isPositive => type == ConductReportType.positive;
  bool get isNegative => type == ConductReportType.negative;

  String get severityDisplayName => severity?.displayName ?? 'N/A';

  // Parse witnesses from string to list
  List<String> get witnessesList {
    if (witnesses == null || witnesses!.isEmpty) return [];
    return witnesses!.split(',').map((w) => w.trim()).toList();
  }

  factory ConductReport.fromJson(Map<String, dynamic> json) {
    // Parse attachments from JSONB
    List<String> attachmentsList = [];
    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        attachmentsList = (json['attachments'] as List)
            .map((a) => a.toString())
            .toList();
      } else if (json['attachments'] is String) {
        // Handle string case
        attachmentsList = [json['attachments'] as String];
      }
    }

    return ConductReport(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      reporterId: json['reporter_id'] as String,
      type: ConductReportType.values.firstWhere(
        (type) => type.name == json['type'],
      ),
      severity: json['severity'] != null
          ? IncidentSeverity.values.firstWhere(
              (severity) => severity.name == json['severity'],
            )
          : null,
      title: json['title'] as String,
      description: json['description'] as String,
      incidentDate: DateTime.parse(json['incident_date'] as String),
      context: json['context'] as String?,
      witnesses: json['witnesses'] as String?,
      immediateActions: json['immediate_actions'] as String?,
      attachments: attachmentsList,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      parentAgreement: json['parent_agreement'] as String?,
      parentSignatureUrl: json['parent_signature_url'] as String?,
      agreementDate: json['agreement_date'] != null
          ? DateTime.parse(json['agreement_date'] as String)
          : null,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      reporterName: json['reporter_name'] as String?,
      studentName: json['student_name'] as String?,
      parentAgreements:
          (json['parent_agreements'] as List<dynamic>?)
              ?.map((a) => ParentAgreement.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'reporter_id': reporterId,
      'type': type.name,
      'severity': severity?.name,
      'title': title,
      'description': description,
      'incident_date': incidentDate.toIso8601String(),
      'context': context,
      'witnesses': witnesses,
      'immediate_actions': immediateActions,
      'attachments': attachments, // Changed from attachment_urls
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'parent_agreement': parentAgreement,
      'parent_signature_url': parentSignatureUrl,
      'agreement_date': agreementDate?.toIso8601String(),
      'follow_up_date': followUpDate?.toIso8601String(),
    };
  }

  ConductReport copyWith({
    String? id,
    String? studentId,
    String? reporterId,
    ConductReportType? type,
    IncidentSeverity? severity,
    String? title,
    String? description,
    DateTime? incidentDate,
    String? context,
    String? witnesses,
    String? immediateActions,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentAgreement,
    String? parentSignatureUrl,
    DateTime? agreementDate,
    DateTime? followUpDate,
    String? reporterName,
    String? studentName,
    List<ParentAgreement>? parentAgreements,
  }) {
    return ConductReport(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      reporterId: reporterId ?? this.reporterId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      incidentDate: incidentDate ?? this.incidentDate,
      context: context ?? this.context,
      witnesses: witnesses ?? this.witnesses,
      immediateActions: immediateActions ?? this.immediateActions,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentAgreement: parentAgreement ?? this.parentAgreement,
      parentSignatureUrl: parentSignatureUrl ?? this.parentSignatureUrl,
      agreementDate: agreementDate ?? this.agreementDate,
      followUpDate: followUpDate ?? this.followUpDate,
      reporterName: reporterName ?? this.reporterName,
      studentName: studentName ?? this.studentName,
      parentAgreements: parentAgreements ?? this.parentAgreements,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConductReport && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ParentAgreement {
  final String id;
  final String conductReportId;
  final String agreementDescription;
  final List<String> specificCommitments;
  final String? signatureImageUrl;
  final DateTime agreementDate;
  final DateTime? followUpDate;
  final String? guardianName;
  final String? guardianRelationship;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ParentAgreement({
    required this.id,
    required this.conductReportId,
    required this.agreementDescription,
    this.specificCommitments = const [],
    this.signatureImageUrl,
    required this.agreementDate,
    this.followUpDate,
    this.guardianName,
    this.guardianRelationship,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ParentAgreement.fromJson(Map<String, dynamic> json) {
    return ParentAgreement(
      id: json['id'] as String,
      conductReportId: json['conduct_report_id'] as String,
      agreementDescription: json['agreement_description'] as String,
      specificCommitments:
          (json['specific_commitments'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      signatureImageUrl: json['signature_image_url'] as String?,
      agreementDate: DateTime.parse(json['agreement_date'] as String),
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      guardianName: json['guardian_name'] as String?,
      guardianRelationship: json['guardian_relationship'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conduct_report_id': conductReportId,
      'agreement_description': agreementDescription,
      'specific_commitments': specificCommitments,
      'signature_image_url': signatureImageUrl,
      'agreement_date': agreementDate.toIso8601String(),
      'follow_up_date': followUpDate?.toIso8601String(),
      'guardian_name': guardianName,
      'guardian_relationship': guardianRelationship,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
