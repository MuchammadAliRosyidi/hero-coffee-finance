import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/audit_log_item.dart';
import '../../models/budget_settings.dart';
import '../../models/finance_summary.dart';
import '../../models/monthly_report.dart';
import '../../models/outlet.dart';
import '../../utils/currency_formatter.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.user,
    required this.financeSummary,
    required this.transactionCount,
    required this.budgetSettings,
    required this.monthlyReports,
    required this.auditLogs,
    required this.outlets,
    required this.selectedOutletId,
    required this.onSelectOutlet,
    required this.onAddOutlet,
    required this.onSaveBudget,
    required this.onExportReport,
    required this.onExportPdf,
    required this.onExportModelHealth,
    required this.onImportCsv,
    required this.onSyncBackup,
    required this.onRetryPendingBackup,
    required this.onToggleCurrentMonthLock,
    required this.onLogout,
    required this.canEditBudget,
    required this.canExportReport,
    required this.canSyncBackup,
    required this.canManageOutlets,
    required this.canViewAuditLog,
    required this.canLockPeriods,
    required this.isCurrentMonthLocked,
    required this.lockedPeriods,
    required this.pendingBackupCount,
    required this.isExportingCsv,
    required this.isExportingPdf,
    required this.isExportingModelHealth,
    required this.isImportingCsv,
    required this.isSyncingBackup,
    required this.isRetryingBackup,
    required List recentTransactions,
  });

  final AppUser user;
  final FinanceSummary financeSummary;
  final int transactionCount;
  final BudgetSettings budgetSettings;
  final List<MonthlyReport> monthlyReports;
  final List<AuditLogItem> auditLogs;
  final List<Outlet> outlets;
  final String selectedOutletId;
  final ValueChanged<String> onSelectOutlet;
  final Future<void> Function() onAddOutlet;
  final Future<void> Function(double value) onSaveBudget;
  final Future<void> Function() onExportReport;
  final Future<void> Function() onExportPdf;
  final Future<void> Function() onExportModelHealth;
  final Future<void> Function() onImportCsv;
  final Future<void> Function() onSyncBackup;
  final Future<void> Function() onRetryPendingBackup;
  final Future<void> Function() onToggleCurrentMonthLock;
  final VoidCallback onLogout;
  final bool canEditBudget;
  final bool canExportReport;
  final bool canSyncBackup;
  final bool canManageOutlets;
  final bool canViewAuditLog;
  final bool canLockPeriods;
  final bool isCurrentMonthLocked;
  final List<String> lockedPeriods;
  final int pendingBackupCount;
  final bool isExportingCsv;
  final bool isExportingPdf;
  final bool isExportingModelHealth;
  final bool isImportingCsv;
  final bool isSyncingBackup;
  final bool isRetryingBackup;

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _card = Colors.white;
  static const Color _line = Color(0xFFE5E7EB);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _blue = Color(0xFF2F6DDE);
  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout = constraints.maxWidth < 900 || keyboardOpen;

        return Container(
          color: _bg,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 10),
              _buildOutletSelector(),
              const SizedBox(height: 10),
              _statsGrid(),
              const SizedBox(height: 10),
              _buildActionButtons(context),
              const SizedBox(height: 10),
              _buildRoleReports(compactLayout),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.role,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              user.isOwner ? 'Kontrol penuh' : 'Operasional',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutletSelector() {
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
          const Text(
            'Outlet Aktif',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, color: _blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedOutletId,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                    isExpanded: true,
                    items: outlets
                        .map((o) => DropdownMenuItem<String>(
                            value: o.id, child: Text(o.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onSelectOutlet(value);
                      }
                    },
                  ),
                ),
              ),
              if (canManageOutlets)
                IconButton.filledTonal(
                  onPressed: onAddOutlet,
                  tooltip: 'Tambah Outlet',
                  icon: const Icon(Icons.add_business_outlined),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final cards = <Widget>[
      _statCard('Transaksi', '$transactionCount item', Icons.receipt_long),
      _statCard('Saldo', currency(financeSummary.balance),
          Icons.account_balance_wallet),
      _statCard(
        'Batas Budget',
        currency(budgetSettings.monthlyExpenseLimit),
        Icons.savings_outlined,
      ),
      if (pendingBackupCount > 0)
        _statCard('Backup Pending', '$pendingBackupCount',
            Icons.cloud_upload_outlined),
    ];

    return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: cards.map((w) => SizedBox(width: 160, child: w)).toList());
  }

  Widget _statCard(String label, String value, IconData icon) {
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
          Icon(icon, size: 18, color: _blue),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canEditBudget)
                _actionBtn(
                  'Atur Budget',
                  () => _showBudgetDialog(context),
                  Icons.savings_outlined,
                ),
              if (canLockPeriods)
                _actionBtn(
                  isCurrentMonthLocked ? 'Buka Bulan Ini' : 'Kunci Bulan Ini',
                  onToggleCurrentMonthLock,
                  isCurrentMonthLocked
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline,
                ),
              if (canExportReport)
                _actionBtn(
                  'Export CSV',
                  !isExportingCsv ? onExportReport : null,
                  Icons.table_view_outlined,
                  loading: isExportingCsv,
                ),
              if (canExportReport)
                _actionBtn(
                  'Export PDF',
                  !isExportingPdf ? onExportPdf : null,
                  Icons.picture_as_pdf_outlined,
                  loading: isExportingPdf,
                ),
              if (canExportReport)
                _actionBtn(
                  'Export ML',
                  !isExportingModelHealth ? onExportModelHealth : null,
                  Icons.monitor_heart_outlined,
                  loading: isExportingModelHealth,
                ),
              _actionBtn(
                'Import CSV',
                !isImportingCsv ? onImportCsv : null,
                Icons.upload_file_outlined,
                loading: isImportingCsv,
              ),
              if (canSyncBackup)
                _actionBtn(
                  'Backup',
                  !isSyncingBackup ? onSyncBackup : null,
                  Icons.cloud_upload_outlined,
                  loading: isSyncingBackup,
                ),
              if (canSyncBackup && pendingBackupCount > 0)
                _actionBtn(
                  'Kirim Ulang',
                  !isRetryingBackup ? onRetryPendingBackup : null,
                  Icons.refresh_outlined,
                  loading: isRetryingBackup,
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
                onPressed: onLogout, child: const Text('Logout')),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, VoidCallback? onPressed, IconData icon,
      {bool loading = false}) {
    return SizedBox(
      width: 148,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: loading ? '$label sedang diproses' : label,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onPressed: onPressed,
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 17),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildReportContainer(
      {required Widget child, required String title, double? height}) {
    final container = Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _ink, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: _line),
          Expanded(child: child),
        ],
      ),
    );

    return SizedBox(height: height ?? 240, child: container);
  }

  Widget _buildRoleReports(bool compactLayout) {
    final reports = <Widget>[
      _buildReportContainer(
        height: compactLayout ? 220 : 260,
        title: 'Laporan Bulanan',
        child: _buildReportListView(),
      ),
    ];

    if (canLockPeriods) {
      reports.add(
        _buildReportContainer(
          height: compactLayout ? 180 : 260,
          title: 'Periode Terkunci',
          child: _buildLockedPeriods(),
        ),
      );
    }

    if (canViewAuditLog) {
      reports.add(
        _buildReportContainer(
          height: compactLayout ? 220 : 260,
          title: 'Audit Log',
          child: _buildAuditLogs(),
        ),
      );
    }

    if (compactLayout || reports.length == 1) {
      return Column(
        children: [
          for (final report in reports) ...[
            report,
            if (report != reports.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final report in reports) ...[
          Expanded(child: report),
          if (report != reports.last) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildReportListView() {
    if (monthlyReports.isEmpty) {
      return _emptyState(
        icon: Icons.bar_chart_rounded,
        title: 'Belum ada laporan bulanan',
        subtitle:
            'Laporan akan muncul setelah transaksi pemasukan dan pengeluaran tercatat.',
      );
    }

    return ListView.builder(
      itemCount: monthlyReports.length,
      itemBuilder: (context, index) {
        final item = monthlyReports[index];
        return ListTile(
          title: Text(item.period,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)),
          subtitle: Text(
            'Income ${currency(item.totalIncome)} | Expense ${currency(item.totalExpense)}',
            style: const TextStyle(color: _muted),
          ),
          trailing: Text(currency(item.net),
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)),
        );
      },
    );
  }

  Widget _buildAuditLogs() {
    if (auditLogs.isEmpty) {
      return _emptyState(
        icon: Icons.history_rounded,
        title: 'Audit log belum ada',
        subtitle:
            'Aktivitas penting seperti tambah transaksi, export, dan backup akan tampil di sini.',
      );
    }

    return ListView.builder(
      itemCount: auditLogs.length > 20 ? 20 : auditLogs.length,
      itemBuilder: (context, index) {
        final item = auditLogs[index];
        return ListTile(
          dense: true,
          title: Text('${item.action} - ${item.actor}',
              style: const TextStyle(
                  color: _ink, fontSize: 12, fontWeight: FontWeight.w700)),
          subtitle: Text(item.details,
              style: const TextStyle(color: _muted, fontSize: 11)),
          trailing: Text(
            item.timestamp.substring(0, 16).replaceFirst('T', ' '),
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
          ),
        );
      },
    );
  }

  Widget _buildLockedPeriods() {
    if (lockedPeriods.isEmpty) {
      return _emptyState(
        icon: Icons.lock_open_rounded,
        title: 'Belum ada periode terkunci',
        subtitle: 'Owner bisa mengunci bulan setelah laporan selesai.',
      );
    }

    return ListView.builder(
      itemCount: lockedPeriods.length,
      itemBuilder: (context, index) {
        final period = lockedPeriods[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.lock_outline, color: Color(0xFF2F6DDE)),
          title: Text(
            period,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Transaksi bulan ini tidak bisa diubah admin.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        );
      },
    );
  }

  Future<void> _showBudgetDialog(BuildContext context) async {
    final controller = TextEditingController(
        text: budgetSettings.monthlyExpenseLimit.toStringAsFixed(0));

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atur Budget Bulanan'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'contoh: 20000000'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                await onSaveBudget(value);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: _muted),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
