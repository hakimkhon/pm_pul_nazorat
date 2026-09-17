import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/category_model.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final CategoryModel category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTransactions = ref.watch(transactionProvider);
    final items = allTransactions.where((t) => t.categoryId == category.id).toList();
    final color = Color(category.colorValue);
    final total = items.fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Column(
        children: [
          AppCard(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            tint: color,
            child: Row(
              children: [
                CategoryAvatar(category: category, radius: 20, iconSize: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jami (barcha vaqt)', style: Theme.of(context).textTheme.labelSmall),
                    Text('${NumberFormat("#,##0").format(total)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
                  ],
                ),
                const Spacer(),
                Text('${items.length} ta', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(icon: Icons.inbox_outlined, title: "Bu bo'limda hali tranzaksiya yo'q")
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) => FadeInItem(
                      index: index,
                      child: TransactionTile(transaction: items[index], category: category),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}