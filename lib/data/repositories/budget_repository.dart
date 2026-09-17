import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../models/budget_model.dart';
import '../hive_service.dart';

class BudgetRepository {
  Box<BudgetModel> get _box => Hive.box<BudgetModel>(HiveService.budgetBox);

  List<BudgetModel> getAll() => _box.values.toList();

  BudgetModel? getByCategory(String categoryId) {
    try {
      return _box.values.firstWhere((b) => b.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }

  Future<void> setBudget(String categoryId, double limit) async {
    final existing = getByCategory(categoryId);
    if (existing != null) {
      existing.monthlyLimit = limit;
      await existing.save();
    } else {
      final budget = BudgetModel(id: const Uuid().v4(), categoryId: categoryId, monthlyLimit: limit);
      await _box.put(budget.id, budget);
    }
  }

  Future<void> deleteBudget(String categoryId) async {
    final existing = getByCategory(categoryId);
    if (existing != null) await existing.delete();
  }
}