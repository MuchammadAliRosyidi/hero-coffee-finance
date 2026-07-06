import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PeriodLockService {
  static const String _key = 'locked_periods';

  Future<List<String>> getLockedPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final periods = decoded.map((item) => item.toString()).toSet().toList();
      periods.sort((a, b) => b.compareTo(a));
      return periods;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> isLocked(String period) async {
    final periods = await getLockedPeriods();
    return periods.contains(period);
  }

  Future<void> setLocked(String period, bool locked) async {
    final periods = (await getLockedPeriods()).toSet();
    if (locked) {
      periods.add(period);
    } else {
      periods.remove(period);
    }
    final sorted = periods.toList()..sort((a, b) => b.compareTo(a));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(sorted));
  }
}
