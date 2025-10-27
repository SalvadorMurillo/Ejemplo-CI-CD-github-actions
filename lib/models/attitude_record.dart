class AttitudeRecord {
  final String id;
  final String studentId;
  final String observedBy; // ID del profesional que observó la actitud
  final String attitudeType; // 'positive' or 'negative'
  final String title;
  final String description;
  final String? context;
  final DateTime observationDate;
  final String? frequency; // Frecuencia de aparición (varchar en DB)
  final String? interventionApplied; // texto de intervención aplicada
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  // Información del profesional que observó (cargada mediante join)
  final String? observedByName;

  AttitudeRecord({
    required this.id,
    required this.studentId,
    required this.observedBy,
    required this.attitudeType,
    required this.title,
    required this.description,
    this.context,
    required this.observationDate,
    this.frequency,
    this.interventionApplied,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.observedByName,
  });

  bool get isPositive => attitudeType == 'positive';
  bool get isNegative => attitudeType == 'negative';
  String get attitudeTypeDisplayName => isPositive ? 'Positiva' : 'Negativa';

  factory AttitudeRecord.fromJson(Map<String, dynamic> json) {
    return AttitudeRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      observedBy: json['observed_by'] as String,
      attitudeType: json['attitude_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      context: json['context'] as String?,
      observationDate: DateTime.parse(json['observation_date'] as String),
      frequency: json['frequency'] as String?,
      interventionApplied: json['intervention_applied'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      observedByName: json['observed_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'observed_by': observedBy,
      'attitude_type': attitudeType,
      'title': title,
      'description': description,
      'context': context,
      'observation_date': observationDate.toIso8601String(),
      'frequency': frequency,
      'intervention_applied': interventionApplied,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  AttitudeRecord copyWith({
    String? id,
    String? studentId,
    String? observedBy,
    String? attitudeType,
    String? title,
    String? description,
    String? context,
    DateTime? observationDate,
    String? frequency,
    String? interventionApplied,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? observedByName,
  }) {
    return AttitudeRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      observedBy: observedBy ?? this.observedBy,
      attitudeType: attitudeType ?? this.attitudeType,
      title: title ?? this.title,
      description: description ?? this.description,
      context: context ?? this.context,
      observationDate: observationDate ?? this.observationDate,
      frequency: frequency ?? this.frequency,
      interventionApplied: interventionApplied ?? this.interventionApplied,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      observedByName: observedByName ?? this.observedByName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttitudeRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
