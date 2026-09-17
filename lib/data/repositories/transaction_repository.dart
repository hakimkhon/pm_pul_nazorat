import 'package:hive/hive.dart';
import '../../models/transaction_model.dart';
import '../hive_service.dart';

class TransactionRepository {
  Box<TransactionModel> get _box =>
      Hive.box<TransactionModel>(HiveService.transactionBox);

  List<TransactionModel> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // eng yangisi tepada
    return list;
  }

  List<TransactionModel> getByDateRange(DateTime start, DateTime end) {
    return getAll()
        .where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                      t.date.isBefore(end.add(const Duration(seconds: 1))))
        .toList();
  }

  Future<void> add(TransactionModel transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> update(TransactionModel transaction) async {
    await _box.put(transaction.id, transaction);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  double totalByType(String type, {DateTime? start, DateTime? end}) {
    var items = getAll().where((t) => t.type == type);
    if (start != null && end != null) {
      items = items.where((t) => t.date.isAfter(start) && t.date.isBefore(end));
    }
    return items.fold(0.0, (sum, t) => sum + t.amount);
  }
}