import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_range_helper.dart';
import 'transaction_provider.dart';

final selectedPeriodTypeProvider = StateProvider<PeriodType>((ref) => PeriodType.monthly);
final selectedReferenceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Tanlangan davrdagi tranzaksiyalar
final filteredTransactionsProvider = Provider((ref) {
  final all = ref.watch(transactionProvider);
  final type = ref.watch(selectedPeriodTypeProvider);
  final refDate = ref.watch(selectedReferenceDateProvider);

  final start = DateRangeHelper.startOf(type, refDate);
  final end = DateRangeHelper.endOf(type, refDate);

  return all.where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                          t.date.isBefore(end.add(const Duration(seconds: 1)))).toList();
});

// Bo'lim bo'yicha jamlangan chiqim/kirim: {categoryId: summa}
final categoryBreakdownProvider = Provider.family<Map<String, double>, String>((ref, type) {
  final transactions = ref.watch(filteredTransactionsProvider).where((t) => t.type == type);
  final map = <String, double>{};
  for (var t in transactions) {
    map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
  }
  return map;
});

final periodTotalIncomeProvider = Provider((ref) {
  return ref.watch(filteredTransactionsProvider)
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);
});

final periodTotalExpenseProvider = Provider((ref) {
  return ref.watch(filteredTransactionsProvider)
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);
});