import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';

/// "Qarz-nasiya" nomli chiqim va kirim bo'limlari mavjudligini tekshiradi,
/// bo'lmasa avtomatik yaratadi. (expenseCategoryId, incomeCategoryId) qaytaradi.
Future<(String, String)> ensureDebtCategories(WidgetRef ref) async {
  final categories = ref.read(categoryProvider);

  CategoryModel? expenseCat;
  CategoryModel? incomeCat;
  try {
    expenseCat = categories.firstWhere((c) => c.type == 'expense' && c.name == 'Qarz-nasiya');
  } catch (_) {}
  try {
    incomeCat = categories.firstWhere((c) => c.type == 'income' && c.name == 'Qarz-nasiya');
  } catch (_) {}

  if (expenseCat == null) {
    expenseCat = CategoryModel(id: const Uuid().v4(), name: 'Qarz-nasiya', iconCode: 'volunteer_activism', colorValue: 0xFF8D6E63, type: 'expense', isDefault: true);
    await ref.read(categoryProvider.notifier).addCategory(expenseCat);
  }
  if (incomeCat == null) {
    incomeCat = CategoryModel(id: const Uuid().v4(), name: 'Qarz-nasiya', iconCode: 'volunteer_activism', colorValue: 0xFF8D6E63, type: 'income', isDefault: true);
    await ref.read(categoryProvider.notifier).addCategory(incomeCat);
  }

  return (expenseCat.id, incomeCat.id);
}