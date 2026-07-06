import 'dart:math';

class DataPoint {
  const DataPoint(this.features, this.target);

  final List<double> features;
  final double target;
}

class TreeNode {
  TreeNode.leaf(this.value)
      : featureIndex = null,
        threshold = null,
        left = null,
        right = null;

  TreeNode.branch({
    required this.featureIndex,
    required this.threshold,
    required this.left,
    required this.right,
  }) : value = null;

  final int? featureIndex;
  final double? threshold;
  final TreeNode? left;
  final TreeNode? right;
  final double? value;
}

class SplitResult {
  const SplitResult({
    required this.featureIndex,
    required this.threshold,
    required this.left,
    required this.right,
    required this.score,
  });

  final int featureIndex;
  final double threshold;
  final List<DataPoint> left;
  final List<DataPoint> right;
  final double score;
}

class PredictionStats {
  const PredictionStats({
    required this.mean,
    required this.spread,
  });

  final double mean;
  final double spread;
}

class RandomForestRegressor {
  RandomForestRegressor({
    this.nEstimators = 21,
    this.maxDepth = 5,
    this.minSamplesSplit = 2,
  });

  final int nEstimators;
  final int maxDepth;
  final int minSamplesSplit;
  final List<TreeNode> _trees = [];
  final Random _random = Random(21);

  void fit(List<List<double>> features, List<double> targets) {
    final dataset = List.generate(
      features.length,
      (index) => DataPoint(features[index], targets[index]),
    );

    _trees.clear();

    for (var i = 0; i < nEstimators; i++) {
      final bootstrap = List.generate(
        dataset.length,
        (_) => dataset[_random.nextInt(dataset.length)],
      );
      _trees.add(_buildTree(bootstrap, maxDepth));
    }
  }

  PredictionStats predict(List<double> features) {
    final predictions = _trees.map((tree) => _predictTree(tree, features)).toList();
    final mean = average(predictions);
    final spread = sqrt(variance(predictions));
    return PredictionStats(mean: mean, spread: spread);
  }

  TreeNode _buildTree(List<DataPoint> data, int depth) {
    if (data.length < minSamplesSplit || depth == 0) {
      return TreeNode.leaf(average(data.map((e) => e.target).toList()));
    }

    final split = _bestSplit(data);
    if (split == null || split.left.isEmpty || split.right.isEmpty) {
      return TreeNode.leaf(average(data.map((e) => e.target).toList()));
    }

    return TreeNode.branch(
      featureIndex: split.featureIndex,
      threshold: split.threshold,
      left: _buildTree(split.left, depth - 1),
      right: _buildTree(split.right, depth - 1),
    );
  }

  SplitResult? _bestSplit(List<DataPoint> data) {
    final featureCount = data.first.features.length;
    SplitResult? best;

    for (var featureIndex = 0; featureIndex < featureCount; featureIndex++) {
      final candidates = data
          .map((item) => item.features[featureIndex])
          .toSet()
          .toList()
        ..sort();

      for (final threshold in candidates) {
        final left = data
            .where((item) => item.features[featureIndex] <= threshold)
            .toList();
        final right = data
            .where((item) => item.features[featureIndex] > threshold)
            .toList();

        if (left.isEmpty || right.isEmpty) {
          continue;
        }

        final score = ((variance(left.map((e) => e.target).toList()) * left.length) +
                (variance(right.map((e) => e.target).toList()) * right.length)) /
            data.length;

        if (best == null || score < best.score) {
          best = SplitResult(
            featureIndex: featureIndex,
            threshold: threshold,
            left: left,
            right: right,
            score: score,
          );
        }
      }
    }

    return best;
  }

  double _predictTree(TreeNode node, List<double> features) {
    if (node.value != null) {
      return node.value!;
    }

    if (features[node.featureIndex!] <= node.threshold!) {
      return _predictTree(node.left!, features);
    }
    return _predictTree(node.right!, features);
  }
}

double average(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  return values.reduce((sum, value) => sum + value) / values.length;
}

double variance(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  final mean = average(values);
  return values
          .map((value) => pow(value - mean, 2).toDouble())
          .reduce((sum, value) => sum + value) /
      values.length;
}
