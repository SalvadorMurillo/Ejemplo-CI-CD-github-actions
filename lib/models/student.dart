import '../core/constants.dart';

class Student {
  final String id;
  final String curp;
  final String institutionalId;
  final String enrollment;
  final String firstName;
  final String lastName;
  final String? middleName;
  final SchoolGrade grade;
  final String group;
  final String currentSchoolYear;
  final int positiveReportsCount;
  final int negativeReportsCount;
  final String? profileImageUrl;
  final String? profileImageUrlGrade1;
  final String? profileImageUrlGrade2;
  final String? profileImageUrlGrade3;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Campos adicionales del sistema escolar
  final String? cct;
  final String? turno;
  final String? sexo;
  final DateTime? birthDate;
  final int? numeroLista;
  final String? grupoTaller;
  final int? numeroListaTaller;
  final String? situacion;
  final bool? repetidor;
  final DateTime? fechaAlta;
  final DateTime? fechaBaja;
  final String? motivoBaja;
  final String? discapacidad;
  final bool? indigena;
  final String? nee;
  final bool? usaer;
  final String? beca;

  // Información de contacto y ubicación
  final String? calle;
  final String? numero;
  final String? colonia;
  final String? localidad;
  final String? municipio;
  final String? telefono;
  final String? codigoPostal;
  final String? tutor;
  final String? nacionalidad;
  final String? primariaProcedencia;
  final double? promedioPrimaria;

  // Información física
  final double? peso;
  final double? estatura;
  final String? uniformeA;
  final String? uniformeB;

  // Información familiar
  final String? padre;
  final DateTime? fechaPadre;
  final String? curpPadre;
  final String? estudiosPadre;
  final String? madre;
  final DateTime? fechaMadre;
  final String? curpMadre;
  final String? estudiosMadre;

  // CURP document information
  final String? curpDocumentUrl;
  final DateTime? curpDocumentUploadDate;

  // Información de tutores
  final List<Guardian> guardians;

  Student({
    required this.id,
    required this.curp,
    required this.institutionalId,
    required this.enrollment,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.grade,
    required this.group,
    required this.currentSchoolYear,
    this.positiveReportsCount = 0,
    this.negativeReportsCount = 0,
    this.profileImageUrl,
    this.profileImageUrlGrade1,
    this.profileImageUrlGrade2,
    this.profileImageUrlGrade3,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.guardians = const [],
    // Campos adicionales
    this.cct,
    this.turno,
    this.sexo,
    this.birthDate,
    this.numeroLista,
    this.grupoTaller,
    this.numeroListaTaller,
    this.situacion,
    this.repetidor,
    this.fechaAlta,
    this.fechaBaja,
    this.motivoBaja,
    this.discapacidad,
    this.indigena,
    this.nee,
    this.usaer,
    this.beca,
    this.calle,
    this.numero,
    this.colonia,
    this.localidad,
    this.municipio,
    this.telefono,
    this.codigoPostal,
    this.tutor,
    this.nacionalidad,
    this.primariaProcedencia,
    this.promedioPrimaria,
    this.peso,
    this.estatura,
    this.uniformeA,
    this.uniformeB,
    this.padre,
    this.fechaPadre,
    this.curpPadre,
    this.estudiosPadre,
    this.madre,
    this.fechaMadre,
    this.curpMadre,
    this.estudiosMadre,
    // CURP document
    this.curpDocumentUrl,
    this.curpDocumentUploadDate,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  String get gradeGroup => '${grade.displayName} ${group.toUpperCase()}';

  /// Get profile image URL for a specific grade
  String? getProfileImageForGrade(SchoolGrade targetGrade) {
    switch (targetGrade) {
      case SchoolGrade.primero:
        return profileImageUrlGrade1;
      case SchoolGrade.segundo:
        return profileImageUrlGrade2;
      case SchoolGrade.tercero:
        return profileImageUrlGrade3;
    }
  }

  /// Get profile image URL for current grade or fallback to general profile image
  String? get currentGradeProfileImage {
    return getProfileImageForGrade(grade) ?? profileImageUrl;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      curp: json['curp'] as String,
      institutionalId: json['institutional_id'] as String,
      enrollment: json['enrollment'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      middleName: json['middle_name'] as String?,
      grade: SchoolGrade.values.firstWhere(
        (grade) => grade.name == json['grade'],
      ),
      group: json['group'] as String,
      currentSchoolYear: json['current_school_year'] as String,
      positiveReportsCount: json['positive_reports_count'] as int? ?? 0,
      negativeReportsCount: json['negative_reports_count'] as int? ?? 0,
      profileImageUrl: json['profile_image_url'] as String?,
      profileImageUrlGrade1: json['profile_image_url_grade1'] as String?,
      profileImageUrlGrade2: json['profile_image_url_grade2'] as String?,
      profileImageUrlGrade3: json['profile_image_url_grade3'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      guardians:
          (json['guardians'] as List<dynamic>?)
              ?.map((g) => Guardian.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
      // Campos adicionales
      cct: json['cct'] as String?,
      turno: json['turno'] as String?,
      sexo: json['sexo'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      numeroLista: json['numero_lista'] as int?,
      grupoTaller: json['grupo_taller'] as String?,
      numeroListaTaller: json['numero_lista_taller'] as int?,
      situacion: json['situacion'] as String?,
      repetidor: json['repetidor'] as bool?,
      fechaAlta: json['fecha_alta'] != null
          ? DateTime.parse(json['fecha_alta'] as String)
          : null,
      fechaBaja: json['fecha_baja'] != null
          ? DateTime.parse(json['fecha_baja'] as String)
          : null,
      motivoBaja: json['motivo_baja'] as String?,
      discapacidad: json['discapacidad'] as String?,
      indigena: json['indigena'] as bool?,
      nee: json['nee'] as String?,
      usaer: json['usaer'] as bool?,
      beca: json['beca'] as String?,
      calle: json['calle'] as String?,
      numero: json['numero'] as String?,
      colonia: json['colonia'] as String?,
      localidad: json['localidad'] as String?,
      municipio: json['municipio'] as String?,
      telefono: json['telefono'] as String?,
      codigoPostal: json['codigo_postal'] as String?,
      tutor: json['tutor'] as String?,
      nacionalidad: json['nacionalidad'] as String?,
      primariaProcedencia: json['primaria_procedencia'] as String?,
      promedioPrimaria: json['promedio_primaria']?.toDouble(),
      peso: json['peso']?.toDouble(),
      estatura: json['estatura']?.toDouble(),
      uniformeA: json['uniforme_a'] as String?,
      uniformeB: json['uniforme_b'] as String?,
      padre: json['padre'] as String?,
      fechaPadre: json['fecha_padre'] != null
          ? DateTime.parse(json['fecha_padre'] as String)
          : null,
      curpPadre: json['curp_padre'] as String?,
      estudiosPadre: json['estudios_padre'] as String?,
      madre: json['madre'] as String?,
      fechaMadre: json['fecha_madre'] != null
          ? DateTime.parse(json['fecha_madre'] as String)
          : null,
      curpMadre: json['curp_madre'] as String?,
      estudiosMadre: json['estudios_madre'] as String?,
      // CURP document
      curpDocumentUrl: json['curp_document_url'] as String?,
      curpDocumentUploadDate: json['curp_document_upload_date'] != null
          ? DateTime.parse(json['curp_document_upload_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'curp': curp,
      'institutional_id': institutionalId,
      'enrollment': enrollment,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'grade': grade.name,
      'group': group,
      'current_school_year': currentSchoolYear,
      'positive_reports_count': positiveReportsCount,
      'negative_reports_count': negativeReportsCount,
      'profile_image_url': profileImageUrl,
      'profile_image_url_grade1': profileImageUrlGrade1,
      'profile_image_url_grade2': profileImageUrlGrade2,
      'profile_image_url_grade3': profileImageUrlGrade3,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'guardians': guardians.map((g) => g.toJson()).toList(),
      // Campos adicionales
      'cct': cct,
      'turno': turno,
      'sexo': sexo,
      'birth_date': birthDate?.toIso8601String(),
      'numero_lista': numeroLista,
      'grupo_taller': grupoTaller,
      'numero_lista_taller': numeroListaTaller,
      'situacion': situacion,
      'repetidor': repetidor,
      'fecha_alta': fechaAlta?.toIso8601String(),
      'fecha_baja': fechaBaja?.toIso8601String(),
      'motivo_baja': motivoBaja,
      'discapacidad': discapacidad,
      'indigena': indigena,
      'nee': nee,
      'usaer': usaer,
      'beca': beca,
      'calle': calle,
      'numero': numero,
      'colonia': colonia,
      'localidad': localidad,
      'municipio': municipio,
      'telefono': telefono,
      'codigo_postal': codigoPostal,
      'tutor': tutor,
      'nacionalidad': nacionalidad,
      'primaria_procedencia': primariaProcedencia,
      'promedio_primaria': promedioPrimaria,
      'peso': peso,
      'estatura': estatura,
      'uniforme_a': uniformeA,
      'uniforme_b': uniformeB,
      'padre': padre,
      'fecha_padre': fechaPadre?.toIso8601String(),
      'curp_padre': curpPadre,
      'estudios_padre': estudiosPadre,
      'madre': madre,
      'fecha_madre': fechaMadre?.toIso8601String(),
      'curp_madre': curpMadre,
      'estudios_madre': estudiosMadre,
      // CURP document
      'curp_document_url': curpDocumentUrl,
      'curp_document_upload_date': curpDocumentUploadDate?.toIso8601String(),
    };
  }

  Student copyWith({
    String? id,
    String? curp,
    String? institutionalId,
    String? enrollment,
    String? firstName,
    String? lastName,
    String? middleName,
    SchoolGrade? grade,
    String? group,
    String? currentSchoolYear,
    int? positiveReportsCount,
    int? negativeReportsCount,
    String? profileImageUrl,
    String? profileImageUrlGrade1,
    String? profileImageUrlGrade2,
    String? profileImageUrlGrade3,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Guardian>? guardians,
    // Campos adicionales
    String? cct,
    String? turno,
    String? sexo,
    DateTime? birthDate,
    int? numeroLista,
    String? grupoTaller,
    int? numeroListaTaller,
    String? situacion,
    bool? repetidor,
    DateTime? fechaAlta,
    DateTime? fechaBaja,
    String? motivoBaja,
    String? discapacidad,
    bool? indigena,
    String? nee,
    bool? usaer,
    String? beca,
    String? calle,
    String? numero,
    String? colonia,
    String? localidad,
    String? municipio,
    String? telefono,
    String? codigoPostal,
    String? tutor,
    String? nacionalidad,
    String? primariaProcedencia,
    double? promedioPrimaria,
    double? peso,
    double? estatura,
    String? uniformeA,
    String? uniformeB,
    String? padre,
    DateTime? fechaPadre,
    String? curpPadre,
    String? estudiosPadre,
    String? madre,
    DateTime? fechaMadre,
    String? curpMadre,
    String? estudiosMadre,
    // CURP document
    String? curpDocumentUrl,
    DateTime? curpDocumentUploadDate,
  }) {
    return Student(
      id: id ?? this.id,
      curp: curp ?? this.curp,
      institutionalId: institutionalId ?? this.institutionalId,
      enrollment: enrollment ?? this.enrollment,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      grade: grade ?? this.grade,
      group: group ?? this.group,
      currentSchoolYear: currentSchoolYear ?? this.currentSchoolYear,
      positiveReportsCount: positiveReportsCount ?? this.positiveReportsCount,
      negativeReportsCount: negativeReportsCount ?? this.negativeReportsCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImageUrlGrade1:
          profileImageUrlGrade1 ?? this.profileImageUrlGrade1,
      profileImageUrlGrade2:
          profileImageUrlGrade2 ?? this.profileImageUrlGrade2,
      profileImageUrlGrade3:
          profileImageUrlGrade3 ?? this.profileImageUrlGrade3,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      guardians: guardians ?? this.guardians,
      // Campos adicionales
      cct: cct ?? this.cct,
      turno: turno ?? this.turno,
      sexo: sexo ?? this.sexo,
      birthDate: birthDate ?? this.birthDate,
      numeroLista: numeroLista ?? this.numeroLista,
      grupoTaller: grupoTaller ?? this.grupoTaller,
      numeroListaTaller: numeroListaTaller ?? this.numeroListaTaller,
      situacion: situacion ?? this.situacion,
      repetidor: repetidor ?? this.repetidor,
      fechaAlta: fechaAlta ?? this.fechaAlta,
      fechaBaja: fechaBaja ?? this.fechaBaja,
      motivoBaja: motivoBaja ?? this.motivoBaja,
      discapacidad: discapacidad ?? this.discapacidad,
      indigena: indigena ?? this.indigena,
      nee: nee ?? this.nee,
      usaer: usaer ?? this.usaer,
      beca: beca ?? this.beca,
      calle: calle ?? this.calle,
      numero: numero ?? this.numero,
      colonia: colonia ?? this.colonia,
      localidad: localidad ?? this.localidad,
      municipio: municipio ?? this.municipio,
      telefono: telefono ?? this.telefono,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      tutor: tutor ?? this.tutor,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      primariaProcedencia: primariaProcedencia ?? this.primariaProcedencia,
      promedioPrimaria: promedioPrimaria ?? this.promedioPrimaria,
      peso: peso ?? this.peso,
      estatura: estatura ?? this.estatura,
      uniformeA: uniformeA ?? this.uniformeA,
      uniformeB: uniformeB ?? this.uniformeB,
      padre: padre ?? this.padre,
      fechaPadre: fechaPadre ?? this.fechaPadre,
      curpPadre: curpPadre ?? this.curpPadre,
      estudiosPadre: estudiosPadre ?? this.estudiosPadre,
      madre: madre ?? this.madre,
      fechaMadre: fechaMadre ?? this.fechaMadre,
      curpMadre: curpMadre ?? this.curpMadre,
      estudiosMadre: estudiosMadre ?? this.estudiosMadre,
      // CURP document
      curpDocumentUrl: curpDocumentUrl ?? this.curpDocumentUrl,
      curpDocumentUploadDate:
          curpDocumentUploadDate ?? this.curpDocumentUploadDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Guardian {
  final String id;
  final String studentId;
  final String firstName;
  final String lastName;
  final String relationshipType;
  final String? phoneNumber;
  final String? emergencyPhone;
  final String? email;
  final Address? address;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Guardian({
    required this.id,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.relationshipType,
    this.phoneNumber,
    this.emergencyPhone,
    this.email,
    this.address,
    this.isPrimary = false,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      relationshipType: json['relationship_type'] as String,
      phoneNumber: json['phone_number'] as String?,
      emergencyPhone: json['emergency_phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      isPrimary: json['is_primary'] as bool? ?? false,
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
      'first_name': firstName,
      'last_name': lastName,
      'relationship_type': relationshipType,
      'phone_number': phoneNumber,
      'emergency_phone': emergencyPhone,
      'email': email,
      'address': address?.toJson(),
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Guardian copyWith({
    String? id,
    String? studentId,
    String? firstName,
    String? lastName,
    String? relationshipType,
    String? phoneNumber,
    String? emergencyPhone,
    String? email,
    Address? address,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guardian(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      relationshipType: relationshipType ?? this.relationshipType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Address {
  final String street;
  final String? number;
  final String? neighborhood;
  final String city;
  final String state;
  final String? postalCode;
  final String? country;

  Address({
    required this.street,
    this.number,
    this.neighborhood,
    required this.city,
    required this.state,
    this.postalCode,
    this.country = 'México',
  });

  String get fullAddress {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (number != null && number!.isNotEmpty) parts.add(number!);
    if (neighborhood != null && neighborhood!.isNotEmpty) {
      parts.add(neighborhood!);
    }
    parts.add(city);
    parts.add(state);
    if (postalCode != null && postalCode!.isNotEmpty) {
      parts.add('C.P. $postalCode');
    }
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      number: json['number'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'México',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'number': number,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
    };
  }
}
