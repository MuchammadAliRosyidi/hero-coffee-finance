import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget_settings.dart';

class BudgetService {
  static const String _budgetKey = 'monthly_expense_limit';

  Future<BudgetSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_budgetKey) ?? 20000000;
    return BudgetSettings(monthlyExpenseLimit: value);
  }

  Future<void> saveMonthlyLimit(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetKey, value);
  }
}
