import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import 'category_provider.dart';
import 'statistics_provider.dart';

class ProfitLossEntry {
  final String name;
  final double income;
  final double expense;
  const ProfitLossEntry({required this.name, required this.income, required this.expense});

  double get profit => income - expense;
  bool get isProfit => profit >= 0;
}

/// Bir xil nomli kirim va chiqim bo'limlarini avtomatik moslashtirib,
/// tanlangan davr uchun foyda/zarar hisoblaydi.
final profitLossProvider = Provider<List<ProfitLossEntry>>((ref) {
  final categories = ref.watch(categoryProvider);
  final transactions = ref.watch(filteredTransactionsProvider); // statistics_provider'dagi davr filtri

  final Map<String, List<CategoryModel>> byName = {};
  for (var c in categories) {
    final key = c.name.trim().toLowerCase();
    byName.putIfAbsent(key, () => []).add(c);
  }

  final result = <ProfitLossEntry>[];

  byName.forEach((key, cats) {
    final expenseCats = cats.where((c) => c.type == 'expense').toList();
    final incomeCats = cats.where((c) => c.type == 'income').toList();
    if (expenseCats.isEmpty || incomeCats.isEmpty) return; // faqat ikkalasi ham mavjud bo'lsa hisoblanadi

    final expenseIds = expenseCats.map((c) => c.id).toSet();
    final incomeIds = incomeCats.map((c) => c.id).toSet();

    final totalExpense = transactions.where((t) => t.type == 'expense' && expenseIds.contains(t.categoryId)).fold(0.0, (s, t) => s + t.amount);
    final totalIncome = transactions.where((t) => t.type == 'income' && incomeIds.contains(t.categoryId)).fold(0.0, (s, t) => s + t.amount);

    if (totalExpense == 0 && totalIncome == 0) return; // shu davrda faoliyat bo'lmagan bo'lsa ko'rsatmaymiz

    result.add(ProfitLossEntry(name: cats.first.name, income: totalIncome, expense: totalExpense));
  });

  result.sort((a, b) => b.profit.abs().compareTo(a.profit.abs()));
  return result;
});