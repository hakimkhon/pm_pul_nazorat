import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/notification_service.dart';
import '../../data/notification_history.dart';

/// Har bir bo'lim byudjetini tekshirib, 80% yoki 100%+ ga yetganda
/// (va shu oyda hali ogohlantirilmagan bo'lsa) bildirishnoma yuboradi.
Future<void> checkBudgetAlerts(WidgetRef ref) async {
  final alertsEnabled = ref.read(budgetAlertsEnabledProvider);
  final budgets = ref.read(budgetProvider);
  final spentMap = ref.read(monthlySpentByCategoryProvider);
  final categories = ref.read(categoryProvider);
  final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  for (var budget in budgets) {
    if (budget.monthlyLimit <= 0) continue;
    final spent = spentMap[budget.categoryId] ?? 0;
    final percent = (spent / budget.monthlyLimit) * 100;

    int newLevel = 0;
    if (percent >= 100) {
      newLevel = 2;
    } else if (percent >= 80) {
      newLevel = 1;
    }

    final sameMonth = budget.lastAlertMonth == currentMonth;

    if (!sameMonth) {
      // Yangi oy boshlangan — hisobni tozalaymiz
      budget.lastAlertMonth = currentMonth;
      budget.lastAlertLevel = 0;
      await budget.save();
    }

    final alreadyAlerted = budget.lastAlertMonth == currentMonth && budget.lastAlertLevel >= newLevel;

    if (newLevel > 0 && !alreadyAlerted && alertsEnabled) {
      final categoryName = categories
          .firstWhere((c) => c.id == budget.categoryId, orElse: () => categories.first)
          .name;
      await NotificationService.showBudgetAlert(categoryName, percent);
      await NotificationHistory.add(
        'Byudjet ogohlantirishi',
        '"$categoryName" bo\'limida byudjetning ${percent.toStringAsFixed(0)}% sarflandi',
      );
      budget.lastAlertMonth = currentMonth;
      budget.lastAlertLevel = newLevel;
      await budget.save();
    }
  }

  ref.read(budgetProvider.notifier).refresh();
}