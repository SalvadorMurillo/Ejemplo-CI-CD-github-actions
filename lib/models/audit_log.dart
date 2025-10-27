class AuditLog {
  final String id;
  final String tableName;
  final String recordId;
  final String action; // INSERT, UPDATE, or DELETE
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final List<String>? changedFields;
  final String? userId;
  final String? userEmail;
  final String? ipAddress;
  final String? userAgent;
  final String? reason;
  final DateTime createdAt;

  // Información del usuario (cargada mediante join)
  final String? userName;

  AuditLog({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.action,
    this.oldValues,
    this.newValues,
    this.changedFields,
    this.userId,
    this.userEmail,
    this.ipAddress,
    this.userAgent,
    this.reason,
    required this.createdAt,
    this.userName,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      tableName: json['table_name'] as String,
      recordId: json['record_id'] as String,
      action: json['action'] as String,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      changedFields: json['changed_fields'] != null
          ? List<String>.from(json['changed_fields'] as List)
          : null,
      userId: json['user_id'] as String?,
      userEmail: json['user_email'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'old_values': oldValues,
      'new_values': newValues,
      'changed_fields': changedFields,
      'user_id': userId,
      'user_email': userEmail,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
