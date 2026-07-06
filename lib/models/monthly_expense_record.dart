class MonthlyExpenseRecord {
  const MonthlyExpenseRecord({
    required this.monthIndex,
    required this.label,
    required this.totalExpense,
    required this.rawMaterials,
    required this.salaries,
    required this.electricity,
    required this.water,
    required this.rent,
    required this.promotion,
    required this.operations,
  });

  final int monthIndex;
  final String label;
  final double totalExpense;
  final double rawMaterials;
  final double salaries;
  final double electricity;
  final double water;
  final double rent;
  final double promotion;
  final double operations;
}
