import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/budget_repository.dart';
import '../models/budget_model.dart';
import 'transaction_provider.dart';

final budgetRepositoryProvider = Provider((ref) => BudgetRepository());

class BudgetNotifier extends StateNotifier<List<BudgetModel>> {
  final BudgetRepository _repo;
  BudgetNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> setBudget(String categoryId, double limit) async {
    await _repo.setBudget(categoryId, limit);
    refresh();
  }

  Future<void> removeBudget(String categoryId) async {
    await _repo.deleteBudget(categoryId);
    refresh();
  }

  double? limitFor(String categoryId) {
    try {
      return state.firstWhere((b) => b.categoryId == categoryId).monthlyLimit;
    } catch (_) {
      return null;
    }
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, List<BudgetModel>>((ref) {
  return BudgetNotifier(ref.read(budgetRepositoryProvider));
});

/// Joriy oy uchun har bir bo'lim bo'yicha sarflangan summa: {categoryId: summa}
final monthlySpentByCategoryProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final now = DateTime.now();
  final map = <String, double>{};
  for (var t in transactions) {
    if (t.type != 'expense') continue;
    if (t.date.year == now.year && t.date.month == now.month) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
  }
  return map;
});