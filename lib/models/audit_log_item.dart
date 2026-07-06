class AuditLogItem {
  const AuditLogItem({
    required this.action,
    required this.actor,
    required this.timestamp,
    required this.details,
  });

  final String action;
  final String actor;
  final String timestamp;
  final String details;

  Map<String, String> toMap() {
    return {
      'action': action,
      'actor': actor,
      'timestamp': timestamp,
      'details': details,
    };
  }

  factory AuditLogItem.fromMap(Map<String, dynamic> map) {
    return AuditLogItem(
      action: map['action']?.toString() ?? '-',
      actor: map['actor']?.toString() ?? '-',
      timestamp: map['timestamp']?.toString() ?? '-',
      details: map['details']?.toString() ?? '-',
    );
  }
}
