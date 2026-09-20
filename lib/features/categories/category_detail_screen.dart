import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/category_model.dart';
import '../add_transaction/add_transaction_screen.dart';
import '../home/home_screen.dart' show uzMonths;

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final CategoryModel category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  double _slideDir = 1;
  bool _showAll = false;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _goPrev() => setState(() { _slideDir = -1; _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1); });
  void _goNext() {
    if (_isCurrentMonth) return;
    setState(() { _slideDir = 1; _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1); });
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final color = Color(category.colorValue);
    final allItems = ref.watch(transactionProvider).where((t) => t.categoryId == category.id).toList();

    final monthItems = allItems.where((t) => t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month).toList();
    final displayedItems = _showAll ? allItems : monthItems;
    final displayedTotal = displayedItems.fold(0.0, (s, t) => s + t.amount);

    double? budgetLimit;
    try {
      budgetLimit = ref.watch(budgetProvider).firstWhere((b) => b.categoryId == category.id).monthlyLimit;
    } catch (_) {
      budgetLimit = null;
    }
    final monthSpent = monthItems.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    final budgetPercent = (budgetLimit != null && budgetLimit > 0) ? (monthSpent / budgetLimit * 100).clamp(0, 999) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Hero(tag: 'cat_icon_${category.id}', child: CategoryAvatar(category: category, radius: 20, iconSize: 20)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Oy stepper ----
          if (!_showAll)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 26), onPressed: _goPrev),
                  ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, animation) {
                        final offset = Tween<Offset>(begin: Offset(_slideDir * 0.4, 0), end: Offset.zero).animate(animation);
                        return SlideTransition(position: offset, child: FadeTransition(opacity: animation, child: child));
                      },
                      child: Text(
                        '${uzMonths[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                        key: ValueKey('${_selectedMonth.year}-${_selectedMonth.month}'),
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right_rounded, size: 26), onPressed: _isCurrentMonth ? null : _goNext),
                ],
              ),
            ),

          // ---- 3 ustunli xulosa: Jami: | summa | soni ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              tint: color,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Jami:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('${NumberFormat("#,##0").format(displayedTotal)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: color)),
                    ),
                  ),
                  Expanded(
                    child: Text('${displayedItems.length} ta', textAlign: TextAlign.end, style: Theme.of(context).textTheme.labelSmall),
                  ),
                ],
              ),
            ),
          ),

          if (budgetPercent != null && !_showAll) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Oylik byudjet', style: Theme.of(context).textTheme.labelSmall),
                        Text('${budgetPercent.toStringAsFixed(0)}% / ${NumberFormat.compact().format(budgetLimit)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: budgetPercent >= 100 ? AppTheme.brandExpense(context) : (budgetPercent >= 80 ? AppTheme.brandGold(context) : AppTheme.brandIncome(context)))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (budgetPercent / 100).clamp(0, 1).toDouble(),
                        minHeight: 6,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(budgetPercent >= 100 ? AppTheme.brandExpense(context) : (budgetPercent >= 80 ? AppTheme.brandGold(context) : AppTheme.brandIncome(context))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Checkbox(value: _showAll, onChanged: (v) => setState(() => _showAll = v ?? false)),
                Text('Barchasini ko\'rish (barcha vaqt)', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),

          Expanded(
            child: displayedItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: EmptyState(icon: Icons.inbox_outlined, title: _showAll ? "Bu bo'limda hali tranzaksiya yo'q" : "Bu oyda tranzaksiya yo'q"),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: displayedItems.length,
                    itemBuilder: (context, index) => FadeInItem(
                      index: index,
                      child: TransactionTile(
                        transaction: displayedItems[index],
                        category: category,
                        onEdit: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: displayedItems[index]))),
                        onDelete: () => _confirmDelete(context, ref, displayedItems[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("O'chirish"),
        content: const Text("Bu tranzaksiyani o'chirmoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(transactionProvider.notifier).deleteTransaction(transaction.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Tranzaksiya o'chirildi"),
                  action: SnackBarAction(label: 'BEKOR QILISH', onPressed: () => ref.read(transactionProvider.notifier).addTransaction(transaction)),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: Text("O'chirish", style: TextStyle(color: AppTheme.brandExpense(context))),
          ),
        ],
      ),
    );
  }
}