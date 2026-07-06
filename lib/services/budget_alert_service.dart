import 'package:shared_preferences/shared_preferences.dart';

class BudgetAlertService {
  static const String _key = 'budget_alert_level';

  Future<int> checkAndGetNewLevel({
    required double totalExpense,
    required double limit,
  }) async {
    if (limit <= 0) {
      return 0;
    }

    final percent = (totalExpense / limit) * 100;
    var level = 0;
    if (percent >= 100) {
      level = 100;
    } else if (percent >= 90) {
      level = 90;
    } else if (percent >= 80) {
      level = 80;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastLevel = prefs.getInt(_key) ?? 0;

    if (level > lastLevel) {
      await prefs.setInt(_key, level);
      return level;
    }

    return 0;
  }

  Future<void> resetIfBelowThreshold({
    required double totalExpense,
    required double limit,
  }) async {
    if (limit <= 0) {
      return;
    }

    final percent = (totalExpense / limit) * 100;
    if (percent < 75) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, 0);
    }
  }
}
