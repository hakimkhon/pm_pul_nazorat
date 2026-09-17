import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 0)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconCode;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  String type;

  @HiveField(5)
  bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCode': iconCode,
        'colorValue': colorValue,
        'type': type,
        'isDefault': isDefault,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'],
        name: json['name'],
        iconCode: json['iconCode'],
        colorValue: json['colorValue'],
        type: json['type'],
        isDefault: json['isDefault'] ?? false,
      );
}