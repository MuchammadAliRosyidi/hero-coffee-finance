import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/transaction_item.dart';
import '../../utils/currency_formatter.dart';

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({
    super.key,
    required this.transactions,
    required this.breakdown,
    required this.titleController,
    required this.amountController,
    required this.searchController,
    required this.expenseCategories,
    required this.selectedType,
    required this.selectedCategory,
    required this.selectedFilterType,
    required this.selectedOutletName,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onFilterTypeChanged,
    required this.onSearchChanged,
    required this.onManageCategories,
    required this.onSave,
    required this.onEdit,
    required this.onDelete,
    required this.canCreateTransaction,
    required this.canEditTransaction,
    required this.canDeleteTransaction,
    required this.canManageCategories,
    required this.isSavingTransaction,
  });

  final List<TransactionItem> transactions;
  final Map<String, double> breakdown;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController searchController;
  final List<String> expenseCategories;
  final TransactionType selectedType;
  final String selectedCategory;
  final TransactionType? selectedFilterType;
  final String selectedOutletName;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<TransactionType?> onFilterTypeChanged;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onManageCategories;
  final Future<void> Function() onSave;
  final Future<void> Function(TransactionItem item) onEdit;
  final Future<void> Function(String id) onDelete;
  final bool canCreateTransaction;
  final bool canEditTransaction;
  final bool canDeleteTransaction;
  final bool canManageCategories;
  final bool isSavingTransaction;

  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _card = Colors.white;
  static const Color _line = Color(0xFFE5E7EB);
  static const Color _blue = Color(0xFF2F6DDE);
  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final dominant = breakdown.entries.isEmpty
        ? null
        : breakdown.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return Container(
      color: const Color(0xFFF5F7FB),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
        children: [
          _buildInputCard(),
          const SizedBox(height: 12),
          _buildDominantBanner(dominant),
          const SizedBox(height: 12),
          _buildFilterSection(),
          const SizedBox(height: 12),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: _muted, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Outlet aktif: $selectedOutletName',
                  style: const TextStyle(
                      color: _muted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(color: _ink),
            decoration:
                _inputDecoration('Cari judul atau kategori...').copyWith(
              prefixIcon: const Icon(Icons.search, color: _muted),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFilterChip('Semua', selectedFilterType == null, () {
                onFilterTypeChanged(null);
              }),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Pemasukan',
                selectedFilterType == TransactionType.income,
                () => onFilterTypeChanged(TransactionType.income),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Pengeluaran',
                selectedFilterType == TransactionType.expense,
                () => onFilterTypeChanged(TransactionType.expense),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? _blue : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDominantBanner(MapEntry<String, double>? dominant) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F6DDE), Color(0xFF255FC4)],
        ),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Text(
        dominant == null
            ? 'Belum ada pengeluaran tercatat pada filter ini.'
            : 'Pengeluaran dominan: ${dominant.key} (${currency(dominant.value)})',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _line),
        ),
        child: const Text(
          'Tidak ada transaksi yang cocok dengan filter.',
          style: TextStyle(color: _muted),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: ListView.separated(
        itemCount: transactions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const Divider(height: 1, color: _line),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final income = transaction.type == TransactionType.income;
          return Semantics(
            label:
                'Transaksi ${transaction.title}, ${income ? 'pemasukan' : 'pengeluaran'}, ${currency(transaction.amount)}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: income
                        ? const Color(0xFFE8F3FF)
                        : const Color(0xFFFFEFEF),
                    child: Icon(
                      income
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: income
                          ? const Color(0xFF2F6DDE)
                          : const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${transaction.category} | ${transaction.date}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 138),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${income ? '+' : '-'} ${currency(transaction.amount)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: income
                                ? const Color(0xFF2F6DDE)
                                : const Color(0xFFE53935),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Edit transaksi',
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 19,
                                color: canEditTransaction
                                    ? _muted
                                    : const Color(0xFFCBD5E1),
                              ),
                              onPressed: canEditTransaction
                                  ? () => onEdit(transaction)
                                  : null,
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Hapus transaksi',
                              icon: Icon(
                                Icons.delete_outline,
                                size: 19,
                                color: canDeleteTransaction
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFFCBD5E1),
                              ),
                              onPressed: canDeleteTransaction
                                  ? () => onDelete(transaction.id)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!canCreateTransaction)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Text(
                'Role ini hanya bisa melihat transaksi.',
                style: TextStyle(
                    color: Color(0xFFB45309), fontWeight: FontWeight.w600),
              ),
            ),
          TextField(
            controller: titleController,
            enabled: canCreateTransaction,
            style: const TextStyle(color: _ink),
            decoration: _inputDecoration('Nama transaksi'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            enabled: canCreateTransaction,
            style: const TextStyle(color: _ink),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('Nominal'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan angka tanpa titik/koma. Contoh: 150000',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          const Text(
            'Jenis transaksi',
            style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: TransactionType.values.map((type) {
              final active = selectedType == type;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type == TransactionType.income ? 6 : 0,
                    left: type == TransactionType.expense ? 6 : 0,
                  ),
                  child: InkWell(
                    onTap:
                        canCreateTransaction ? () => onTypeChanged(type) : null,
                    borderRadius: BorderRadius.circular(_radius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: active ? _blue : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      child: Text(
                        type == TransactionType.income
                            ? 'Pemasukan'
                            : 'Pengeluaran',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active ? Colors.white : _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kategori',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: canManageCategories ? onManageCategories : null,
                child: const Text('Kelola'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: expenseCategories.map((category) {
              final active = selectedCategory == category;
              return InkWell(
                onTap: canCreateTransaction
                    ? () => onCategoryChanged(category)
                    : null,
                borderRadius: BorderRadius.circular(_radius),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? _blue : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(_radius),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: active ? Colors.white : _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_radius)),
              ),
              onPressed: canCreateTransaction && !isSavingTransaction
                  ? () => onSave()
                  : null,
              child: isSavingTransaction
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Simpan Transaksi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _blue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
