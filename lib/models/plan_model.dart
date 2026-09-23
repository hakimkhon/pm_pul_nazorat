import 'package:hive/hive.dart';

part 'plan_model.g.dart';

@HiveType(typeId: 6)
class PlanModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? note;

  @HiveField(3)
  String periodType; // 'daily' | 'weekly' | 'monthly'

  @HiveField(4)
  DateTime date; // reja tegishli sana (kunlik/haftalik/oylik boshlanishi)

  @HiveField(5)
  String status; // 'pending' | 'inProgress' | 'done' | 'notDone'

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? reminderTime;

  PlanModel({
    required this.id,
    required this.title,
    this.note,
    required this.periodType,
    required this.date,
    this.status = 'pending',
    required this.createdAt,
    this.reminderTime,
  });
}