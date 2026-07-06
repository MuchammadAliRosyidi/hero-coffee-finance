class FinanceSummary {
  const FinanceSummary({
    required this.totalIncome,
    required this.totalExpense,
  });

  final double totalIncome;
  final double totalExpense;

  double get balance => totalIncome - totalExpense;
}
