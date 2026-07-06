import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/monthly_expense_record.dart';
import '../../models/prediction_result.dart';
import 'random_forest_regressor.dart';

class PredictionService {
  static const String modelVersion = 'rf-mobile-v1.1';

  PredictionService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? AppConfig.normalizedApiBaseUrl);

  final http.Client _client;
  final String _baseUrl;

  Future<PredictionResult> predictNextExpense(
    List<MonthlyExpenseRecord> history,
  ) async {
    final latest = history.last;
    final nextFeatures = _nextFeaturesFromLatest(latest);
    final targetPeriod = _nextPeriodFromLabel(latest.label);

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'month_index': nextFeatures[0].toInt(),
              'raw_materials': nextFeatures[1],
              'salaries': nextFeatures[2],
              'electricity': nextFeatures[3],
              'water': nextFeatures[4],
              'rent': nextFeatures[5],
              'promotion': nextFeatures[6],
              'operations': nextFeatures[7],
              'dominant_category': _dominantCategory(latest),
            }),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final metrics = (data['model_metrics'] as Map<String, dynamic>?) ?? {};

        return PredictionResult(
          predictedExpense: (data['predicted_expense'] as num).toDouble(),
          lowerBound: (data['lower_bound'] as num).toDouble(),
          upperBound: (data['upper_bound'] as num).toDouble(),
          targetPeriod: targetPeriod,
          dominantCategory: data['dominant_category']?.toString() ??
              _dominantCategory(latest),
          confidence: data['confidence']?.toString() ?? '80%',
          modelSource: 'API Random Forest',
          modelVersion: data['model_version']?.toString() ?? modelVersion,
          trainingSampleCount:
              (data['training_sample_count'] as num?)?.toInt() ??
                  history.length,
          trainedAt: data['trained_at']?.toString(),
          mae: (metrics['mae'] as num?)?.toDouble(),
          rmse: (metrics['rmse'] as num?)?.toDouble(),
          mape: (metrics['mape'] as num?)?.toDouble(),
        );
      }
    } catch (_) {
      // Fallback to local in-app model when API is unavailable.
    }

    return predictNextExpenseLocal(history);
  }

  PredictionResult predictNextExpenseLocal(List<MonthlyExpenseRecord> history) {
    final regressor = RandomForestRegressor();
    final features = history.map(_buildFeatureVector).toList();
    final targets = history.map((row) => row.totalExpense).toList();

    regressor.fit(features, targets);

    final latest = history.last;
    final nextFeatures = _nextFeaturesFromLatest(latest);
    final evaluation = _evaluateWalkForward(history);

    final result = regressor.predict(nextFeatures);
    final confidence = max(68, min(94, 100 - (result.spread / 150000))).round();
    final predictedExpense = result.mean.roundToDouble();

    return PredictionResult(
      predictedExpense: predictedExpense,
      lowerBound: (predictedExpense - (result.spread * 1.3)).roundToDouble(),
      upperBound: (predictedExpense + (result.spread * 1.3)).roundToDouble(),
      targetPeriod: _nextPeriodFromLabel(latest.label),
      dominantCategory: _dominantCategory(latest),
      confidence: '$confidence%',
      modelSource: 'Local Fallback',
      modelVersion: modelVersion,
      trainingSampleCount: history.length,
      trainedAt: DateTime.now().toIso8601String(),
      mae: evaluation.mae,
      rmse: evaluation.rmse,
      mape: evaluation.mape,
    );
  }

  List<double> _buildFeatureVector(MonthlyExpenseRecord record) {
    return [
      record.monthIndex.toDouble(),
      record.rawMaterials,
      record.salaries,
      record.electricity,
      record.water,
      record.rent,
      record.promotion,
      record.operations,
    ];
  }

  List<double> _nextFeaturesFromLatest(MonthlyExpenseRecord latest) {
    return [
      (latest.monthIndex + 1).toDouble(),
      (latest.rawMaterials * 1.03).roundToDouble(),
      (latest.salaries * 1.02).roundToDouble(),
      (latest.electricity * 1.01).roundToDouble(),
      (latest.water * 1.01).roundToDouble(),
      latest.rent,
      (latest.promotion * 1.04).roundToDouble(),
      (latest.operations * 1.03).roundToDouble(),
    ];
  }

  String _dominantCategory(MonthlyExpenseRecord record) {
    final categories = <String, double>{
      'Bahan Baku': record.rawMaterials,
      'Gaji': record.salaries,
      'Listrik': record.electricity,
      'Air': record.water,
      'Sewa': record.rent,
      'Promosi': record.promotion,
      'Operasional': record.operations,
    };

    return categories.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  _EvalResult _evaluateWalkForward(List<MonthlyExpenseRecord> history) {
    if (history.length < 8) {
      return const _EvalResult();
    }

    const minTrain = 6;
    final absoluteErrors = <double>[];
    final squaredErrors = <double>[];
    final percentageErrors = <double>[];

    for (var i = minTrain; i < history.length; i++) {
      final trainSlice = history.sublist(0, i);
      final model = RandomForestRegressor();
      model.fit(
        trainSlice.map(_buildFeatureVector).toList(),
        trainSlice.map((row) => row.totalExpense).toList(),
      );

      final previous = history[i - 1];
      final predicted = model.predict(_nextFeaturesFromLatest(previous)).mean;
      final actual = history[i].totalExpense;
      final error = (actual - predicted).abs();

      absoluteErrors.add(error);
      squaredErrors.add(pow(actual - predicted, 2).toDouble());
      if (actual > 0) {
        percentageErrors.add((error / actual) * 100);
      }
    }

    if (absoluteErrors.isEmpty) {
      return const _EvalResult();
    }

    final mae = absoluteErrors.reduce((a, b) => a + b) / absoluteErrors.length;
    final rmse =
        sqrt(squaredErrors.reduce((a, b) => a + b) / squaredErrors.length);
    final mape = percentageErrors.isEmpty
        ? null
        : percentageErrors.reduce((a, b) => a + b) / percentageErrors.length;
    return _EvalResult(mae: mae, rmse: rmse, mape: mape);
  }

  String _nextPeriodFromLabel(String label) {
    const monthMap = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };

    final parts = label.split(' ');
    if (parts.length != 2) {
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
    final month = monthMap[parts.first];
    final year = int.tryParse(parts.last);
    if (month == null || year == null) {
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }

    final next = DateTime(year, month + 1, 1);
    return '${next.year}-${next.month.toString().padLeft(2, '0')}';
  }
}

class _EvalResult {
  const _EvalResult({this.mae, this.rmse, this.mape});

  final double? mae;
  final double? rmse;
  final double? mape;
}
