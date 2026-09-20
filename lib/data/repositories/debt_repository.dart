import 'package:hive/hive.dart';
import '../../models/debt_model.dart';
import '../hive_service.dart';

class DebtRepository {
  Box<DebtModel> get _box => Hive.box<DebtModel>(HiveService.debtBox);

  List<DebtModel> getAll() => _box.values.toList();

  Future<void> add(DebtModel debt) async => await _box.put(debt.id, debt);

  Future<void> save(DebtModel debt) async => await debt.save();

  Future<void> delete(String id) async => await _box.delete(id);

  Future<void> addPayment(DebtModel debt, DebtPaymentModel payment) async {
    debt.payments.add(payment);
    await debt.save();
  }
}