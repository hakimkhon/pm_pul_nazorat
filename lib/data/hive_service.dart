import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/debt_model.dart';
import '../models/plan_model.dart';

class HiveService {
  static const String categoryBox = 'categories';
  static const String transactionBox = 'transactions';
  static const String budgetBox = 'budgets';
  static const String settingsBox = 'settings';
  static const String recurringBox = 'recurring';
  static const String debtBox = 'debts';
  static const String planBox = 'plans';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(RecurringTransactionModelAdapter());
    Hive.registerAdapter(DebtPaymentModelAdapter()); 
    Hive.registerAdapter(DebtModelAdapter());        
    Hive.registerAdapter(PlanModelAdapter());

    await Hive.openBox<CategoryModel>(categoryBox);
    await Hive.openBox<TransactionModel>(transactionBox);
    await Hive.openBox<BudgetModel>(budgetBox);
    await Hive.openBox<RecurringTransactionModel>(recurringBox);
    await Hive.openBox<DebtModel>(debtBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox<PlanModel>(planBox); 

    await _seedDefaultCategories();
  }

  // Dastur birinchi marta ochilganda standart bo'limlarni qo'shamiz
  static Future<void> _seedDefaultCategories() async {
    final box = Hive.box<CategoryModel>(categoryBox);
    if (box.isNotEmpty) return;

    final defaults = [
      CategoryModel(
        id: 'food',
        name: 'Oziq-ovqat',
        iconCode: 'restaurant',
        colorValue: 0xFFFF7043,
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel(
        id: 'transport',
        name: "Yo'l kira",
        iconCode: 'directions_bus',
        colorValue: 0xFF42A5F5,
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel(
        id: 'health',
        name: 'Dori-darmon',
        iconCode: 'local_hospital',
        colorValue: 0xFFEF5350,
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel(
        id: 'utilities',
        name: 'Kommunal',
        iconCode: 'bolt',
        colorValue: 0xFFFFCA28,
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel(
        id: 'entertainment',
        name: "Ko'ngilochar",
        iconCode: 'movie',
        colorValue: 0xFFAB47BC,
        type: 'expense',
        isDefault: true,
      ),
      CategoryModel(
        id: 'salary',
        name: 'Ish haqi',
        iconCode: 'work',
        colorValue: 0xFF66BB6A,
        type: 'income',
        isDefault: true,
      ),
      CategoryModel(
        id: 'other_income',
        name: 'Boshqa daromad',
        iconCode: 'attach_money',
        colorValue: 0xFF26A69A,
        type: 'income',
        isDefault: true,
      ),
    ];

    for (var cat in defaults) {
      await box.put(cat.id, cat);
    }
  }
}
