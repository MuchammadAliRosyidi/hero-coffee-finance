import '../models/finance_summary.dart';
import '../models/monthly_expense_record.dart';
import '../models/transaction_item.dart';

class FinanceService {
  const FinanceService();

  FinanceSummary calculateSummary(List<TransactionItem> transactions) {
    var totalIncome = 0.0;
    var totalExpense = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    return FinanceSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  Map<String, double> categoryBreakdown(List<TransactionItem> transactions) {
    final result = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        result[transaction.category] =
            (result[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return result;
  }

  List<MonthlyExpenseRecord> buildHistory(
    List<MonthlyExpenseRecord> history,
    List<TransactionItem> transactions,
  ) {
    if (history.isEmpty || transactions.isEmpty) {
      return history;
    }

    final timeline = <MonthlyExpenseRecord>[...history];
    final existingLabels = history.map((item) => item.label).toSet();
    final baseMonth = _parseMonthLabel(history.first.label);
    if (baseMonth == null) {
      return history;
    }

    final grouped = _groupExpenseByMonth(transactions);
    final sortedKeys = grouped.keys.toList()..sort();

    for (final key in sortedKeys) {
      final year = key ~/ 100;
      final month = key % 100;
      final label = _monthLabel(year, month);
      if (existingLabels.contains(label)) {
        continue;
      }

      final monthOffset =
          ((year - baseMonth.year) * 12) + (month - baseMonth.month);
      if (monthOffset < 0) {
        continue;
      }

      final breakdown = grouped[key]!;
      final total =
          breakdown.values.fold<double>(0, (sum, value) => sum + value);

      timeline.add(
        MonthlyExpenseRecord(
          monthIndex: history.first.monthIndex + monthOffset,
          label: label,
          totalExpense: total,
          rawMaterials: breakdown['Bahan Baku'] ?? 0,
          salaries: breakdown['Gaji'] ?? 0,
          electricity: breakdown['Listrik'] ?? 0,
          water: breakdown['Air'] ?? 0,
          rent: breakdown['Sewa'] ?? 0,
          promotion: breakdown['Promosi'] ?? 0,
          operations: breakdown['Operasional'] ?? 0,
        ),
      );
      existingLabels.add(label);
    }

    timeline.sort((a, b) => a.monthIndex.compareTo(b.monthIndex));
    return timeline;
  }

  List<TransactionItem> filterToCurrentMonth(
      List<TransactionItem> transactions) {
    final now = DateTime.now();
    return transactions.where((item) {
      final date = DateTime.tryParse(item.createdAt);
      if (date == null) {
        return false;
      }
      return date.year == now.year && date.month == now.month;
    }).toList();
  }

  Map<int, Map<String, double>> _groupExpenseByMonth(
      List<TransactionItem> transactions) {
    final grouped = <int, Map<String, double>>{};

    for (final item in transactions) {
      if (item.type != TransactionType.expense) {
        continue;
      }
      final date = DateTime.tryParse(item.createdAt);
      if (date == null) {
        continue;
      }

      final key = (date.year * 100) + date.month;
      grouped.putIfAbsent(key, () => <String, double>{});
      grouped[key]![item.category] =
          (grouped[key]![item.category] ?? 0) + item.amount;
    }

    return grouped;
  }

  _YearMonth? _parseMonthLabel(String label) {
    final parts = label.trim().split(' ');
    if (parts.length != 2) {
      return null;
    }
    final month = _monthNameToNumber(parts.first);
    final year = int.tryParse(parts.last);
    if (month == null || year == null) {
      return null;
    }
    return _YearMonth(year: year, month: month);
  }

  int? _monthNameToNumber(String monthName) {
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
    return monthMap[monthName];
  }

  String _monthLabel(int year, int month) {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${monthNames[month - 1]} $year';
  }
}

class _YearMonth {
  const _YearMonth({required this.year, required this.month});

  final int year;
  final int month;
}
