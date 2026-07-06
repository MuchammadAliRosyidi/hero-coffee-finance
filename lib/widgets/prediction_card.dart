import 'package:flutter/material.dart';

import '../models/prediction_result.dart';
import '../utils/currency_formatter.dart';

class PredictionCard extends StatelessWidget {
  const PredictionCard({
    super.key,
    required this.prediction,
  });

  final PredictionResult prediction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21493A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEEDB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Prediksi Random Forest',
              style: TextStyle(
                color: Color(0xFF21493A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Estimasi Pengeluaran Bulan Depan',
            style: TextStyle(
              color: Color(0xFFE5F4E7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency(prediction.predictedExpense),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rentang prediksi ${currency(prediction.lowerBound)} - ${currency(prediction.upperBound)}',
            style: const TextStyle(
              color: Color(0xFFC8E2CC),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PredictionMetaBox(
                  label: 'Akurasi Simulasi',
                  value: prediction.confidence,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PredictionMetaBox(
                  label: 'Biaya Dominan',
                  value: prediction.dominantCategory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PredictionMetaBox extends StatelessWidget {
  const _PredictionMetaBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B5F4C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC6E1CB),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
