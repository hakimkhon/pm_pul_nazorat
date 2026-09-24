import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../core/utils/date_range_helper.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../providers/profit_loss_provider.dart';
import '../categories/category_detail_screen.dart';
import 'transaction_search_screen.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _viewType = 'expense';
  String _mainTab = 'overview'; // 'overview' | 'profitLoss'

  @override
  Widget build(BuildContext context) {
    final periodType = ref.watch(selectedPeriodTypeProvider);
    final refDate = ref.watch(selectedReferenceDateProvider);
    final categories = ref.watch(categoryProvider);
    final breakdown = ref.watch(categoryBreakdownProvider(_viewType));
    final totalIncome = ref.watch(periodTotalIncomeProvider);
    final totalExpense = ref.watch(periodTotalExpenseProvider);
    final budgets = ref.watch(budgetProvider);

    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistika'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Tranzaksiya qidirish',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionSearchScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EqualSegmentedBar<String>(
            options: const {
              'Umumiy statistika': 'overview',
              'Foyda-zarar tahlili': 'profitLoss',
            },
            selected: _mainTab,
            onSelect: (v) => setState(() => _mainTab = v),
          ),
          const SizedBox(height: 16),

          EqualSegmentedBar<PeriodType>(
            options: const {
              'Kunlik': PeriodType.daily,
              'Haftalik': PeriodType.weekly,
              'Oylik': PeriodType.monthly,
              'Yillik': PeriodType.yearly,
            },
            selected: periodType,
            onSelect: (t) {
              ref.read(selectedPeriodTypeProvider.notifier).state = t;
              ref.read(selectedReferenceDateProvider.notifier).state =
                  DateTime.now();
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    ref.read(selectedReferenceDateProvider.notifier).state =
                        DateRangeHelper.shift(periodType, refDate, -1),
              ),
              Text(
                DateRangeHelper.label(periodType, refDate),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    ref.read(selectedReferenceDateProvider.notifier).state =
                        DateRangeHelper.shift(periodType, refDate, 1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_mainTab == 'profitLoss')
            _ProfitLossView(
              periodLabel: DateRangeHelper.label(periodType, refDate),
            )
          else ...[
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Kirim',
                      value: totalIncome,
                      color: AppTheme.brandIncome(context),
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Chiqim',
                      value: totalExpense,
                      color: AppTheme.brandExpense(context),
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            EqualSegmentedBar<String>(
              options: const {'Chiqimlar': 'expense', 'Kirimlar': 'income'},
              selected: _viewType,
              onSelect: (v) => setState(() => _viewType = v),
            ),
            const SizedBox(height: 20),

            if (breakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: EmptyState(
                  icon: Icons.pie_chart_outline_rounded,
                  title: "Bu davrda ma'lumot yo'q",
                ),
              )
            else ...[
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    sections: sortedEntries.map((entry) {
                      final cat = categories.firstWhere(
                        (c) => c.id == entry.key,
                        orElse: () => categories.first,
                      );
                      final percent = total == 0
                          ? 0
                          : (entry.value / total * 100);
                      return PieChartSectionData(
                        value: entry.value,
                        color: Color(cat.colorValue),
                        title: '${percent.toStringAsFixed(0)}%',
                        radius: 42,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Text(
                      _viewType == 'expense' ? 'Jami chiqim' : 'Jami kirim',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '${NumberFormat("#,##0").format(total)} so\'m',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Bo'limlar bo'yicha",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...sortedEntries.map((entry) {
                final cat = categories.firstWhere(
                  (c) => c.id == entry.key,
                  orElse: () => categories.first,
                );
                final percent = total == 0 ? 0 : (entry.value / total * 100);
                final color = Color(cat.colorValue);

                double? budgetLimit;
                try {
                  budgetLimit = budgets
                      .firstWhere((b) => b.categoryId == cat.id)
                      .monthlyLimit;
                } catch (_) {
                  budgetLimit = null;
                }

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(category: cat),
                    ),
                  ),
                  child: AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    tint: color,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(
                            IconHelper.getIcon(cat.iconCode),
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: total == 0 ? 0 : entry.value / total,
                                  minHeight: 6,
                                  backgroundColor: color.withValues(
                                    alpha: 0.15,
                                  ),
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                              if (budgetLimit != null &&
                                  _viewType == 'expense') ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Byudjet: ${NumberFormat.compact().format(budgetLimit)} so\'m',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              NumberFormat("#,##0").format(entry.value),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${percent.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProfitLossView extends ConsumerWidget {
  final String periodLabel;
  const _ProfitLossView({required this.periodLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(profitLossProvider);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyState(
          icon: Icons.compare_arrows_rounded,
          title: "Mos keluvchi faoliyat topilmadi",
          subtitle:
              "Bir xil nomdagi kirim VA chiqim bo'limi bo'lsa (masalan ikkalasida ham \"Dehqonchilik\"), shu yerda avtomatik solishtiriladi.",
        ),
      );
    }

    final totalProfit = entries.fold(0.0, (s, e) => s + e.profit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          tint: totalProfit >= 0
              ? AppTheme.brandIncome(context)
              : AppTheme.brandExpense(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$periodLabel — umumiy natija',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${totalProfit >= 0 ? '+' : ''}${NumberFormat("#,##0").format(totalProfit)} so\'m',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: totalProfit >= 0
                      ? AppTheme.brandIncome(context)
                      : AppTheme.brandExpense(context),
                ),
              ),
              Text(
                totalProfit >= 0 ? 'Umumiy foyda' : 'Umumiy zarar',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Faoliyatlar bo'yicha",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ...entries.map((e) {
          final color = e.isProfit
              ? AppTheme.brandIncome(context)
              : AppTheme.brandExpense(context);
          final total = e.income + e.expense;
          final incomeRatio = total == 0 ? 0.5 : e.income / total;

          return AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            tint: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${e.isProfit ? '+' : ''}${NumberFormat("#,##0").format(e.profit)} so\'m',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (incomeRatio * 100).round().clamp(1, 99),
                        child: Container(
                          height: 8,
                          color: AppTheme.brandIncome(context),
                        ),
                      ),
                      Expanded(
                        flex: (100 - (incomeRatio * 100).round()).clamp(1, 99),
                        child: Container(
                          height: 8,
                          color: AppTheme.brandExpense(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kirim: ${NumberFormat.compact().format(e.income)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.brandIncome(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Chiqim: ${NumberFormat.compact().format(e.expense)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.brandExpense(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${NumberFormat.compact().format(value)} so\'m',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: color,
          ),
        ),
      ],
    );
  }
}
