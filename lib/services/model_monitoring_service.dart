import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/model_monitoring_item.dart';

class ModelMonitoringService {
  static const String _key = 'model_monitoring_items_v1';

  Future<List<ModelMonitoringItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .map((item) => ModelMonitoringItem.fromMap(
              Map<String, dynamic>.from(item as Map)))
          .toList();
      items.sort((a, b) => b.period.compareTo(a.period));
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsertPrediction({
    required String period,
    required double predictedExpense,
    required String modelVersion,
  }) async {
    final items = await getItems();
    final index = items.indexWhere((item) => item.period == period);
    if (index == -1) {
      items.add(
        ModelMonitoringItem(
          period: period,
          predictedExpense: predictedExpense,
          modelVersion: modelVersion,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    } else {
      items[index] = items[index].copyWith(
        predictedExpense: predictedExpense,
        modelVersion: modelVersion,
      );
    }
    await _save(items);
  }

  Future<void> upsertActual({
    required String period,
    required double actualExpense,
    String modelVersion = '-',
  }) async {
    final items = await getItems();
    final index = items.indexWhere((item) => item.period == period);
    if (index == -1) {
      items.add(
        ModelMonitoringItem(
          period: period,
          actualExpense: actualExpense,
          modelVersion: modelVersion,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    } else {
      final predicted = items[index].predictedExpense;
      final absError =
          predicted == null ? null : (actualExpense - predicted).abs();
      final ape = (predicted == null || actualExpense <= 0)
          ? null
          : ((absError! / actualExpense) * 100);
      items[index] = items[index].copyWith(
        actualExpense: actualExpense,
        absoluteError: absError,
        absolutePercentageError: ape,
      );
    }
    await _save(items);
  }

  Future<void> _save(List<ModelMonitoringItem> items) async {
    items.sort((a, b) => b.period.compareTo(a.period));
    final payload = items.take(24).map((item) => item.toMap()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(payload));
  }
}
