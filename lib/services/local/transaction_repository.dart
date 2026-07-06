import 'package:sqflite/sqflite.dart';

import '../../data/sample_data.dart';
import '../../models/transaction_item.dart';
import 'database_helper.dart';

class TransactionRepository {
  Future<List<TransactionItem>> getTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'transactions',
      orderBy: 'created_at DESC, id DESC',
    );

    if (rows.isEmpty) {
      await seedInitialTransactions();
      final seededRows = await db.query(
        'transactions',
        orderBy: 'created_at DESC, id DESC',
      );
      return seededRows.map(TransactionItem.fromMap).toList();
    }

    return rows.map(TransactionItem.fromMap).toList();
  }

  Future<void> insertTransaction(TransactionItem transaction) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(TransactionItem transaction) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedInitialTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    for (final transaction in seedTransactions) {
      batch.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Backward-compatible alias for older call sites.
  Future<void> update(TransactionItem item) => updateTransaction(item);
}
