class MonthlyReport {
  const MonthlyReport({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
  });

  final String period;
  final double totalIncome;
  final double totalExpense;
  final double net;
}
