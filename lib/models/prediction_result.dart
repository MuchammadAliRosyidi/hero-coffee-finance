class PredictionResult {
  const PredictionResult({
    required this.predictedExpense,
    required this.lowerBound,
    required this.upperBound,
    required this.targetPeriod,
    required this.dominantCategory,
    required this.confidence,
    required this.modelSource,
    required this.modelVersion,
    required this.trainingSampleCount,
    this.trainedAt,
    this.mae,
    this.rmse,
    this.mape,
  });

  final double predictedExpense;
  final double lowerBound;
  final double upperBound;
  final String targetPeriod;
  final String dominantCategory;
  final String confidence;
  final String modelSource;
  final String modelVersion;
  final int trainingSampleCount;
  final String? trainedAt;
  final double? mae;
  final double? rmse;
  final double? mape;
}
