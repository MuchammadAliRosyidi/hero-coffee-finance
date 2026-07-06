import '../models/monthly_report.dart';
import '../models/transaction_item.dart';

class ReportService {
  List<MonthlyReport> monthlyReports(List<TransactionItem> transactions) {
    final buckets = <String, Map<String, double>>{};

    for (final item in transactions) {
      final period = item.createdAt.substring(0, 7);
      buckets.putIfAbsent(period, () => {'income': 0, 'expense': 0});
      if (item.type == TransactionType.income) {
        buckets[period]!['income'] = buckets[period]!['income']! + item.amount;
      } else {
        buckets[period]!['expense'] = buckets[period]!['expense']! + item.amount;
      }
    }

    final reports = buckets.entries
        .map(
          (entry) => MonthlyReport(
            period: entry.key,
            totalIncome: entry.value['income'] ?? 0,
            totalExpense: entry.value['expense'] ?? 0,
            net: (entry.value['income'] ?? 0) - (entry.value['expense'] ?? 0),
          ),
        )
        .toList();

    reports.sort((a, b) => b.period.compareTo(a.period));
    return reports;
  }
}
