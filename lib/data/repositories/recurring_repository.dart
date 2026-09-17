import 'package:hive/hive.dart';
import '../../models/recurring_transaction_model.dart';
import '../hive_service.dart';

class RecurringRepository {
  Box<RecurringTransactionModel> get _box =>
      Hive.box<RecurringTransactionModel>(HiveService.recurringBox);

  List<RecurringTransactionModel> getAll() => _box.values.toList();

  Future<void> add(RecurringTransactionModel model) async =>
      await _box.put(model.id, model);

  Future<void> update(RecurringTransactionModel model) async =>
      await model.save();

  Future<void> delete(String id) async => await _box.delete(id);
}
