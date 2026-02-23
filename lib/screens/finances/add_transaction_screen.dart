// lib/screens/finances/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/primary_button.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  String? _category;
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _cropController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  List<String> get _categories =>
      _type == TransactionType.income
          ? FinanceProvider.incomeCategories
          : FinanceProvider.expenseCategories;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _cropController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: AppColors.info)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_descController.text.trim().isEmpty) {
      _showError('Please enter a description.');
      return;
    }
    if (_category == null) {
      _showError('Please select a category.');
      return;
    }
    final amount =
        double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context.read<FinanceProvider>().addTransaction(
          userId: user.userId,
          type: _type,
          category: _category!,
          description: _descController.text.trim(),
          amount: amount,
          date: _date,
          cropOrAnimal:
              _cropController.text.trim().isEmpty
                  ? null
                  : _cropController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_type == TransactionType.income
            ? 'Income recorded!'
            : 'Expense recorded!'),
        backgroundColor: _type == TransactionType.income
            ? AppColors.success
            : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == TransactionType.income;
    final accentColor =
        isIncome ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income / Expense toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = TransactionType.income;
                        _category = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        decoration: BoxDecoration(
                          color: isIncome
                              ? AppColors.success
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward,
                                color: isIncome
                                    ? Colors.white
                                    : AppColors.success,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Income',
                              style: AppTextStyles.body
                                  .copyWith(
                                color: isIncome
                                    ? Colors.white
                                    : AppColors.success,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = TransactionType.expense;
                        _category = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        decoration: BoxDecoration(
                          color: !isIncome
                              ? AppColors.error
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward,
                                color: !isIncome
                                    ? Colors.white
                                    : AppColors.error,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Expense',
                              style: AppTextStyles.body
                                  .copyWith(
                                color: !isIncome
                                    ? Colors.white
                                    : AppColors.error,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text('Category', style: AppTextStyles.heading3),
            const SizedBox(height: 10),

            // Category chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _category == cat;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? accentColor
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? accentColor
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(cat,
                        style: AppTextStyles.body.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Text('Details', style: AppTextStyles.heading3),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descController,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description *',
                hintText:
                    'e.g. Sold 200kg maize to GMB',
                prefixIcon: const Icon(Icons.edit,
                    color: AppColors.info),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (USD) *',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money,
                    color: AppColors.info),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.info),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Date',
                            style: AppTextStyles.label),
                        Text(_formatDate(_date),
                            style: AppTextStyles.body),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Crop/Animal link
            TextFormField(
              controller: _cropController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Crop or Animal (optional)',
                hintText:
                    'e.g. Maize, Beef Cattle, Tomatoes',
                prefixIcon: const Icon(Icons.eco,
                    color: AppColors.info),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: const Icon(Icons.notes,
                    color: AppColors.info),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 32),

            Consumer<FinanceProvider>(
              builder: (ctx, provider, _) =>
                  PrimaryButton(
                label: isIncome
                    ? 'Record Income'
                    : 'Record Expense',
                icon: isIncome
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                isLoading: provider.isLoading,
                onPressed: _save,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}