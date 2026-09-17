import 'package:hive/hive.dart';

part 'recurring_transaction_model.g.dart';

@HiveType(typeId: 3)
class RecurringTransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String categoryId;

  @HiveField(3)
  String type; // 'income' yoki 'expense'

  @HiveField(4)
  String frequency; // 'daily', 'weekly', 'monthly'

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  DateTime lastGeneratedDate;

  @HiveField(7)
  String? note;

  @HiveField(8)
  String? source;

  @HiveField(9)
  bool isActive;

  RecurringTransactionModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.lastGeneratedDate,
    this.note,
    this.source,
    this.isActive = true,
  });
}