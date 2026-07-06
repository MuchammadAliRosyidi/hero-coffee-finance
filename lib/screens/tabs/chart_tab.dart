import 'package:flutter/material.dart';

import '../../models/finance_summary.dart';
import '../../models/model_monitoring_item.dart';
import '../../models/monthly_report.dart';
import '../../models/prediction_result.dart';
import '../../utils/currency_formatter.dart';

enum _ChartMetric { expense, income }

class ChartTab extends StatefulWidget {
  const ChartTab({
    super.key,
    required this.financeSummary,
    required this.prediction,
    required this.dominantExpense,
    required this.monthlyReports,
    required this.monitoringItems,
    required this.canViewFullPrediction,
  });

  final FinanceSummary financeSummary;
  final PredictionResult prediction;
  final MapEntry<String, double>? dominantExpense;
  final List<MonthlyReport> monthlyReports;
  final List<ModelMonitoringItem> monitoringItems;
  final bool canViewFullPrediction;

  @override
  State<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<ChartTab> {
  _ChartMetric _chartMetric = _ChartMetric.expense;
  int _rangeMonths = 6;
  int? _selectedChartIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _insightCard(),
          const SizedBox(height: 12),
          _trendChartCard(),
          if (widget.canViewFullPrediction) ...[
            const SizedBox(height: 12),
            _predictionCard(),
          ],
        ],
      ),
    );
  }

  Widget _trendChartCard() {
    final reports =
        widget.monthlyReports.take(_rangeMonths).toList().reversed.toList();
    final values = reports
        .map((e) => _chartMetric == _ChartMetric.expense
            ? e.totalExpense
            : e.totalIncome)
        .toList();

    if (_selectedChartIndex != null && _selectedChartIndex! >= values.length) {
      _selectedChartIndex = null;
    }

    final selectedValue = (_selectedChartIndex != null && values.isNotEmpty)
        ? values[_selectedChartIndex!]
        : null;
    final selectedLabel = (_selectedChartIndex != null && reports.isNotEmpty)
        ? reports[_selectedChartIndex!].period
        : null;
    final predictedByPeriod = <String, double>{};
    for (final item in widget.monitoringItems) {
      if (item.predictedExpense != null) {
        predictedByPeriod[item.period] = item.predictedExpense!;
      }
    }
    final predictedValues = reports
        .map((report) => predictedByPeriod[report.period])
        .toList(growable: false);
    final hasPredictionOverlay = widget.canViewFullPrediction &&
        _chartMetric == _ChartMetric.expense &&
        predictedValues.any((value) => value != null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Bulanan',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _segButton('Expense', _chartMetric == _ChartMetric.expense, () {
                setState(() {
                  _chartMetric = _ChartMetric.expense;
                  _selectedChartIndex = null;
                });
              }),
              const SizedBox(width: 8),
              _segButton('Income', _chartMetric == _ChartMetric.income, () {
                setState(() {
                  _chartMetric = _ChartMetric.income;
                  _selectedChartIndex = null;
                });
              }),
              const Spacer(),
              _rangeBtn('3B', _rangeMonths == 3, () {
                setState(() {
                  _rangeMonths = 3;
                  _selectedChartIndex = null;
                });
              }),
              const SizedBox(width: 6),
              _rangeBtn('6B', _rangeMonths == 6, () {
                setState(() {
                  _rangeMonths = 6;
                  _selectedChartIndex = null;
                });
              }),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: values.length < 2
                ? const Center(
                    child: Text(
                      'Data belum cukup untuk chart',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (details) {
                          final index = ((details.localPosition.dx /
                                      constraints.maxWidth) *
                                  (values.length - 1))
                              .round()
                              .clamp(0, values.length - 1);
                          setState(() => _selectedChartIndex = index);
                        },
                        child: CustomPaint(
                          painter: _MiniLineChartPainter(
                            values: values,
                            selectedIndex: _selectedChartIndex,
                            secondaryValues:
                                hasPredictionOverlay ? predictedValues : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (hasPredictionOverlay) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                _LegendDot(color: Color(0xFF2F6DDE), label: 'Aktual'),
                SizedBox(width: 10),
                _LegendDot(color: Color(0xFFEA580C), label: 'Prediksi'),
              ],
            ),
          ],
          const SizedBox(height: 6),
          if (reports.isNotEmpty)
            Wrap(
              spacing: 8,
              children: reports
                  .map((r) => Text(
                        r.period,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 10),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 6),
          Text(
            selectedValue == null
                ? 'Ketuk chart untuk lihat detail nilai bulan tertentu'
                : '$selectedLabel: ${currency(selectedValue)}',
            style: const TextStyle(
                color: Color(0xFF111827), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _segButton(String text, bool active, VoidCallback onTap) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? const Color(0xFF2F6DDE) : Colors.white,
          foregroundColor: active ? Colors.white : const Color(0xFF111827),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _rangeBtn(String text, bool active, VoidCallback onTap) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? const Color(0xFFE8F3FF) : Colors.white,
          foregroundColor: const Color(0xFF111827),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          minimumSize: const Size(48, 40),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _predictionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F6DDE), Color(0xFF255FC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prediksi Bulan Depan',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            currency(widget.prediction.predictedExpense),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Rentang: ${currency(widget.prediction.lowerBound)} - ${currency(widget.prediction.upperBound)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'Confidence: ${widget.prediction.confidence} | Kategori dominan: ${widget.prediction.dominantCategory}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _insightCard() {
    final reports = widget.monthlyReports.toList();
    final current = reports.isNotEmpty
        ? reports.first.totalExpense
        : widget.financeSummary.totalExpense;
    final previous = reports.length > 1 ? reports[1].totalExpense : current;
    final mom = previous <= 0 ? 0.0 : ((current - previous) / previous) * 100;
    final recentApe = widget.monitoringItems
        .where((item) => item.absolutePercentageError != null)
        .map((item) => item.absolutePercentageError!)
        .toList();
    final latestApe = recentApe.isEmpty ? null : recentApe.first;
    final risk = _riskStatus(mom, latestApe);
    final detail = widget.canViewFullPrediction
        ? 'MoM Expense: ${mom >= 0 ? '+' : ''}${mom.toStringAsFixed(1)}% | Dominan: ${widget.dominantExpense?.key ?? '-'}'
        : 'MoM Expense: ${mom >= 0 ? '+' : ''}${mom.toStringAsFixed(1)}% | Grafik operasional outlet';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F3FF),
            child: Icon(Icons.insights, color: Color(0xFF2F6DDE)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight Grafik',
                  style: TextStyle(
                      color: Color(0xFF111827), fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 6),
                _riskBadge(risk),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _RiskStatus _riskStatus(double mom, double? ape) {
    if (mom >= 15 || (ape != null && ape >= 20)) {
      return const _RiskStatus(
        label: 'Kritis',
        bg: Color(0xFFFEE2E2),
        fg: Color(0xFFB91C1C),
      );
    }
    if (mom >= 8 || (ape != null && ape >= 12)) {
      return const _RiskStatus(
        label: 'Waspada',
        bg: Color(0xFFFFF7D6),
        fg: Color(0xFF92400E),
      );
    }
    return const _RiskStatus(
      label: 'Normal',
      bg: Color(0xFFDCFCE7),
      fg: Color(0xFF166534),
    );
  }

  Widget _riskBadge(_RiskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Status Risiko: ${status.label}',
        style: TextStyle(
          color: status.fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  _MiniLineChartPainter({
    required this.values,
    required this.selectedIndex,
    this.secondaryValues,
    this.lineColor = const Color(0xFF2F6DDE),
    this.drawArea = true,
  });

  final List<double> values;
  final int? selectedIndex;
  final List<double?>? secondaryValues;
  final Color lineColor;
  final bool drawArea;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final merged = <double>[...values];
    if (secondaryValues != null) {
      merged.addAll(secondaryValues!.whereType<double>());
    }
    final minValue = merged.reduce((a, b) => a < b ? a : b);
    final maxValue = merged.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 1 ? 1.0 : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalized = (values[i] - minValue) / range;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      points.add(Offset(x, y));
    }

    if (drawArea) {
      final areaPath = Path()..moveTo(points.first.dx, size.height);
      for (final point in points) {
        areaPath.lineTo(point.dx, point.dy);
      }
      areaPath
        ..lineTo(points.last.dx, size.height)
        ..close();

      final areaPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x332F6DDE), Color(0x002F6DDE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(areaPath, areaPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      final radius = selectedIndex == i ? 5.0 : 3.0;
      canvas.drawCircle(points[i], radius, dotPaint);
    }

    if (secondaryValues != null && secondaryValues!.length == values.length) {
      final secondaryPoints = <Offset?>[];
      for (var i = 0; i < secondaryValues!.length; i++) {
        final value = secondaryValues![i];
        if (value == null) {
          secondaryPoints.add(null);
          continue;
        }
        final x = (i / (values.length - 1)) * size.width;
        final normalized = (value - minValue) / range;
        final y = size.height - (normalized * (size.height - 8)) - 4;
        secondaryPoints.add(Offset(x, y));
      }
      final secondaryPaint = Paint()
        ..color = const Color(0xFFEA580C)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final secondaryPath = Path();
      var started = false;
      for (final point in secondaryPoints) {
        if (point == null) {
          started = false;
          continue;
        }
        if (!started) {
          secondaryPath.moveTo(point.dx, point.dy);
          started = true;
        } else {
          secondaryPath.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(secondaryPath, secondaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.secondaryValues != secondaryValues ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.drawArea != drawArea;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _RiskStatus {
  const _RiskStatus({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;
}
