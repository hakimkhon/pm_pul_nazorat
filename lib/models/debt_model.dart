import 'package:hive/hive.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 5)
class DebtPaymentModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? note;

  DebtPaymentModel({required this.id, required this.amount, required this.date, this.note});
}

@HiveType(typeId: 4)
class DebtModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String personName;

  @HiveField(2)
  String type; // 'lent' (men berdim) | 'borrowed' (men oldim)

  @HiveField(3)
  double totalAmount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  String? note;

  @HiveField(7)
  List<DebtPaymentModel> payments;

  @HiveField(8)
  bool remindedOverdue;

  DebtModel({
    required this.id,
    required this.personName,
    required this.type,
    required this.totalAmount,
    required this.date,
    this.dueDate,
    this.note,
    List<DebtPaymentModel>? payments,
    this.remindedOverdue = false,
  }) : payments = payments ?? [];

  double get paidAmount => payments.fold(0.0, (s, p) => s + p.amount);
  double get remainingAmount => totalAmount - paidAmount;
  bool get isSettled => remainingAmount <= 0;
  bool get isOverdue => !isSettled && dueDate != null && dueDate!.isBefore(DateTime.now());
}