import 'package:hive/hive.dart';
import '../../models/category_model.dart';
import '../hive_service.dart';

class CategoryRepository {
  Box<CategoryModel> get _box => Hive.box<CategoryModel>(HiveService.categoryBox);

  List<CategoryModel> getAll() => _box.values.toList();

  List<CategoryModel> getByType(String type) =>
      _box.values.where((c) => c.type == type).toList();

  Future<void> add(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> update(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}