import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String categoryId;

  @HiveField(3)
  String type;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  String? source;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.date,
    this.note,
    this.source,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'categoryId': categoryId,
        'type': type,
        'date': date.toIso8601String(),
        'note': note,
        'source': source,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'],
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'],
        type: json['type'],
        date: DateTime.parse(json['date']),
        note: json['note'],
        source: json['source'],
      );
}