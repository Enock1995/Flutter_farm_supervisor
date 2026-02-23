// lib/screens/finances/finance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import 'add_transaction_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() =>
      _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context
            .read<FinanceProvider>()
            .loadTransactions(user.userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Farm Finances'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Transactions'),
            Tab(text: 'Report'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddTransactionScreen()),
        ),
        backgroundColor: AppColors.info,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add',
            style: AppTextStyles.button),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SummaryTab(),
          _TransactionsTab(),
          _ReportTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1 — SUMMARY
// =============================================================================
class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final profit = provider.netProfit;
        final isProfitable = profit >= 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main P&L card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isProfitable
                        ? [
                            AppColors.success,
                            AppColors.success
                                .withOpacity(0.7)
                          ]
                        : [
                            AppColors.error,
                            AppColors.error.withOpacity(0.7)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      isProfitable
                          ? '✅ Profitable Season'
                          : '⚠️ Running at a Loss',
                      style: AppTextStyles.body.copyWith(
                          color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Net: \$${profit.abs().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      isProfitable ? 'Profit' : 'Loss',
                      style: AppTextStyles.heading3
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _FinanceStat(
                          icon: '📈',
                          label: 'Income',
                          value:
                              '\$${provider.totalIncome.toStringAsFixed(2)}',
                          color: Colors.white,
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.white30),
                        _FinanceStat(
                          icon: '📉',
                          label: 'Expenses',
                          value:
                              '\$${provider.totalExpenses.toStringAsFixed(2)}',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (provider.transactions.isEmpty) ...[
                _EmptyFinanceState(),
              ] else ...[
                // Expense breakdown
                if (provider.expensesByCategory.isNotEmpty) ...[
                  Text('Expenses by Category',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  ...provider.expensesByCategory.entries
                      .take(6)
                      .map((e) => _CategoryBar(
                            label: e.key,
                            amount: e.value,
                            total:
                                provider.totalExpenses,
                            color: AppColors.error,
                          )),
                  const SizedBox(height: 20),
                ],

                // Income breakdown
                if (provider.incomeByCategory.isNotEmpty) ...[
                  Text('Income by Category',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  ...provider.incomeByCategory.entries
                      .take(6)
                      .map((e) => _CategoryBar(
                            label: e.key,
                            amount: e.value,
                            total: provider.totalIncome,
                            color: AppColors.success,
                          )),
                ],
              ],
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _FinanceStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.heading3
                .copyWith(color: color)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: color.withOpacity(0.7))),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  const _CategoryBar(
      {required this.label,
      required this.amount,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(
                            fontWeight:
                                FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)} (${(pct * 100).toInt()}%)',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor:
                  color.withOpacity(0.1),
              valueColor:
                  AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFinanceState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('💰',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No Transactions Yet',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to record income or expenses.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 2 — TRANSACTIONS LIST
// =============================================================================
class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator());
        }

        if (provider.transactions.isEmpty) {
          return _EmptyFinanceState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.transactions.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final tx = provider.transactions[i];
            return _TransactionTile(
              tx: tx,
              onDelete: () =>
                  _confirmDelete(context, tx, provider),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context,
      FinanceTransaction tx,
      FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transaction'),
        content: Text(
            'Delete "${tx.description}" (\$${tx.amount.toStringAsFixed(2)})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              provider.deleteTransaction(tx.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinanceTransaction tx;
  final VoidCallback onDelete;
  const _TransactionTile(
      {required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final color =
        isIncome ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(tx.description,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text(tx.category,
                          style: AppTextStyles.caption
                              .copyWith(color: color)),
                    ),
                    if (tx.cropOrAnimal != null) ...[
                      const SizedBox(width: 6),
                      Text('• ${tx.cropOrAnimal}',
                          style: AppTextStyles.caption),
                    ],
                  ],
                ),
                Text(_formatDate(tx.date),
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.textHint),
              ),
            ],
          ),
        ],
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

// =============================================================================
// TAB 3 — REPORT
// =============================================================================
class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        if (provider.transactions.isEmpty) {
          return _EmptyFinanceState();
        }

        // Build monthly summary for last 6 months
        final now = DateTime.now();
        final months = List.generate(6, (i) {
          final d = DateTime(now.year, now.month - i, 1);
          return d;
        }).reversed.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text('Season Report',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text(
                'Financial summary across all recorded transactions.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),

              // Overall totals
              Row(
                children: [
                  Expanded(
                    child: _ReportCard(
                      label: 'Total Income',
                      value:
                          '\$${provider.totalIncome.toStringAsFixed(2)}',
                      icon: '📈',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ReportCard(
                      label: 'Total Expenses',
                      value:
                          '\$${provider.totalExpenses.toStringAsFixed(2)}',
                      icon: '📉',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ReportCard(
                label: provider.netProfit >= 0
                    ? 'Net Profit'
                    : 'Net Loss',
                value:
                    '\$${provider.netProfit.abs().toStringAsFixed(2)}',
                icon: provider.netProfit >= 0
                    ? '✅'
                    : '⚠️',
                color: provider.netProfit >= 0
                    ? AppColors.success
                    : AppColors.error,
                large: true,
              ),

              const SizedBox(height: 20),

              // Monthly breakdown
              Text('Monthly Breakdown',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              ...months.map((monthDate) {
                final txs = provider.getByMonth(
                    monthDate.month, monthDate.year);
                final income = txs
                    .where((t) => t.isIncome)
                    .fold(0.0, (s, t) => s + t.amount);
                final expenses = txs
                    .where((t) => !t.isIncome)
                    .fold(0.0, (s, t) => s + t.amount);
                final net = income - expenses;
                final isNow =
                    monthDate.month == now.month &&
                        monthDate.year == now.year;

                return Container(
                  margin:
                      const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isNow
                        ? AppColors.primary
                            .withOpacity(0.05)
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: isNow
                          ? AppColors.primary
                              .withOpacity(0.3)
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          _monthLabel(monthDate),
                          style: AppTextStyles.body
                              .copyWith(
                            fontWeight: isNow
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isNow
                                ? AppColors.primary
                                : AppColors
                                    .textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceAround,
                          children: [
                            _MiniStat(
                              label: 'In',
                              value:
                                  '\$${income.toStringAsFixed(0)}',
                              color: AppColors.success,
                            ),
                            _MiniStat(
                              label: 'Out',
                              value:
                                  '\$${expenses.toStringAsFixed(0)}',
                              color: AppColors.error,
                            ),
                            _MiniStat(
                              label: 'Net',
                              value:
                                  '${net >= 0 ? '+' : '-'}\$${net.abs().toStringAsFixed(0)}',
                              color: net >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ],
                        ),
                      ),
                      Text('${txs.length} tx',
                          style: AppTextStyles.caption),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  String _monthLabel(DateTime d) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${names[d.month]}\n${d.year}';
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;
  final bool large;
  const _ReportCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(large ? 20 : 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withOpacity(0.25)),
      ),
      child: large
          ? Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(icon,
                    style:
                        const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        )),
                    Text(label,
                        style: AppTextStyles.body
                            .copyWith(color: color)),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(icon,
                    style:
                        const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    )),
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: color)),
              ],
            ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w700)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}