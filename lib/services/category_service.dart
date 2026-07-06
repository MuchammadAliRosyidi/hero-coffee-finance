import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static const String _key = 'custom_expense_categories';

  Future<List<String>> getCategories(List<String> defaults) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return defaults;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final custom = decoded.map((e) => e.toString()).toList();
      final merged = [...defaults];
      for (final item in custom) {
        if (!merged.contains(item)) {
          merged.add(item);
        }
      }
      return merged;
    } catch (_) {
      return defaults;
    }
  }

  Future<void> saveCategories(List<String> categories, List<String> defaults) async {
    final prefs = await SharedPreferences.getInstance();
    final customOnly = categories.where((item) => !defaults.contains(item)).toList();
    await prefs.setString(_key, jsonEncode(customOnly));
  }
}
