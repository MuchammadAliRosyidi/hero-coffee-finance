enum TransactionType { income, expense }

class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
    this.outletId = 'main',
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final TransactionType type;
  final String date;
  final String createdAt;
  final String outletId;

  TransactionItem copyWith({
    String? title,
    String? category,
    double? amount,
    TransactionType? type,
    String? date,
    String? createdAt,
    String? outletId,
  }) {
    return TransactionItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      outletId: outletId ?? this.outletId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'type': type.name,
      'date': date,
      'created_at': createdAt,
      'outlet_id': outletId,
    };
  }

  factory TransactionItem.fromMap(Map<String, Object?> map) {
    return TransactionItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      date: map['date'] as String,
      createdAt:
          (map['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      outletId: (map['outlet_id'] as String?) ?? 'main',
    );
  }
}
