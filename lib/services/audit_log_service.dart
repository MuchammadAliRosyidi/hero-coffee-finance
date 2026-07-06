import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/audit_log_item.dart';

class AuditLogService {
  static const String _key = 'audit_logs';

  Future<void> addLog(AuditLogItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getLogs();
    final updated = [item, ...current].take(100).toList();
    final payload = updated.map((e) => e.toMap()).toList();
    await prefs.setString(_key, jsonEncode(payload));
  }

  Future<List<AuditLogItem>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final logs = <AuditLogItem>[];
      for (final item in decoded) {
        if (item is Map) {
          logs.add(
            AuditLogItem.fromMap(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
      return logs;
    } catch (_) {
      return const [];
    }
  }
}
