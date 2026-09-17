import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/theme/app_theme.dart';

class TransactionSearchScreen extends ConsumerStatefulWidget {
  const TransactionSearchScreen({super.key});

  @override
  ConsumerState<TransactionSearchScreen> createState() => _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends ConsumerState<TransactionSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);

    String categoryName(String id) =>
        categories.firstWhere((c) => c.id == id, orElse: () => categories.first).name;

    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? <dynamic>[]
        : allTransactions.where((t) {
            final source = (t.source ?? '').toLowerCase();
            final note = (t.note ?? '').toLowerCase();
            final catName = categoryName(t.categoryId).toLowerCase();
            return source.contains(q) || note.contains(q) || catName.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Qidirish... (masalan: non, taksi, dorixona)',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _controller.clear();
                _query = '';
              }),
            ),
        ],
      ),
      body: q.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, size: 48, color: AppTheme.mutedText(context)),
                    const SizedBox(height: 12),
                    Text(
                      'Bo\'lim, izoh yoki manba nomi bo\'yicha qidiring',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Text('"$q" bo\'yicha hech narsa topilmadi', style: Theme.of(context).textTheme.bodyMedium),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final t = results[index];
                    final cat = categories.firstWhere((c) => c.id == t.categoryId, orElse: () => categories.first);
                    final color = Color(cat.colorValue);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.14),
                            child: Icon(IconHelper.getIcon(cat.iconCode), color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.source ?? cat.name, style: Theme.of(context).textTheme.titleMedium),
                                if (t.note != null && t.note!.isNotEmpty)
                                  Text(t.note!, style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  '${cat.name} • ${DateFormat('dd.MM.yyyy HH:mm').format(t.date)}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${t.type == 'income' ? '+' : '-'}${NumberFormat("#,##0").format(t.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: t.type == 'income' ? AppTheme.brandIncome(context) : AppTheme.brandExpense(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}