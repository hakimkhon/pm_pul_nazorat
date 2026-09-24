import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/debt_repository.dart';
import '../models/debt_model.dart';

final debtRepositoryProvider = Provider((ref) => DebtRepository());

class DebtNotifier extends StateNotifier<List<DebtModel>> {
  final DebtRepository _repo;
  DebtNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> add(DebtModel debt) async {
    await _repo.add(debt);
    refresh();
  }

  Future<void> update(DebtModel debt) async {
    await _repo.save(debt);
    refresh();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    refresh();
  }

  Future<void> addPayment(DebtModel debt, double amount, {String? note, String? transactionId}) async {
    final payment = DebtPaymentModel(id: const Uuid().v4(), amount: amount, date: DateTime.now(), note: note, transactionId: transactionId);
    await _repo.addPayment(debt, payment);
    refresh();
  }
}

final debtProvider = StateNotifierProvider<DebtNotifier, List<DebtModel>>((ref) {
  return DebtNotifier(ref.read(debtRepositoryProvider));
});

/// Menga qarzdor bo'lganlarning jami qoldiq summasi (men berganlarim, hali qaytmagan)
final totalOwedToMeProvider = Provider<double>((ref) {
  return ref.watch(debtProvider).where((d) => d.type == 'lent' && !d.isSettled).fold(0.0, (s, d) => s + d.remainingAmount);
});

/// Mening to'lashim kerak bo'lgan jami summa (men olganlarim, hali to'lamaganim)
final totalIOweProvider = Provider<double>((ref) {
  return ref.watch(debtProvider).where((d) => d.type == 'borrowed' && !d.isSettled).fold(0.0, (s, d) => s + d.remainingAmount);
});