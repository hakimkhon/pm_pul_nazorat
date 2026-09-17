import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/recurring_repository.dart';
import '../models/recurring_transaction_model.dart';

final recurringRepositoryProvider = Provider((ref) => RecurringRepository());

class RecurringNotifier extends StateNotifier<List<RecurringTransactionModel>> {
  final RecurringRepository _repo;
  RecurringNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> add(RecurringTransactionModel model) async {
    await _repo.add(model);
    refresh();
  }

  Future<void> toggleActive(RecurringTransactionModel model, bool value) async {
    model.isActive = value;
    await _repo.update(model);
    refresh();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    refresh();
  }
}

final recurringProvider = StateNotifierProvider<RecurringNotifier, List<RecurringTransactionModel>>((ref) {
  return RecurringNotifier(ref.read(recurringRepositoryProvider));
});