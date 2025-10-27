import '../core/constants.dart';

class BAPRecord {
  final String id;
  final String studentId;
  final String identifiedById; // ID del profesional que la identificó
  final BAPType type;
  final String title;
  final String description;
  final DateTime detectionDate;
  final List<String> interventionStrategies;
  final String? currentStatus;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Información del profesional que la identificó (cargada mediante join)
  final String? identifiedByName;

  // Seguimientos
  final List<BAPFollowUp> followUps;

  BAPRecord({
    required this.id,
    required this.studentId,
    required this.identifiedById,
    required this.type,
    required this.title,
    required this.description,
    required this.detectionDate,
    this.interventionStrategies = const [],
    this.currentStatus,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.identifiedByName,
    this.followUps = const [],
  });

  factory BAPRecord.fromJson(Map<String, dynamic> json) {
    // Parse intervention strategies from string or list
    List<String> strategies = [];
    if (json['intervention_strategies'] != null) {
      if (json['intervention_strategies'] is String) {
        strategies = (json['intervention_strategies'] as String)
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();
      } else if (json['intervention_strategies'] is List) {
        strategies = (json['intervention_strategies'] as List<dynamic>)
            .map((s) => s.toString())
            .toList();
      }
    }

    // Parse attachment URLs
    List<String> attachments = [];
    if (json['documents'] != null) {
      if (json['documents'] is List) {
        attachments = (json['documents'] as List<dynamic>)
            .map((url) => url.toString())
            .toList();
      }
    } else if (json['attachment_urls'] != null) {
      if (json['attachment_urls'] is List) {
        attachments = (json['attachment_urls'] as List<dynamic>)
            .map((url) => url.toString())
            .toList();
      }
    }

    // Parse follow-ups
    List<BAPFollowUp> followUps = [];
    if (json['follow_ups'] != null && json['follow_ups'] is List) {
      followUps = (json['follow_ups'] as List<dynamic>)
          .map((f) => BAPFollowUp.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    return BAPRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      identifiedById:
          json['detected_by'] as String? ?? json['identified_by_id'] as String,
      type: BAPType.values.firstWhere((type) => type.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      detectionDate: DateTime.parse(json['detection_date'] as String),
      interventionStrategies: strategies,
      currentStatus: json['current_status'] as String?,
      attachmentUrls: attachments,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      identifiedByName: json['identified_by_name'] as String?,
      followUps: followUps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'identified_by_id': identifiedById,
      'type': type.name,
      'title': title,
      'description': description,
      'detection_date': detectionDate.toIso8601String(),
      'intervention_strategies': interventionStrategies,
      'current_status': currentStatus,
      'attachment_urls': attachmentUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'follow_ups': followUps.map((f) => f.toJson()).toList(),
    };
  }

  BAPRecord copyWith({
    String? id,
    String? studentId,
    String? identifiedById,
    BAPType? type,
    String? title,
    String? description,
    DateTime? detectionDate,
    List<String>? interventionStrategies,
    String? currentStatus,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? identifiedByName,
    List<BAPFollowUp>? followUps,
  }) {
    return BAPRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      identifiedById: identifiedById ?? this.identifiedById,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      detectionDate: detectionDate ?? this.detectionDate,
      interventionStrategies:
          interventionStrategies ?? this.interventionStrategies,
      currentStatus: currentStatus ?? this.currentStatus,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      identifiedByName: identifiedByName ?? this.identifiedByName,
      followUps: followUps ?? this.followUps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BAPRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class BAPFollowUp {
  final String id;
  final String bapRecordId;
  final String followUpById; // ID del profesional que hace el seguimiento
  final DateTime followUpDate;
  final String observations;
  final String? evolution;
  final List<String> updatedStrategies;
  final String? nextSteps;
  final DateTime? nextFollowUpDate;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Información del profesional que hace el seguimiento (cargada mediante join)
  final String? followUpByName;

  BAPFollowUp({
    required this.id,
    required this.bapRecordId,
    required this.followUpById,
    required this.followUpDate,
    required this.observations,
    this.evolution,
    this.updatedStrategies = const [],
    this.nextSteps,
    this.nextFollowUpDate,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.followUpByName,
  });

  factory BAPFollowUp.fromJson(Map<String, dynamic> json) {
    return BAPFollowUp(
      id: json['id'] as String,
      bapRecordId: json['bap_record_id'] as String,
      followUpById: json['follow_up_by_id'] as String,
      followUpDate: DateTime.parse(json['follow_up_date'] as String),
      observations: json['observations'] as String,
      evolution: json['evolution'] as String?,
      updatedStrategies:
          (json['updated_strategies'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      nextSteps: json['next_steps'] as String?,
      nextFollowUpDate: json['next_follow_up_date'] != null
          ? DateTime.parse(json['next_follow_up_date'] as String)
          : null,
      attachmentUrls:
          (json['attachment_urls'] as List<dynamic>?)
              ?.map((url) => url as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      followUpByName: json['follow_up_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bap_record_id': bapRecordId,
      'follow_up_by_id': followUpById,
      'follow_up_date': followUpDate.toIso8601String(),
      'observations': observations,
      'evolution': evolution,
      'updated_strategies': updatedStrategies,
      'next_steps': nextSteps,
      'next_follow_up_date': nextFollowUpDate?.toIso8601String(),
      'attachment_urls': attachmentUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
