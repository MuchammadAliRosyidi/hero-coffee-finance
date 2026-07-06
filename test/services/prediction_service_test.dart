import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_coffee_finance/models/monthly_expense_record.dart';
import 'package:hero_coffee_finance/services/prediction/prediction_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  List<MonthlyExpenseRecord> buildHistory() {
    return const [
      MonthlyExpenseRecord(
        monthIndex: 1,
        label: 'Jan',
        totalExpense: 15000000,
        rawMaterials: 5000000,
        salaries: 4000000,
        electricity: 800000,
        water: 300000,
        rent: 2500000,
        promotion: 700000,
        operations: 1700000,
      ),
      MonthlyExpenseRecord(
        monthIndex: 2,
        label: 'Feb',
        totalExpense: 15800000,
        rawMaterials: 5300000,
        salaries: 4100000,
        electricity: 820000,
        water: 310000,
        rent: 2500000,
        promotion: 750000,
        operations: 2020000,
      ),
      MonthlyExpenseRecord(
        monthIndex: 3,
        label: 'Mar',
        totalExpense: 16200000,
        rawMaterials: 5500000,
        salaries: 4200000,
        electricity: 840000,
        water: 320000,
        rent: 2500000,
        promotion: 780000,
        operations: 2060000,
      ),
    ];
  }

  test('uses API prediction when endpoint returns 200', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/predict');
      return http.Response(
        jsonEncode({
          'predicted_expense': 17000000,
          'lower_bound': 16000000,
          'upper_bound': 18000000,
          'confidence': '85%',
          'dominant_category': 'Bahan Baku',
          'model_metrics': {
            'mae': 500000,
            'rmse': 650000,
            'mape': 6.2,
          },
        }),
        200,
      );
    });

    final service = PredictionService(client: client, baseUrl: 'http://test-api');
    final result = await service.predictNextExpense(buildHistory());

    expect(result.modelSource, 'API Random Forest');
    expect(result.predictedExpense, 17000000);
    expect(result.mape, 6.2);
  });

  test('falls back to local model when API unavailable', () async {
    final client = MockClient((request) async {
      return http.Response('server error', 500);
    });

    final service = PredictionService(client: client, baseUrl: 'http://test-api');
    final result = await service.predictNextExpense(buildHistory());

    expect(result.modelSource, 'Local Fallback');
    expect(result.predictedExpense, greaterThan(0));
  });
}
