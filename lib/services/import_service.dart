import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/transaction_item.dart';

class ImportService {
  Future<List<TransactionItem>> pickAndParseCsv({required String outletId}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) {
      return const [];
    }

    final file = File(result.files.single.path!);
    final content = await file.readAsLines();

    if (content.isEmpty) {
      return const [];
    }

    final items = <TransactionItem>[];
    for (var i = 1; i < content.length; i++) {
      final line = content[i].trim();
      if (line.isEmpty) {
        continue;
      }

      final parts = line.split(',');
      if (parts.length < 5) {
        continue;
      }

      final title = parts[0].trim();
      final category = parts[1].trim();
      final amount = double.tryParse(parts[2].trim());
      final typeRaw = parts[3].trim().toLowerCase();
      final date = parts[4].trim();

      if (amount == null) {
        continue;
      }

      final type = typeRaw == 'income'
          ? TransactionType.income
          : TransactionType.expense;
      final now = DateTime.now();
      items.add(
        TransactionItem(
          id: 'imp-${now.microsecondsSinceEpoch}-$i',
          title: title,
          category: category,
          amount: amount,
          type: type,
          date: date,
          createdAt: now.toIso8601String(),
          outletId: outletId,
        ),
      );
    }

    return items;
  }
}
