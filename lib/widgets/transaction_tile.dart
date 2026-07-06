import 'package:flutter/material.dart';

import '../models/transaction_item.dart';
import '../utils/currency_formatter.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile(this.transaction, {super.key});

  final TransactionItem transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isIncome
                  ? const Color(0xFFDDF2E3)
                  : const Color(0xFFF5DED1),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              isIncome ? '+' : '-',
              style: const TextStyle(
                color: Color(0xFF3D2C24),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: Color(0xFF201815),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${transaction.date}',
                  style: const TextStyle(
                    color: Color(0xFF7B6A5C),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              '${isIncome ? '+' : '-'} ${currency(transaction.amount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isIncome
                    ? const Color(0xFF1C6B37)
                    : const Color(0xFFA34720),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
