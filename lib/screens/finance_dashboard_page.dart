import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hero_coffee_finance/data/sample_data.dart';
import 'package:hero_coffee_finance/models/app_user.dart';
import 'package:hero_coffee_finance/models/audit_log_item.dart';
import 'package:hero_coffee_finance/models/budget_settings.dart';
import 'package:hero_coffee_finance/models/outlet.dart';
import 'package:hero_coffee_finance/models/prediction_result.dart';
import 'package:hero_coffee_finance/models/model_monitoring_item.dart';
import 'package:hero_coffee_finance/models/transaction_item.dart';
import 'package:hero_coffee_finance/services/audit_log_service.dart';
import 'package:hero_coffee_finance/services/budget_alert_service.dart';
import 'package:hero_coffee_finance/services/budget_service.dart';
import 'package:hero_coffee_finance/services/category_service.dart';
import 'package:hero_coffee_finance/services/export_service.dart';
import 'package:hero_coffee_finance/services/finance_service.dart';
import 'package:hero_coffee_finance/services/import_service.dart';
import 'package:hero_coffee_finance/services/local/transaction_repository.dart';
import 'package:hero_coffee_finance/services/model_monitoring_service.dart';
import 'package:hero_coffee_finance/services/outlet_service.dart';
import 'package:hero_coffee_finance/services/period_lock_service.dart';
import 'package:hero_coffee_finance/services/prediction/prediction_service.dart';
import 'package:hero_coffee_finance/services/report_service.dart';
import 'package:hero_coffee_finance/services/sync_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/transactions_tab.dart';
import 'tabs/chart_tab.dart';

class FinanceDashboardPage extends StatefulWidget {
  const FinanceDashboardPage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends State<FinanceDashboardPage> {
  static const Color _pageBackground = Color(0xFFF5F7FB);
  static const Color _surfaceColor = Colors.white;
  static const Color _primaryBlue = Color(0xFF2F6DDE);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final FinanceService _financeService = const FinanceService();
  final PredictionService _predictionService = PredictionService();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final BudgetService _budgetService = BudgetService();
  final BudgetAlertService _budgetAlertService = BudgetAlertService();
  final CategoryService _categoryService = CategoryService();
  final OutletService _outletService = OutletService();
  final ReportService _reportService = ReportService();
  final ExportService _exportService = ExportService();
  final SyncService _syncService = SyncService();
  final ImportService _importService = ImportService();
  final AuditLogService _auditLogService = AuditLogService();
  final PeriodLockService _periodLockService = PeriodLockService();
  final ModelMonitoringService _modelMonitoringService =
      ModelMonitoringService();

  List<TransactionItem> _transactions = [];
  List<AuditLogItem> _auditLogs = [];
  List<ModelMonitoringItem> _modelMonitoringItems = [];
  List<String> _lockedPeriods = [];
  List<String> _expenseCategories = [...expenseCategories];
  List<Outlet> _outlets = const [
    Outlet(id: 'main', name: 'Hero Coffee - Main')
  ];

  bool _isLoading = true;
  bool _isSavingTransaction = false;
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  bool _isExportingModelHealth = false;
  bool _isImportingCsv = false;
  bool _isSyncingBackup = false;
  bool _isRetryingBackup = false;
  String? _errorMessage;
  int _selectedIndex = 0;
  int _pendingBackupCount = 0;
  TransactionType _selectedType = TransactionType.expense;
  TransactionType? _selectedFilterType;
  String _selectedCategory = expenseCategories.first;
  String _selectedOutletId = 'main';
  PredictionResult? _prediction;
  BudgetSettings _budgetSettings =
      const BudgetSettings(monthlyExpenseLimit: 20000000);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadTransactions(),
      _loadBudgetSettings(),
      _reloadPendingBackupCount(),
      _loadCategories(),
      _loadOutlets(),
      _loadAuditLogs(),
      _loadModelMonitoring(),
      _loadLockedPeriods(),
    ]);

    await _syncService.flushPendingQueue();
    await _reloadPendingBackupCount();
    await _logAction('open_app', 'Membuka dashboard keuangan');
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getCategories(expenseCategories);
    if (!mounted) {
      return;
    }

    setState(() {
      _expenseCategories = categories;
      if (!_expenseCategories.contains(_selectedCategory)) {
        _selectedCategory = _expenseCategories.first;
      }
    });
  }

  Future<void> _loadOutlets() async {
    final allOutlets = await _outletService.getOutlets();
    final outlets = allOutlets
        .where((outlet) => widget.user.canAccessOutlet(outlet.id))
        .toList();
    final selected = await _outletService.getSelectedOutletId();
    if (!mounted) {
      return;
    }

    setState(() {
      _outlets = outlets.isEmpty ? allOutlets.take(1).toList() : outlets;
      _selectedOutletId =
          _outlets.any((o) => o.id == selected) ? selected : _outlets.first.id;
    });
  }

  Future<void> _reloadPendingBackupCount() async {
    final count = await _syncService.getPendingCount();
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingBackupCount = count;
    });
  }

  Future<void> _loadAuditLogs() async {
    if (!widget.user.canViewAuditLog) {
      if (!mounted) {
        return;
      }
      setState(() {
        _auditLogs = const [];
      });
      return;
    }

    final logs = await _auditLogService.getLogs();
    if (!mounted) {
      return;
    }
    setState(() {
      _auditLogs = logs;
    });
  }

  Future<void> _loadBudgetSettings() async {
    final settings = await _budgetService.getSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _budgetSettings = settings;
    });
  }

  Future<void> _loadLockedPeriods() async {
    final periods = await _periodLockService.getLockedPeriods();
    if (!mounted) {
      return;
    }
    setState(() {
      _lockedPeriods = periods;
    });
  }

  Future<void> _loadModelMonitoring() async {
    try {
      final items = await _modelMonitoringService.getItems();
      if (!mounted) {
        return;
      }
      setState(() {
        _modelMonitoringItems = items;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _modelMonitoringItems = const [];
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await _transactionRepository
          .getTransactions()
          .timeout(const Duration(seconds: 10));

      if (!mounted) {
        return;
      }

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      try {
        await _refreshPrediction();
        await _syncCurrentMonthActualMonitoring();
      } catch (_) {
        // Fitur monitoring/prediksi tidak boleh menggagalkan load data utama.
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _refreshPrediction() async {
    final history =
        _financeService.buildHistory(monthlyExpenseHistory, _transactions);
    if (history.isEmpty) {
      return;
    }
    final prediction = await _predictionService.predictNextExpense(history);
    try {
      await _modelMonitoringService.upsertPrediction(
        period: prediction.targetPeriod,
        predictedExpense: prediction.predictedExpense,
        modelVersion: prediction.modelVersion,
      );
    } catch (_) {}

    if (!mounted) {
      return;
    }

    setState(() {
      _prediction = prediction;
    });
    try {
      await _loadModelMonitoring();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final selectedOutletTransactions = _transactions
        .where((item) => item.outletId == _selectedOutletId)
        .toList();
    final currentMonthTransactions =
        _financeService.filterToCurrentMonth(selectedOutletTransactions);
    final financeSummary =
        _financeService.calculateSummary(selectedOutletTransactions);
    final currentMonthSummary =
        _financeService.calculateSummary(currentMonthTransactions);
    final history = _financeService.buildHistory(
        monthlyExpenseHistory, selectedOutletTransactions);
    final prediction =
        _prediction ?? _predictionService.predictNextExpenseLocal(history);

    final overallBreakdown =
        _financeService.categoryBreakdown(selectedOutletTransactions);
    final dominantOverall = overallBreakdown.entries.isEmpty
        ? null
        : overallBreakdown.entries.reduce((a, b) => a.value >= b.value ? a : b);

    final filteredTransactions =
        _applyTransactionFilters(selectedOutletTransactions);
    final filteredBreakdown =
        _financeService.categoryBreakdown(filteredTransactions);
    final monthlyReports =
        _reportService.monthlyReports(selectedOutletTransactions);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : IndexedStack(
                    index: _selectedIndex,
                    children: [
                      HomeTab(
                        user: widget.user,
                        selectedOutletName: _selectedOutletName(),
                        currentMonthSummary: currentMonthSummary,
                        currentMonthTransactions: currentMonthTransactions,
                        allTimeSummary: financeSummary,
                        allTimeTransactions: selectedOutletTransactions,
                        onAddTransactionTap: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),
                      TransactionsTab(
                        transactions: filteredTransactions,
                        breakdown: filteredBreakdown,
                        titleController: _titleController,
                        amountController: _amountController,
                        searchController: _searchController,
                        expenseCategories: _expenseCategories,
                        selectedType: _selectedType,
                        selectedCategory: _selectedCategory,
                        selectedFilterType: _selectedFilterType,
                        selectedOutletName: _selectedOutletName(),
                        onTypeChanged: (type) {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                        onCategoryChanged: (category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        onFilterTypeChanged: (type) {
                          setState(() {
                            _selectedFilterType = type;
                          });
                        },
                        onSearchChanged: (_) {
                          setState(() {});
                        },
                        onManageCategories: _showManageCategoriesDialog,
                        onSave: _addTransaction,
                        onEdit: _editTransaction,
                        onDelete: _deleteTransaction,
                        canCreateTransaction: widget.user.canCreateTransaction,
                        canEditTransaction: widget.user.canEditTransaction,
                        canDeleteTransaction: widget.user.canDeleteTransaction,
                        canManageCategories: widget.user.canManageCategories,
                        isSavingTransaction: _isSavingTransaction,
                      ),
                      ChartTab(
                        financeSummary: financeSummary,
                        prediction: prediction,
                        dominantExpense: dominantOverall,
                        monthlyReports: monthlyReports,
                        monitoringItems: _modelMonitoringItems,
                        canViewFullPrediction:
                            widget.user.canViewFullPrediction,
                      ),
                      ProfileTab(
                        user: widget.user,
                        financeSummary: financeSummary,
                        transactionCount: selectedOutletTransactions.length,
                        budgetSettings: _budgetSettings,
                        monthlyReports: monthlyReports,
                        recentTransactions: selectedOutletTransactions,
                        auditLogs: _auditLogs,
                        outlets: _outlets,
                        selectedOutletId: _selectedOutletId,
                        onSelectOutlet: _selectOutlet,
                        onAddOutlet: _addOutlet,
                        onSaveBudget: _saveBudget,
                        onExportReport: _exportReport,
                        onExportPdf: _exportReportPdf,
                        onExportModelHealth: _exportModelHealthCsv,
                        onImportCsv: _importCsv,
                        onSyncBackup: _syncBackup,
                        onRetryPendingBackup: _retryPendingBackup,
                        onToggleCurrentMonthLock: _toggleCurrentMonthLock,
                        onLogout: _confirmLogout,
                        canEditBudget: widget.user.canEditBudget,
                        canExportReport: widget.user.canExportReport,
                        canSyncBackup: widget.user.canSyncBackup,
                        canManageOutlets: widget.user.canManageOutlets,
                        canViewAuditLog: widget.user.canViewAuditLog,
                        canLockPeriods: widget.user.canLockPeriods,
                        isCurrentMonthLocked:
                            _lockedPeriods.contains(_currentPeriod()),
                        lockedPeriods: _lockedPeriods,
                        pendingBackupCount: _pendingBackupCount,
                        isExportingCsv: _isExportingCsv,
                        isExportingPdf: _isExportingPdf,
                        isExportingModelHealth: _isExportingModelHealth,
                        isImportingCsv: _isImportingCsv,
                        isSyncingBackup: _isSyncingBackup,
                        isRetryingBackup: _isRetryingBackup,
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: _surfaceColor,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: const Color(0xFF6B7280),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Grafik'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  List<TransactionItem> _applyTransactionFilters(List<TransactionItem> items) {
    final query = _searchController.text.trim().toLowerCase();

    return items.where((item) {
      final matchesType =
          _selectedFilterType == null || item.type == _selectedFilterType;
      if (!matchesType) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();
  }

  String _selectedOutletName() {
    final match = _outlets.where((o) => o.id == _selectedOutletId);
    if (match.isEmpty) {
      return '-';
    }
    return match.first.name;
  }

  String _currentPeriod() {
    final now = DateTime.now();
    return _periodFromDateTime(now);
  }

  String _periodFromDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _periodFromTransaction(TransactionItem item) {
    final parsed = DateTime.tryParse(item.createdAt);
    return _periodFromDateTime(parsed ?? DateTime.now());
  }

  Future<bool> _isPeriodLocked(String period) async {
    if (_lockedPeriods.contains(period)) {
      return true;
    }
    return _periodLockService.isLocked(period);
  }

  Future<bool> _ensurePeriodEditable(String period) async {
    final locked = await _isPeriodLocked(period);
    if (!locked) {
      return true;
    }
    _showPermissionDenied(
      'Periode $period sudah dikunci Owner dan tidak bisa diubah.',
    );
    return false;
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Gagal memuat data lokal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan yang belum diketahui.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadTransactions,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTransaction() async {
    if (!widget.user.canCreateTransaction) {
      _showPermissionDenied('Role Anda tidak punya izin menambah transaksi.');
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty) {
      _showInfo('Nama transaksi wajib diisi.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showInfo('Nominal harus berupa angka lebih dari 0.');
      return;
    }

    final now = DateTime.now();
    final period = _periodFromDateTime(now);
    if (!await _ensurePeriodEditable(period)) {
      return;
    }

    final transaction = TransactionItem(
      id: 'trx-${now.millisecondsSinceEpoch}',
      title: title,
      category: _selectedType == TransactionType.income
          ? 'Penjualan'
          : _selectedCategory,
      amount: amount,
      type: _selectedType,
      date: DateFormat('dd MMMM yyyy', 'id_ID').format(now),
      createdAt: now.toIso8601String(),
      outletId: _selectedOutletId,
    );

    try {
      setState(() {
        _isSavingTransaction = true;
      });
      await _transactionRepository.insertTransaction(transaction);
      if (!mounted) {
        return;
      }

      setState(() {
        _transactions.insert(0, transaction);
        _titleController.clear();
        _amountController.clear();
        _selectedType = TransactionType.expense;
        _selectedCategory = _expenseCategories.first;
      });

      _showInfo('Transaksi berhasil disimpan.');
      try {
        await _refreshPrediction();
        await _checkBudgetWarning();
        await _syncCurrentMonthActualMonitoring();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Transaksi tersimpan, tetapi pembaruan analisis belum berhasil.',
              ),
            ),
          );
        }
      }
      await _logAction('create_transaction',
          'Menambah transaksi ${transaction.title} (${transaction.amount.toStringAsFixed(0)})');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTransaction = false;
        });
      }
    }
  }

  Future<void> _editTransaction(TransactionItem item) async {
    if (!widget.user.canEditTransaction) {
      _showPermissionDenied('Role Anda tidak punya izin edit transaksi.');
      return;
    }

    if (!await _ensurePeriodEditable(_periodFromTransaction(item))) {
      return;
    }
    if (!mounted) {
      return;
    }

    final titleController = TextEditingController(text: item.title);
    final amountController =
        TextEditingController(text: item.amount.toStringAsFixed(0));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                return;
              }
              final updated = item.copyWith(
                  title: titleController.text.trim(), amount: amount);
              if (!await _ensurePeriodEditable(
                  _periodFromTransaction(updated))) {
                return;
              }
              await _transactionRepository.updateTransaction(updated);
              if (!mounted) {
                return;
              }
              setState(() {
                final index = _transactions.indexWhere((t) => t.id == item.id);
                if (index != -1) {
                  _transactions[index] = updated;
                }
              });
              await _refreshPrediction();
              await _syncCurrentMonthActualMonitoring();
              await _logAction(
                'edit_transaction',
                'Edit transaksi ${item.title} ${item.amount.toStringAsFixed(0)} menjadi ${updated.title} ${updated.amount.toStringAsFixed(0)}',
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    if (!widget.user.canDeleteTransaction) {
      _showPermissionDenied('Hanya Owner yang bisa menghapus transaksi.');
      return;
    }

    TransactionItem? transaction;
    for (final item in _transactions) {
      if (item.id == id) {
        transaction = item;
        break;
      }
    }

    if (transaction != null &&
        !await _ensurePeriodEditable(_periodFromTransaction(transaction))) {
      return;
    }
    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Transaksi'),
            content: const Text('Yakin ingin menghapus transaksi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await _transactionRepository.deleteTransaction(id);
    if (!mounted) {
      return;
    }

    setState(() {
      _transactions.removeWhere((item) => item.id == id);
    });

    await _refreshPrediction();
    await _syncCurrentMonthActualMonitoring();
    await _logAction(
      'delete_transaction',
      'Hapus transaksi ${transaction?.title ?? id}',
    );

    if (!mounted || transaction == null) {
      return;
    }
    final deletedTransaction = transaction;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaksi ${deletedTransaction.title} dihapus'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            if (!await _ensurePeriodEditable(
                _periodFromTransaction(deletedTransaction))) {
              return;
            }
            await _transactionRepository.insertTransaction(deletedTransaction);
            if (!mounted) {
              return;
            }
            setState(() {
              _transactions.insert(0, deletedTransaction);
            });
            await _refreshPrediction();
            await _syncCurrentMonthActualMonitoring();
            await _logAction(
              'undo_delete_transaction',
              'Restore transaksi ${deletedTransaction.title}',
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveBudget(double value) async {
    if (!widget.user.canEditBudget) {
      _showPermissionDenied('Hanya Owner yang bisa mengubah budget.');
      return;
    }

    await _budgetService.saveMonthlyLimit(value);
    await _loadBudgetSettings();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget berhasil disimpan')),
    );
    await _logAction('set_budget', 'Mengubah budget ke $value');
  }

  Future<void> _exportReport() async {
    if (!widget.user.canExportReport) {
      _showPermissionDenied('Role Anda tidak punya izin export laporan.');
      return;
    }

    setState(() => _isExportingCsv = true);
    try {
      final reports = _reportService.monthlyReports(
        _transactions
            .where((item) => item.outletId == _selectedOutletId)
            .toList(),
      );
      final path = await _exportService.exportMonthlyReportsCsv(reports);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan CSV diexport ke: $path')),
      );
      await _logAction('export_csv', 'Export CSV laporan bulanan');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export CSV: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingCsv = false);
      }
    }
  }

  Future<void> _exportReportPdf() async {
    if (!widget.user.canExportReport) {
      _showPermissionDenied('Role Anda tidak punya izin export laporan.');
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      final reports = _reportService.monthlyReports(
        _transactions
            .where((item) => item.outletId == _selectedOutletId)
            .toList(),
      );
      final path = await _exportService.exportMonthlyReportsPdf(reports);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Laporan PDF berhasil dibuat.'),
          action: SnackBarAction(
            label: 'Bagikan',
            onPressed: () {
              Share.shareXFiles(
                [XFile(path)],
                text: 'Laporan Bulanan Hero Coffee',
              );
            },
          ),
        ),
      );
      await _logAction('export_pdf', 'Export PDF laporan bulanan');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _exportModelHealthCsv() async {
    if (!widget.user.canExportReport) {
      _showPermissionDenied('Role Anda tidak punya izin export laporan.');
      return;
    }

    setState(() => _isExportingModelHealth = true);
    try {
      final path =
          await _exportService.exportModelHealthCsv(_modelMonitoringItems);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan kesehatan model diexport ke: $path')),
      );
      await _logAction('export_model_health_csv', 'Export CSV kesehatan model');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export kesehatan model: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingModelHealth = false);
      }
    }
  }

  Future<void> _importCsv() async {
    if (!widget.user.canCreateTransaction) {
      _showPermissionDenied('Role Anda tidak punya izin import transaksi.');
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import CSV'),
            content: const Text(
                'Import akan menambahkan transaksi baru dari file CSV. Lanjutkan?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lanjut'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _isImportingCsv = true);
    try {
      final items =
          await _importService.pickAndParseCsv(outletId: _selectedOutletId);
      if (items.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data CSV yang diimport')),
        );
        return;
      }

      for (final item in items) {
        if (!await _ensurePeriodEditable(_periodFromTransaction(item))) {
          return;
        }
      }

      for (final item in items) {
        await _transactionRepository.insertTransaction(item);
      }

      await _loadTransactions();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Import CSV berhasil: ${items.length} transaksi')),
      );
      await _logAction(
          'import_csv', 'Import ${items.length} transaksi dari CSV');
    } finally {
      if (mounted) {
        setState(() => _isImportingCsv = false);
      }
    }
  }

  Future<void> _syncBackup() async {
    if (!widget.user.canSyncBackup) {
      _showPermissionDenied('Hanya Owner yang bisa menjalankan backup cloud.');
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Backup Cloud'),
            content: const Text(
                'Backup akan mengirim data transaksi saat ini ke cloud. Lanjutkan?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lanjut'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _isSyncingBackup = true);
    try {
      final result = await _syncService.backupWithQueue(_transactions);
      await _reloadPendingBackupCount();
      if (!mounted) {
        return;
      }

      final message = result.allDelivered
          ? 'Backup cloud berhasil (${result.sent} transaksi terkirim)'
          : 'Backup pending: ${result.queued} transaksi antre. ${result.message ?? 'Akan dicoba lagi.'}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _logAction('backup_cloud', message);
    } finally {
      if (mounted) {
        setState(() => _isSyncingBackup = false);
      }
    }
  }

  Future<void> _retryPendingBackup() async {
    if (!widget.user.canSyncBackup) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kirim Ulang Backup'),
            content: const Text(
                'Aplikasi akan mencoba mengirim ulang antrean backup yang tertunda. Lanjutkan?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lanjut'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _isRetryingBackup = true);
    try {
      final result = await _syncService.flushPendingQueue();
      await _reloadPendingBackupCount();
      if (!mounted) {
        return;
      }

      final message = result.queued == 0
          ? 'Semua antrean backup berhasil dikirim.'
          : 'Masih ada ${result.queued} transaksi pending backup. ${result.message ?? 'Akan dicoba lagi.'}';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await _logAction('retry_backup', message);
    } finally {
      if (mounted) {
        setState(() => _isRetryingBackup = false);
      }
    }
  }

  Future<void> _selectOutlet(String id) async {
    if (!widget.user.canAccessOutlet(id)) {
      _showPermissionDenied(
          'Admin hanya bisa mengakses outlet yang ditugaskan.');
      return;
    }

    await _outletService.setSelectedOutletId(id);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedOutletId = id;
    });
    await _logAction('select_outlet', 'Pilih outlet $id');
  }

  Future<void> _addOutlet() async {
    if (!widget.user.canManageOutlets) {
      _showPermissionDenied('Hanya Owner yang bisa menambah outlet.');
      return;
    }

    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Outlet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama outlet'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                return;
              }
              await _outletService.addOutlet(name);
              await _loadOutlets();
              if (context.mounted) {
                Navigator.pop(context);
              }
              await _logAction('add_outlet', 'Tambah outlet $name');
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showManageCategoriesDialog() async {
    if (!widget.user.canManageCategories) {
      _showPermissionDenied('Hanya Owner yang bisa mengelola kategori.');
      return;
    }

    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kelola Kategori'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration:
                            const InputDecoration(hintText: 'Kategori baru'),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Tambah kategori',
                      child: Tooltip(
                        message: 'Tambah kategori',
                        child: IconButton(
                          onPressed: () {
                            final value = controller.text.trim();
                            if (value.isEmpty) {
                              return;
                            }
                            if (!_expenseCategories.contains(value)) {
                              setState(() {
                                _expenseCategories.add(value);
                              });
                              setDialogState(() {});
                            }
                            controller.clear();
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: _expenseCategories.length,
                    itemBuilder: (context, index) {
                      final item = _expenseCategories[index];
                      final isDefault = expenseCategories.contains(item);
                      return ListTile(
                        dense: true,
                        title: Text(item),
                        trailing: isDefault
                            ? const Icon(Icons.lock_outline, size: 16)
                            : Semantics(
                                button: true,
                                label: 'Hapus kategori $item',
                                child: Tooltip(
                                  message: 'Hapus kategori',
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      setState(() {
                                        _expenseCategories.removeAt(index);
                                        if (!_expenseCategories
                                            .contains(_selectedCategory)) {
                                          _selectedCategory =
                                              _expenseCategories.first;
                                        }
                                      });
                                      setDialogState(() {});
                                    },
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            FilledButton(
              onPressed: () async {
                await _categoryService.saveCategories(
                  _expenseCategories,
                  expenseCategories,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
                await _logAction(
                    'manage_category', 'Memperbarui kategori custom');
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkBudgetWarning() async {
    final selectedOutletTransactions = _transactions
        .where((item) => item.outletId == _selectedOutletId)
        .toList();
    final currentMonthTransactions =
        _financeService.filterToCurrentMonth(selectedOutletTransactions);
    final totalExpense =
        _financeService.calculateSummary(currentMonthTransactions).totalExpense;

    await _budgetAlertService.resetIfBelowThreshold(
      totalExpense: totalExpense,
      limit: _budgetSettings.monthlyExpenseLimit,
    );

    final level = await _budgetAlertService.checkAndGetNewLevel(
      totalExpense: totalExpense,
      limit: _budgetSettings.monthlyExpenseLimit,
    );

    if (level == 0 || !mounted) {
      return;
    }

    final message = level >= 100
        ? 'Peringatan: pengeluaran melewati batas budget bulanan'
        : 'Alert budget: pengeluaran sudah $level% dari limit bulanan';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    await _logAction('budget_alert', message);
  }

  Future<void> _syncCurrentMonthActualMonitoring() async {
    final selectedOutletTransactions = _transactions
        .where((item) => item.outletId == _selectedOutletId)
        .toList();
    final currentMonthTransactions =
        _financeService.filterToCurrentMonth(selectedOutletTransactions);
    final currentMonthExpense =
        _financeService.calculateSummary(currentMonthTransactions).totalExpense;
    final now = DateTime.now();
    final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await _modelMonitoringService.upsertActual(
      period: period,
      actualExpense: currentMonthExpense,
      modelVersion: PredictionService.modelVersion,
    );
    try {
      await _loadModelMonitoring();
    } catch (_) {}
  }

  Future<void> _logAction(String action, String details) async {
    final item = AuditLogItem(
      action: action,
      actor: widget.user.username,
      timestamp: DateTime.now().toIso8601String(),
      details: details,
    );
    await _auditLogService.addLog(item);
    await _loadAuditLogs();
  }

  Future<void> _toggleCurrentMonthLock() async {
    if (!widget.user.canLockPeriods) {
      _showPermissionDenied('Hanya Owner yang bisa mengunci periode.');
      return;
    }

    final period = _currentPeriod();
    final willLock = !_lockedPeriods.contains(period);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(willLock ? 'Kunci Periode' : 'Buka Kunci Periode'),
            content: Text(
              willLock
                  ? 'Transaksi periode $period tidak bisa diedit atau dihapus setelah dikunci. Lanjutkan?'
                  : 'Periode $period akan bisa diedit kembali. Lanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(willLock ? 'Kunci' : 'Buka'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await _periodLockService.setLocked(period, willLock);
    await _loadLockedPeriods();
    await _logAction(
      willLock ? 'lock_period' : 'unlock_period',
      '${willLock ? 'Mengunci' : 'Membuka kunci'} periode $period',
    );
    _showInfo(
        willLock ? 'Periode $period dikunci.' : 'Periode $period dibuka.');
  }

  void _showPermissionDenied(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showInfo(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmLogout() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Anda yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }
    widget.onLogout();
  }
}
