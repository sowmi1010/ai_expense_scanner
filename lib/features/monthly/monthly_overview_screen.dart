import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/expense_options.dart';
import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

class MonthlyOverviewScreen extends StatefulWidget {
  const MonthlyOverviewScreen({super.key});

  @override
  State<MonthlyOverviewScreen> createState() => _MonthlyOverviewScreenState();
}

class _MonthlyOverviewScreenState extends State<MonthlyOverviewScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ExpenseRepository.instance;
  final _moneyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  final _monthLabelFormatter = DateFormat('MMMM yyyy');
  final _expenseDateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

  late final TabController _tabController;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _loading = true;
  List<CategoryTotal> _categoryTotals = const [];
  List<ExpenseModel> _expenses = const [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _repo.changes.addListener(_load);
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_load);
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _nextMonthStart => DateTime(_month.year, _month.month + 1, 1);

  bool get _canGoNextMonth {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    return _month.isBefore(currentMonth);
  }

  String _money(double value) => _moneyFormatter.format(value);
  String _formatDate(DateTime value) => DateFormat('dd-MM-yyyy').format(value);

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final raw = await _repo.getCategoryTotals(_month, _nextMonthStart);
      final expenses = await _repo.getExpensesInRange(_month, _nextMonthStart);

      final totalsByCategory = <String, double>{};
      for (final item in raw) {
        totalsByCategory[item.category] =
            (totalsByCategory[item.category] ?? 0) + item.total;
      }

      final rows = <CategoryTotal>[];
      for (final name in ExpenseOptions.categories) {
        rows.add(CategoryTotal(category: name, total: totalsByCategory[name] ?? 0));
      }

      final extras = totalsByCategory.keys
          .where((name) => !ExpenseOptions.categories.contains(name))
          .toList()
        ..sort(
          (a, b) =>
              (totalsByCategory[b] ?? 0).compareTo(totalsByCategory[a] ?? 0),
        );

      for (final name in extras) {
        rows.add(CategoryTotal(category: name, total: totalsByCategory[name] ?? 0));
      }

      final total = rows.fold<double>(0, (sum, e) => sum + e.total);

      if (!mounted) return;
      setState(() {
        _categoryTotals = rows;
        _expenses = expenses;
        _total = total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
    _load();
  }

  DateTime? _parseDate(String value) {
    final text = value.trim().toLowerCase();
    if (text.isEmpty || text == 'today') return DateTime.now();
    if (text == 'yesterday') return DateTime.now().subtract(const Duration(days: 1));

    final dmy = RegExp(r'^(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2,4})$');
    final ymd = RegExp(r'^(\d{4})[\/\.\-](\d{1,2})[\/\.\-](\d{1,2})$');

    final m1 = dmy.firstMatch(text);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!);
      final month = int.tryParse(m1.group(2)!);
      var year = int.tryParse(m1.group(3)!);
      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    }

    final m2 = ymd.firstMatch(text);
    if (m2 != null) {
      final year = int.tryParse(m2.group(1)!);
      final month = int.tryParse(m2.group(2)!);
      final day = int.tryParse(m2.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _editExpense(ExpenseModel expense) async {
    final amountController = TextEditingController(
      text: expense.amount % 1 == 0
          ? expense.amount.toStringAsFixed(0)
          : expense.amount.toStringAsFixed(2),
    );
    final merchantController = TextEditingController(text: expense.merchant);
    final dateController = TextEditingController(text: _formatDate(expense.createdAt));

    var selectedCategory = expense.category;
    if (!ExpenseOptions.categories.contains(selectedCategory)) {
      selectedCategory = ExpenseOptions.defaultCategory;
    }

    var selectedPaymentMode = expense.paymentMode;
    if (!ExpenseOptions.paymentModes.contains(selectedPaymentMode)) {
      selectedPaymentMode = ExpenseOptions.defaultPaymentMode;
    }

    final updatedExpense = await showDialog<ExpenseModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Edit expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: merchantController,
                      decoration: const InputDecoration(labelText: 'Merchant'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date (DD-MM-YYYY)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ExpenseOptions.categories
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setLocalState(() => selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPaymentMode,
                      decoration: const InputDecoration(labelText: 'Payment mode'),
                      items: ExpenseOptions.paymentModes
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setLocalState(() => selectedPaymentMode = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsedAmount = double.tryParse(
                      amountController.text.trim().replaceAll(',', ''),
                    );
                    if (parsedAmount == null || parsedAmount <= 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }

                    final parsedDate = _parseDate(dateController.text);
                    if (parsedDate == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid date')),
                      );
                      return;
                    }

                    final merchantName = merchantController.text.trim().isEmpty
                        ? 'Unknown'
                        : merchantController.text.trim();
                    final original = expense.createdAt;
                    final editedDate = DateTime(
                      parsedDate.year,
                      parsedDate.month,
                      parsedDate.day,
                      original.hour,
                      original.minute,
                      original.second,
                      original.millisecond,
                      original.microsecond,
                    );

                    Navigator.of(dialogContext).pop(
                      ExpenseModel(
                        id: expense.id,
                        amount: parsedAmount,
                        merchant: merchantName,
                        category: selectedCategory,
                        paymentMode: selectedPaymentMode,
                        createdAt: editedDate,
                        receiptImagePath: expense.receiptImagePath,
                        rawOcrText: expense.rawOcrText,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    merchantController.dispose();
    dateController.dispose();

    if (updatedExpense == null) return;

    try {
      await _repo.updateExpense(updatedExpense);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final id = expense.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete expense'),
          content: Text('Delete "${expense.merchant}" (${_money(expense.amount)})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repo.deleteExpense(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildSummaryTab() {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Glass(
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'By category',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),
                    ..._categoryTotals.map((item) {
                      final pct = _total <= 0 ? 0.0 : item.total / _total;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.category} =',
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  _money(item.total),
                                  style: TextStyle(
                                    color: item.total > 0
                                        ? cs.onSurface
                                        : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.45,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  item.total > 0 ? cs.primary : cs.outlineVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: const [
          SizedBox(height: 70),
          Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      );
    }

    if (_expenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Glass(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 28,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No expenses found for this month.',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: _expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = _expenses[index];
        return Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.merchant,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money(item.amount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editExpense(item);
                      } else if (value == 'delete') {
                        _deleteExpense(item);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _expenseDateFormatter.format(item.createdAt),
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(label: item.category),
                  _Tag(label: item.paymentMode),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthLabel = _monthLabelFormatter.format(_month);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track category insights and detailed expense history.',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Glass(
                  emphasize: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                            tooltip: 'Previous month',
                          ),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_note_rounded,
                                    size: 18,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    monthLabel,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _canGoNextMonth ? () => _changeMonth(1) : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                            tooltip: 'Next month',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricPill(
                            label: 'Total spend',
                            value: _money(_total),
                            icon: Icons.payments_rounded,
                          ),
                          _MetricPill(
                            label: 'Expenses',
                            value: '${_expenses.length}',
                            icon: Icons.receipt_long_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surface.withValues(alpha: 0.72),
                        cs.surfaceContainerHighest.withValues(alpha: 0.54),
                      ],
                    ),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.30),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'Expenses'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: _buildSummaryTab(),
                ),
                RefreshIndicator(
                  onRefresh: _load,
                  child: _buildExpensesTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 138),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surface.withValues(alpha: 0.55),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: cs.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
