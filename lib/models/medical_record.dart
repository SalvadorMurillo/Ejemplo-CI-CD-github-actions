import '../core/constants.dart';

class MedicalRecord {
  final String id;
  final String studentId;
  final BloodType? bloodType;
  final List<String> knownAllergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? insuranceInfo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Student information (from join)
  final String? studentFirstName;
  final String? studentLastName;
  final String? studentCurp;
  final String? studentEnrollment;

  // Relaciones
  final List<MedicalDiagnosis> diagnoses;
  final List<MedicalFollowUp> followUps;

  MedicalRecord({
    required this.id,
    required this.studentId,
    this.bloodType,
    this.knownAllergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.emergencyContact,
    this.emergencyPhone,
    this.insuranceInfo,
    required this.createdAt,
    this.updatedAt,
    this.studentFirstName,
    this.studentLastName,
    this.studentCurp,
    this.studentEnrollment,
    this.diagnoses = const [],
    this.followUps = const [],
  });

  // Helper getter for full student name
  String get studentFullName {
    if (studentFirstName != null && studentLastName != null) {
      return '$studentFirstName $studentLastName';
    }
    return 'Estudiante desconocido';
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    BloodType? parsedBloodType;
    if (json['blood_type'] != null) {
      try {
        final bloodTypeStr = json['blood_type'] as String;
        parsedBloodType = BloodType.values.firstWhere(
          (type) => type.name.toLowerCase() == bloodTypeStr.toLowerCase(),
          orElse: () => throw Exception('Invalid blood type'),
        );
      } catch (e) {
        print(
          'Warning: Failed to parse blood type: ${json['blood_type']}. Error: $e',
        );
        parsedBloodType = null;
      }
    }

    // Parse student data from join
    String? firstName;
    String? lastName;
    String? curp;
    String? enrollment;

    if (json['students'] != null) {
      final studentData = json['students'] is List
          ? (json['students'] as List).first
          : json['students'];

      firstName = studentData['first_name'] as String?;
      lastName = studentData['last_name'] as String?;
      curp = studentData['curp'] as String?;
      enrollment = studentData['enrollment'] as String?;
    }

    return MedicalRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      bloodType: parsedBloodType,
      knownAllergies: _parseListFromString(json['allergies'] as String?),
      chronicConditions: _parseListFromString(
        json['chronic_conditions'] as String?,
      ),
      currentMedications: _parseListFromString(
        json['current_medications'] as String?,
      ),
      emergencyContact: json['emergency_contact_name'] as String?,
      emergencyPhone: json['emergency_contact_phone'] as String?,
      insuranceInfo: json['medical_insurance'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      studentFirstName: firstName,
      studentLastName: lastName,
      studentCurp: curp,
      studentEnrollment: enrollment,
      diagnoses: _parseDiagnoses(json['diagnoses']),
      followUps: _parseFollowUps(json['medical_events']),
    );
  }

  static List<String> _parseListFromString(String? value) {
    if (value == null || value.isEmpty) return [];
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<MedicalDiagnosis> _parseDiagnoses(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json
          .map((d) => MedicalDiagnosis.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<MedicalFollowUp> _parseFollowUps(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json
          .map((f) => MedicalFollowUp.fromJson(f as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'blood_type':
          bloodType?.name, // This will save as 'aPositive', 'bPositive', etc.
      'allergies': knownAllergies.where((e) => e.isNotEmpty).join(', '),
      'chronic_conditions': chronicConditions
          .where((e) => e.isNotEmpty)
          .join(', '),
      'current_medications': currentMedications
          .where((e) => e.isNotEmpty)
          .join(', '),
      'emergency_contact_name': emergencyContact,
      'emergency_contact_phone': emergencyPhone,
      'medical_insurance': insuranceInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'diagnoses': diagnoses.map((d) => d.toJson()).toList(),
      'medical_events': followUps.map((f) => f.toJson()).toList(),
    };
  }

  MedicalRecord copyWith({
    String? id,
    String? studentId,
    BloodType? bloodType,
    List<String>? knownAllergies,
    List<String>? chronicConditions,
    List<String>? currentMedications,
    String? emergencyContact,
    String? emergencyPhone,
    String? insuranceInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? studentFirstName,
    String? studentLastName,
    String? studentCurp,
    String? studentEnrollment,
    List<MedicalDiagnosis>? diagnoses,
    List<MedicalFollowUp>? followUps,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      bloodType: bloodType ?? this.bloodType,
      knownAllergies: knownAllergies ?? this.knownAllergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentFirstName: studentFirstName ?? this.studentFirstName,
      studentLastName: studentLastName ?? this.studentLastName,
      studentCurp: studentCurp ?? this.studentCurp,
      studentEnrollment: studentEnrollment ?? this.studentEnrollment,
      diagnoses: diagnoses ?? this.diagnoses,
      followUps: followUps ?? this.followUps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicalRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MedicalDiagnosis {
  final String id;
  final String medicalRecordId;
  final String diagnosis;
  final String? diagnosingDoctor;
  final DateTime diagnosisDate;
  final String? description;
  final List<String> attachmentUrls; // Documentos médicos
  final bool isActive;
  final String? treatment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicalDiagnosis({
    required this.id,
    required this.medicalRecordId,
    required this.diagnosis,
    this.diagnosingDoctor,
    required this.diagnosisDate,
    this.description,
    this.attachmentUrls = const [],
    this.isActive = true,
    this.treatment,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicalDiagnosis.fromJson(Map<String, dynamic> json) {
    return MedicalDiagnosis(
      id: json['id'] as String,
      medicalRecordId: json['medical_record_id'] as String,
      diagnosis: json['diagnosis'] as String,
      diagnosingDoctor: json['diagnosing_doctor'] as String?,
      diagnosisDate: DateTime.parse(json['diagnosis_date'] as String),
      description: json['description'] as String?,
      attachmentUrls:
          (json['attachment_urls'] as List<dynamic>?)
              ?.map((url) => url as String)
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
      treatment: json['treatment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medical_record_id': medicalRecordId,
      'diagnosis': diagnosis,
      'diagnosing_doctor': diagnosingDoctor,
      'diagnosis_date': diagnosisDate.toIso8601String(),
      'description': description,
      'attachment_urls': attachmentUrls,
      'is_active': isActive,
      'treatment': treatment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class MedicalFollowUp {
  final String id;
  final String medicalRecordId;
  final DateTime followUpDate;
  final String? consultationType;
  final String? observations;
  final String? attendingPhysician;
  final String? evolution;
  final String? schoolObservations;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicalFollowUp({
    required this.id,
    required this.medicalRecordId,
    required this.followUpDate,
    this.consultationType,
    this.observations,
    this.attendingPhysician,
    this.evolution,
    this.schoolObservations,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicalFollowUp.fromJson(Map<String, dynamic> json) {
    return MedicalFollowUp(
      id: json['id'] as String,
      medicalRecordId: json['medical_record_id'] as String,
      followUpDate: DateTime.parse(json['follow_up_date'] as String),
      consultationType: json['consultation_type'] as String?,
      observations: json['observations'] as String?,
      attendingPhysician: json['attending_physician'] as String?,
      evolution: json['evolution'] as String?,
      schoolObservations: json['school_observations'] as String?,
      attachmentUrls:
          (json['attachment_urls'] as List<dynamic>?)
              ?.map((url) => url as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medical_record_id': medicalRecordId,
      'follow_up_date': followUpDate.toIso8601String(),
      'consultation_type': consultationType,
      'observations': observations,
      'attending_physician': attendingPhysician,
      'evolution': evolution,
      'school_observations': schoolObservations,
      'attachment_urls': attachmentUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
