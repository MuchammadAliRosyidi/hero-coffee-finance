class ModelMonitoringItem {
  const ModelMonitoringItem({
    required this.period,
    this.predictedExpense,
    this.actualExpense,
    this.absoluteError,
    this.absolutePercentageError,
    required this.modelVersion,
    required this.createdAt,
  });

  final String period;
  final double? predictedExpense;
  final double? actualExpense;
  final double? absoluteError;
  final double? absolutePercentageError;
  final String modelVersion;
  final String createdAt;

  bool get isComplete => predictedExpense != null && actualExpense != null;

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'predicted_expense': predictedExpense,
      'actual_expense': actualExpense,
      'absolute_error': absoluteError,
      'absolute_percentage_error': absolutePercentageError,
      'model_version': modelVersion,
      'created_at': createdAt,
    };
  }

  factory ModelMonitoringItem.fromMap(Map<String, dynamic> map) {
    return ModelMonitoringItem(
      period: map['period']?.toString() ?? '',
      predictedExpense: (map['predicted_expense'] as num?)?.toDouble(),
      actualExpense: (map['actual_expense'] as num?)?.toDouble(),
      absoluteError: (map['absolute_error'] as num?)?.toDouble(),
      absolutePercentageError:
          (map['absolute_percentage_error'] as num?)?.toDouble(),
      modelVersion: map['model_version']?.toString() ?? '-',
      createdAt:
          map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  ModelMonitoringItem copyWith({
    double? predictedExpense,
    double? actualExpense,
    double? absoluteError,
    double? absolutePercentageError,
    String? modelVersion,
  }) {
    return ModelMonitoringItem(
      period: period,
      predictedExpense: predictedExpense ?? this.predictedExpense,
      actualExpense: actualExpense ?? this.actualExpense,
      absoluteError: absoluteError ?? this.absoluteError,
      absolutePercentageError:
          absolutePercentageError ?? this.absolutePercentageError,
      modelVersion: modelVersion ?? this.modelVersion,
      createdAt: createdAt,
    );
  }
}
