import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../recurring/recurring_screen.dart';
import '../notifications/notifications_screen.dart';

const List<String> uzMonths = [
  'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).subtract(const Duration(seconds: 1));

    final monthIncome = transactions
        .where((t) => t.type == 'income' && t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month)
        .fold(0.0, (s, t) => s + t.amount);
    final monthExpense = transactions
        .where((t) => t.type == 'expense' && t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month)
        .fold(0.0, (s, t) => s + t.amount);
    final carryover = transactions.where((t) => !t.date.isAfter(monthEnd)).fold(
          0.0, (s, t) => s + (t.type == 'income' ? t.amount : -t.amount),
        );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.brandPrimary(context),
          onRefresh: () async => ref.read(transactionProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(),
              const SizedBox(height: 20),
              _BalanceCard(
                selectedMonth: _selectedMonth,
                carryover: carryover,
                monthIncome: monthIncome,
                monthExpense: monthExpense,
                onPickMonth: () => _pickMonth(context),
              ),
              const SizedBox(height: 20),
              SectionTitle(
                "So'nggi tranzaksiyalar",
                trailing: transactions.isNotEmpty ? Text('${transactions.length} ta', style: Theme.of(context).textTheme.labelSmall) : null,
              ),
              const SizedBox(height: 4),
              if (transactions.isEmpty)
                const EmptyState(icon: Icons.receipt_long_rounded, title: "Hozircha tranzaksiya yo'q", subtitle: "Pastdagi + tugmasi orqali qo'shing")
              else
                ...List.generate(transactions.take(10).length, (index) {
                  final t = transactions[index];
                  final cat = categories.firstWhere((c) => c.id == t.categoryId, orElse: () => categories.first);
                  return FadeInItem(index: index, child: TransactionTile(transaction: t, category: cat, showCategoryAsSubtitle: true));
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _pickMonth(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge))),
      builder: (_) {
        final now = DateTime.now();
        final months = List.generate(12, (i) => DateTime(now.year, now.month - i, 1));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oyni tanlang', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: months.map((m) {
                    final selected = m.year == _selectedMonth.year && m.month == _selectedMonth.month;
                    return ChoiceChip(
                      label: Text('${uzMonths[m.month - 1]} ${m.year}'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedMonth = DateTime(m.year, m.month, 1));
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xush kelibsiz', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text('PulNazorat', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        Row(
          children: [
            _HeaderIcon(icon: Icons.notifications_none_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            const SizedBox(width: 10),
            _HeaderIcon(icon: Icons.autorenew_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecurringScreen()))),
          ],
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.softShadow(opacity: 0.05)),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final DateTime selectedMonth;
  final double carryover;
  final double monthIncome;
  final double monthExpense;
  final VoidCallback onPickMonth;

  const _BalanceCard({
    required this.selectedMonth, required this.carryover, required this.monthIncome, required this.monthExpense, required this.onPickMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.brandPrimary(context), AppTheme.brandPrimary(context).withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow(opacity: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Oy oxiriga qolgan mablag'", style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: onPickMonth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(uzMonths[selectedMonth.month - 1], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: carryover),
                builder: (context, v, _) => Text(NumberFormat('#,##0').format(v), style: Theme.of(context).textTheme.displayLarge),
              ),
              const SizedBox(width: 6),
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Text("so'm", style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15))),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Bu oy kirim', value: monthIncome, color: const Color(0xFF6FE3B4), icon: Icons.arrow_downward_rounded)),
              const SizedBox(width: 12),
              Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Bu oy chiqim', value: monthExpense, color: const Color(0xFFFFB199), icon: Icons.arrow_upward_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle), child: Icon(icon, size: 14, color: color)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
            Text(NumberFormat.compact().format(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}