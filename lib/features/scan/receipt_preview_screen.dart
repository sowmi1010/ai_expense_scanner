import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/expense_options.dart';
import '../../core/services/budget_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import 'receipt_preview_args.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({super.key});

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  final amount = TextEditingController();
  final merchant = TextEditingController();
  final date = TextEditingController();

  final _picker = ImagePicker();
  final _ocr = OcrService();
  final _repo = ExpenseRepository.instance;

  String category = ExpenseOptions.defaultCategory;
  String paymentMode = ExpenseOptions.defaultPaymentMode;

  String? _imagePath;
  bool _initDone = false;
  bool _scanning = false;
  bool _saving = false;
  String _rawText = '';

  // NEW: extracted payment method from OCR (example: "UPI, SuperCoins", "EMI")
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    date.text = _formatDate(DateTime.now());
  }

  @override
  void dispose() {
    amount.dispose();
    merchant.dispose();
    date.dispose();
    _ocr.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initDone) return;
    _initDone = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _imagePath = (args is ReceiptPreviewArgs) ? args.imagePath : null;

    if (_imagePath != null) {
      _runOcr();
    }
  }

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd-$mm-$yyyy';
  }

  Future<void> _pickFromGallery() async {
    if (_scanning || _saving) return;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (image == null || !mounted) return;

      setState(() {
        _imagePath = image.path;
        _rawText = '';
        _paymentMethod = null;
      });

      await _runOcr();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not import image: $e')));
    }
  }

  Future<void> _runOcr() async {
    if (_imagePath == null || _scanning) return;

    setState(() => _scanning = true);

    try {
      final parsed = await _ocr.scanReceiptFromImagePath(_imagePath!);

      _rawText = parsed.rawText;
      _paymentMethod = parsed.paymentMethod;

      if (parsed.totalAmount != null) {
        amount.text = parsed.totalAmount!.toStringAsFixed(
          parsed.totalAmount! % 1 == 0 ? 0 : 2,
        );
      }
      if (parsed.merchant != null && parsed.merchant!.trim().isNotEmpty) {
        merchant.text = parsed.merchant!.trim();
      }
      if (parsed.date != null) {
        date.text = _formatDate(parsed.date!);
      }
      if (parsed.category != null &&
          ExpenseOptions.categories.contains(parsed.category)) {
        category = parsed.category!;
      }

      // Category improved: include merchant + payment method too
      final categoryFromFullText = ExpenseOptions.detectCategoryFromText(
        '${parsed.rawText}\n${merchant.text}\n${_paymentMethod ?? ''}',
      );
      if (ExpenseOptions.categories.contains(categoryFromFullText)) {
        category = categoryFromFullText;
      }

      // Payment mode improved: use both raw text + payment method line
      final paymentHint = [parsed.paymentMethod, parsed.rawText]
          .where((e) => e != null && e!.trim().isNotEmpty)
          .map((e) => e!.trim())
          .join('\n');

      paymentMode = ExpenseOptions.detectPaymentModeFromText(paymentHint);
      if (!ExpenseOptions.paymentModes.contains(paymentMode)) {
        paymentMode = ExpenseOptions.defaultPaymentMode;
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed, please enter manually: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  double? _parseAmount(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'(rs\.?|inr|\u20B9)'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final match = RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)').firstMatch(normalized);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  DateTime? _parseDate(String value) {
    final text = value.trim().toLowerCase();
    if (text.isEmpty || text == 'today') return DateTime.now();
    if (text == 'yesterday')
      return DateTime.now().subtract(const Duration(days: 1));

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

  DateTime _startOfMonth(DateTime now) => DateTime(now.year, now.month, 1);
  DateTime _startOfNextMonth(DateTime now) =>
      DateTime(now.year, now.month + 1, 1);

  Future<void> _checkBudgetAndNotify() async {
    final budget = await BudgetService.instance.getMonthlyBudget();
    if (budget <= 0) return;

    await BudgetService.instance.resetMonthIfNeeded();

    final now = DateTime.now();
    final spent = await _repo.sumByDateRange(
      _startOfMonth(now),
      _startOfNextMonth(now),
    );
    final percent = (spent / budget) * 100;

    if (percent >= 100) {
      final already = await BudgetService.instance.hasTriggered100ThisMonth();
      if (!already) {
        await BudgetService.instance.markTriggered100ThisMonth();
        final msg =
            'Budget exceeded: ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
        await NotificationService.instance.showBudgetAlert(
          title: 'Monthly budget exceeded',
          body: msg,
        );
      }
      return;
    }

    if (percent >= 80) {
      final already = await BudgetService.instance.hasTriggered80ThisMonth();
      if (!already) {
        await BudgetService.instance.markTriggered80ThisMonth();
        final msg =
            'You reached ${percent.toStringAsFixed(0)}%: ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
        await NotificationService.instance.showBudgetAlert(
          title: 'Budget warning (80%)',
          body: msg,
        );
      }
    }
  }

  Future<void> _saveExpense() async {
    if (_saving) return;

    final amt = _parseAmount(amount.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final parsedDate = _parseDate(date.text);
    if (parsedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter valid date (DD-MM-YYYY / today / yesterday)',
          ),
        ),
      );
      return;
    }

    final merch = merchant.text.trim().isEmpty
        ? 'Unknown'
        : merchant.text.trim();
    final now = DateTime.now();
    final createdAt = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    setState(() => _saving = true);

    try {
      final expense = ExpenseModel(
        amount: amt,
        merchant: merch,
        category: category,
        paymentMode: paymentMode,
        createdAt: createdAt,
        receiptImagePath: _imagePath,
        rawOcrText: _rawText.isEmpty ? null : _rawText,
      );

      await _repo.insertExpense(expense);
      await _checkBudgetAndNotify();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense saved')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review and Save'),
        actions: [
          IconButton(
            onPressed: (_scanning || _saving) ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library_rounded),
            tooltip: 'Pick image',
          ),
          IconButton(
            onPressed: (_scanning || _saving) ? null : _runOcr,
            icon: const Icon(Icons.auto_fix_high_rounded),
            tooltip: 'Auto-detect',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Glass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill image (optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePath == null
                        ? Container(
                            color: cs.surfaceContainerHighest.withValues(
                              alpha: 0.35,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'No bill image selected',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _pickFromGallery,
                                    icon: const Icon(
                                      Icons.photo_library_rounded,
                                    ),
                                    label: const Text('Import from gallery'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              Positioned.fill(
                                child: Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (_scanning)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 14),

                  // NEW: show detected payment method
                  if (_paymentMethod != null &&
                      _paymentMethod!.trim().isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.25,
                        ),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detected payment method',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _paymentMethod!,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),
                  Text(
                    'Expense details',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    label: 'Amount',
                    hintText: 'e.g. 450.50',
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Merchant',
                    hintText: 'Shop name',
                    controller: merchant,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Date',
                    hintText: 'DD-MM-YYYY or today/yesterday',
                    controller: date,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Category',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ExpenseOptions.categories
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item),
                            selected: category == item,
                            onSelected: (_) => setState(() => category = item),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment mode',
                    ),
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
                      setState(() => paymentMode = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'View OCR text',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          _rawText.isEmpty ? 'No OCR text yet.' : _rawText,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: (_saving || _scanning) ? null : _saveExpense,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save expense'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}
