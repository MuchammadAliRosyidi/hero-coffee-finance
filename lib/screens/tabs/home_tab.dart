import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/finance_summary.dart';
import '../../models/transaction_item.dart';
import '../../utils/currency_formatter.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.user,
    required this.selectedOutletName,
    required this.currentMonthSummary,
    required this.currentMonthTransactions,
    required this.allTimeSummary,
    required this.allTimeTransactions,
    required this.onAddTransactionTap,
  });

  final AppUser user;
  final String selectedOutletName;
  final FinanceSummary currentMonthSummary;
  final List<TransactionItem> currentMonthTransactions;
  final FinanceSummary allTimeSummary;
  final List<TransactionItem> allTimeTransactions;
  final VoidCallback onAddTransactionTap;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _card = Colors.white;
  static const Color _line = Color(0xFFE5E7EB);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _blue = Color(0xFF2F6DDE);
  static const double _radius = 8;

  bool _showAllTime = false;

  @override
  Widget build(BuildContext context) {
    if (widget.user.isAdmin) {
      return _buildAdminHome();
    }

    return _buildOwnerHome();
  }

  Widget _buildOwnerHome() {
    final financeSummary =
        _showAllTime ? widget.allTimeSummary : widget.currentMonthSummary;
    final recentTransactions = _showAllTime
        ? widget.allTimeTransactions
        : widget.currentMonthTransactions;
    final expense = financeSummary.totalExpense;
    final budget = expense <= 0 ? 1.0 : expense * 1.2;
    final shortScreen = MediaQuery.of(context).size.height < 760;

    return Container(
      color: _bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ownerHeader(financeSummary),
            const SizedBox(height: 12),
            _periodToggle(),
            const SizedBox(height: 12),
            const Text(
              'Anggaran Pengeluaran',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: _ink,
              ),
            ),
            const SizedBox(height: 10),
            shortScreen
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 140,
                        child: _budgetRing('Makan', expense * 0.35, budget),
                      ),
                      SizedBox(
                        width: 140,
                        child: _budgetRing('Transport', expense * 0.25, budget),
                      ),
                      SizedBox(
                        width: 140,
                        child: _budgetRing('Lain-lain', expense * 0.2, budget),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _budgetRing('Makan', expense * 0.35, budget),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _budgetRing('Transport', expense * 0.25, budget),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _budgetRing('Lain-lain', expense * 0.2, budget),
                      ),
                    ],
                  ),
            const SizedBox(height: 14),
            _insightCard(financeSummary, budget),
            const SizedBox(height: 12),
            _quickGuideCard(),
            const SizedBox(height: 14),
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            recentTransactions.isEmpty
                ? _emptyTransactionState()
                : _recentTransactionList(recentTransactions),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHome() {
    final todayTransactions = _todayTransactions(widget.allTimeTransactions);
    final todaySummary = _summaryFor(todayTransactions);

    return Container(
      color: _bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _adminHeader(todaySummary),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Pemasukan Hari Ini',
                    todaySummary.totalIncome,
                    true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    'Pengeluaran Hari Ini',
                    todaySummary.totalExpense,
                    false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _adminTaskCard(todayTransactions.length),
            const SizedBox(height: 14),
            const Text(
              'Transaksi Terakhir Outlet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            widget.allTimeTransactions.isEmpty
                ? _emptyTransactionState()
                : _recentTransactionList(widget.allTimeTransactions, limit: 6),
          ],
        ),
      ),
    );
  }

  Widget _ownerHeader(FinanceSummary financeSummary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Halo Owner,\nRingkasan bisnis',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FF),
                  borderRadius: BorderRadius.circular(_radius),
                ),
                child: Text(
                  _showAllTime ? 'Semua Waktu' : 'Bulan Ini',
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              currency(financeSummary.balance),
              style: const TextStyle(
                color: _ink,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child:
                    _summaryCard('Pemasukan', financeSummary.totalIncome, true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                    'Pengeluaran', financeSummary.totalExpense, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminHeader(FinanceSummary todaySummary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F3FF),
            child: Icon(Icons.badge_outlined, color: _blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${widget.user.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Outlet: ${widget.selectedOutletName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3FF),
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: const Text(
              'Hari Ini',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminTaskCard(int todayCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined, color: _blue),
              SizedBox(width: 8),
              Text(
                'Tugas Operasional',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$todayCount transaksi dicatat hari ini. Pastikan pemasukan dan pengeluaran outlet sudah lengkap.',
            style: const TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onAddTransactionTap,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Transaksi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _periodButton(
              label: 'Bulan Ini',
              selected: !_showAllTime,
              onTap: () => setState(() => _showAllTime = false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _periodButton(
              label: 'Semua Waktu',
              selected: _showAllTime,
              onTap: () => setState(() => _showAllTime = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter periode $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _blue : _card,
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, double value, bool positive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            currency(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  positive ? const Color(0xFF22C55E) : const Color(0xFFE53935),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetRing(String label, double spent, double budget) {
    final progress = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    return Semantics(
      label: '$label, terpakai ${(progress * 100).toStringAsFixed(0)} persen',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              width: 56,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                backgroundColor: const Color(0xFFE8ECF2),
                valueColor: const AlwaysStoppedAnimation(_blue),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightCard(FinanceSummary financeSummary, double budget) {
    final ratio = (financeSummary.totalExpense / budget).clamp(0.0, 1.5);
    final percent = (ratio * 100).toStringAsFixed(0);
    final status = ratio >= 1
        ? 'Melewati batas'
        : ratio >= 0.8
            ? 'Mendekati batas'
            : 'Masih aman';

    return _infoCard(
      icon: Icons.insights,
      title: 'Insight Utama Bulan Ini',
      subtitle: 'Budget terpakai $percent% - $status',
    );
  }

  Widget _quickGuideCard() {
    return _infoCard(
      icon: Icons.show_chart,
      title: 'Analisis Owner',
      subtitle: 'Lihat tren, perbandingan, dan prediksi detail di tab Grafik.',
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F3FF),
            child: Icon(icon, color: _blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentTransactionList(List<TransactionItem> items, {int limit = 4}) {
    return ListView.separated(
      itemCount: items.length > limit ? limit : items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = items[index];
        final negative = t.type == TransactionType.expense;
        return Semantics(
          label:
              'Transaksi ${t.title}, ${negative ? 'pengeluaran' : 'pemasukan'} ${currency(t.amount)} tanggal ${t.date}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: negative
                      ? const Color(0xFFFFEFEF)
                      : const Color(0xFFE8F3FF),
                  child: Icon(
                    negative
                        ? Icons.north_east_rounded
                        : Icons.south_west_rounded,
                    color: negative ? const Color(0xFFE53935) : _blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.category} | ${t.date}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    '${negative ? '-' : '+'} ${currency(t.amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: negative
                          ? const Color(0xFFE53935)
                          : const Color(0xFF22C55E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyTransactionState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: _muted, size: 30),
          SizedBox(height: 8),
          Text(
            'Belum ada transaksi',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Tambahkan transaksi pertama dari tab Transaksi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<TransactionItem> _todayTransactions(List<TransactionItem> items) {
    final now = DateTime.now();
    return items.where((item) {
      final createdAt = DateTime.tryParse(item.createdAt);
      if (createdAt == null) {
        return false;
      }
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).toList();
  }

  FinanceSummary _summaryFor(List<TransactionItem> items) {
    var income = 0.0;
    var expense = 0.0;
    for (final item in items) {
      if (item.type == TransactionType.income) {
        income += item.amount;
      } else {
        expense += item.amount;
      }
    }
    return FinanceSummary(totalIncome: income, totalExpense: expense);
  }
}
