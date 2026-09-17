import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

final transactionRepositoryProvider = Provider((ref) => TransactionRepository());

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionRepository _repo;

  TransactionNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> addTransaction(TransactionModel transaction) async {
    await _repo.add(transaction);
    refresh();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repo.update(transaction);
    refresh();
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.delete(id);
    refresh();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  (ref) => TransactionNotifier(ref.read(transactionRepositoryProvider)),
);

// Balans va statistikalar uchun qulay provayderlar
final totalIncomeProvider = Provider<double>((ref) {
  final list = ref.watch(transactionProvider);
  return list.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  final list = ref.watch(transactionProvider);
  return list.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
});

final balanceProvider = Provider<double>((ref) {
  return ref.watch(totalIncomeProvider) - ref.watch(totalExpenseProvider);
});