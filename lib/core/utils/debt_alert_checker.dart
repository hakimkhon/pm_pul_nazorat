import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/debt_provider.dart';
import '../../data/notification_service.dart';
import '../../data/notification_history.dart';

/// Muddati o'tgan, hali yopilmagan qarzlarni tekshirib, har biri uchun
/// FAQAT BIR MARTA (remindedOverdue orqali) bildirishnoma yuboradi.
Future<void> checkDebtOverdueAlerts(WidgetRef ref) async {
  final debts = ref.read(debtProvider);
  bool anyChange = false;

  for (var debt in debts) {
    if (debt.isSettled || debt.dueDate == null) continue;
    if (!debt.dueDate!.isBefore(DateTime.now())) continue; // hali muddati o'tmagan
    if (debt.remindedOverdue) continue; // avval ogohlantirilgan

    final amountText = NumberFormat("#,##0").format(debt.remainingAmount);
    await NotificationService.showDebtOverdueAlert(debt.personName, debt.type, amountText);
    await NotificationHistory.add(
      "Qarz muddati o'tdi",
      debt.type == 'lent'
          ? '${debt.personName} sizga $amountText so\'m qaytarishi kerak edi'
          : '${debt.personName} ga $amountText so\'m to\'lashingiz kerak edi',
    );

    debt.remindedOverdue = true;
    await debt.save();
    anyChange = true;
  }

  if (anyChange) ref.read(debtProvider.notifier).refresh();
}