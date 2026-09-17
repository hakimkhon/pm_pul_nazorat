import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 2)
class BudgetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String categoryId;

  @HiveField(2)
  double monthlyLimit;

  @HiveField(3)
  String? lastAlertMonth; // masalan "2026-09" — shu oyda qaysi darajada ogohlantirilganini bilish uchun

  @HiveField(4)
  int lastAlertLevel; // 0 = yo'q, 1 = 80%, 2 = 100%+

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
    this.lastAlertMonth,
    this.lastAlertLevel = 0,
  });
}