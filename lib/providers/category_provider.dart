import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/category_repository.dart';
import '../models/category_model.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  final CategoryRepository _repo;

  CategoryNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> addCategory(CategoryModel category) async {
    await _repo.add(category);
    refresh();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _repo.update(category);
    refresh();
  }

  Future<void> deleteCategory(String id) async {
    await _repo.delete(id);
    refresh();
  }

  List<CategoryModel> byType(String type) =>
      state.where((c) => c.type == type).toList();
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryModel>>(
  (ref) => CategoryNotifier(ref.read(categoryRepositoryProvider)),
);