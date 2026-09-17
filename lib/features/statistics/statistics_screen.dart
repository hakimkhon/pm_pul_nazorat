import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/utils/date_range_helper.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/theme/app_theme.dart';
import 'transaction_search_screen.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _viewType = 'expense'; // 'expense' yoki 'income'

  String _formatMoney(double v) => "${NumberFormat("#,##0").format(v)} so'm";

  @override
  Widget build(BuildContext context) {
    final periodType = ref.watch(selectedPeriodTypeProvider);
    final refDate = ref.watch(selectedReferenceDateProvider);
    final categories = ref.watch(categoryProvider);
    final breakdown = ref.watch(categoryBreakdownProvider(_viewType));
    final totalIncome = ref.watch(periodTotalIncomeProvider);
    final totalExpense = ref.watch(periodTotalExpenseProvider);

    final total = breakdown.values.fold(0.0, (a, b) => a + b);

    // Kategoriya bo'yicha tartiblangan ro'yxat (eng ko'p sarflanganidan boshlab)
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
          // Davr tanlash
          _PeriodSelector(),

          const SizedBox(height: 8),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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

          // Kirim/Chiqim umumiy karta
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Kirim',
                    value: totalIncome,
                    color: AppTheme.income,
                    icon: Icons.arrow_downward,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                Expanded(
                  child: _SummaryTile(
                    label: 'Chiqim',
                    value: totalExpense,
                    color: AppTheme.expense,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Kirim/Chiqim toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleTab(
                    label: 'Chiqimlar',
                    selected: _viewType == 'expense',
                    onTap: () => setState(() => _viewType = 'expense'),
                  ),
                ),
                Expanded(
                  child: _ToggleTab(
                    label: 'Kirimlar',
                    selected: _viewType == 'income',
                    onTap: () => setState(() => _viewType = 'income'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (breakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: Text("Bu davrda ma'lumot yo'q")),
            )
          else ...[
            // Doiraviy diagramma
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    _formatMoney(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bo'limlar bo'yicha ro'yxat
            const Text(
              "Bo'limlar bo'yicha",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...sortedEntries.map((entry) {
              final cat = categories.firstWhere(
                (c) => c.id == entry.key,
                orElse: () => categories.first,
              );
              final percent = total == 0 ? 0 : (entry.value / total * 100);
              final color = Color(cat.colorValue);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : entry.value / total,
                              minHeight: 6,
                              backgroundColor: color.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatMoney(entry.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${percent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPeriodTypeProvider);

    final options = {
      PeriodType.daily: 'Kunlik',
      PeriodType.weekly: 'Haftalik',
      PeriodType.monthly: 'Oylik',
      PeriodType.yearly: 'Yillik',
    };

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.entries.map((entry) {
          final isSelected = entry.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) {
                ref.read(selectedPeriodTypeProvider.notifier).state = entry.key;
                ref.read(selectedReferenceDateProvider.notifier).state =
                    DateTime.now();
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
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
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "${NumberFormat.compact().format(value)} so'm",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppTheme.primary : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
