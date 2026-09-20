import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/debt_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../widgets/shared_widgets.dart';

class DebtDetailScreen extends ConsumerWidget {
  final String debtId;
  const DebtDetailScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtProvider);
    final debt = debts.firstWhere((d) => d.id == debtId);
    final color = debt.isSettled ? AppTheme.mutedText(context) : (debt.isOverdue ? AppTheme.brandExpense(context) : AppTheme.brandPrimary(context));
    final progress = debt.totalAmount == 0 ? 0.0 : (debt.paidAmount / debt.totalAmount).clamp(0, 1).toDouble();
    final payments = List.of(debt.payments)..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.personName),
        actions: [
          IconButton(icon: Icon(Icons.delete_outline, color: AppTheme.brandExpense(context)), onPressed: () => _confirmDelete(context, ref)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            tint: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(debt.type == 'lent' ? Icons.call_made_rounded : Icons.call_received_rounded, color: color),
                    const SizedBox(width: 8),
                    Text(debt.type == 'lent' ? 'Siz berdingiz' : 'Siz oldingiz', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (debt.isSettled)
                      Text("To'landi ✓", style: TextStyle(color: AppTheme.brandIncome(context), fontWeight: FontWeight.w700))
                    else if (debt.isOverdue)
                      Text("Muddati o'tgan", style: TextStyle(color: AppTheme.brandExpense(context), fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jami summa', style: Theme.of(context).textTheme.labelSmall),
                          Text('${NumberFormat("#,##0").format(debt.totalAmount)} so\'m', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Qoldiq', style: Theme.of(context).textTheme.labelSmall),
                          Text('${NumberFormat("#,##0").format(debt.remainingAmount)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: color.withValues(alpha: 0.12), valueColor: AlwaysStoppedAnimation(color))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.mutedText(context)),
                    const SizedBox(width: 6),
                    Text('Sana: ${DateFormat('dd.MM.yyyy').format(debt.date)}', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                if (debt.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_outlined, size: 14, color: AppTheme.mutedText(context)),
                      const SizedBox(width: 6),
                      Text('Muddat: ${DateFormat('dd.MM.yyyy').format(debt.dueDate!)}', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ],
                if (debt.note != null && debt.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(debt.note!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!debt.isSettled)
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showAddPaymentDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text("To'lov qo'shish"),
              ),
            ),
          const SizedBox(height: 20),
          Text("To'lovlar tarixi", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (payments.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Hali to\'lov qilinmagan', style: Theme.of(context).textTheme.labelSmall)))
          else
            ...payments.map((p) => AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 16, backgroundColor: AppTheme.brandIncome(context).withValues(alpha: 0.14), child: Icon(Icons.check, size: 16, color: AppTheme.brandIncome(context))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${NumberFormat("#,##0").format(p.amount)} so\'m', style: Theme.of(context).textTheme.titleMedium),
                            if (p.note != null && p.note!.isNotEmpty) Text(p.note!, style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                      Text(DateFormat('dd.MM.yyyy').format(p.date), style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, WidgetRef ref) {
    final debt = ref.read(debtProvider).firstWhere((d) => d.id == debtId);
    final controller = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("To'lov qo'shish"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller, keyboardType: TextInputType.number, inputFormatters: [ThousandsFormatter()], autofocus: true,
              decoration: InputDecoration(labelText: 'Summa', suffixText: "so'm", helperText: 'Qoldiq: ${NumberFormat("#,##0").format(debt.remainingAmount)} so\'m'),
            ),
            const SizedBox(height: 8),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              final amount = ThousandsFormatter.parse(controller.text);
              if (amount == null || amount <= 0) return;
              ref.read(debtProvider.notifier).addPayment(debt, amount, note: noteController.text.trim().isEmpty ? null : noteController.text.trim());
              Navigator.pop(dialogContext);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("O'chirish"),
        content: const Text('Bu qarz yozuvini butunlay o\'chirmoqchimisiz? (To\'lovlar tarixi ham o\'chadi)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              ref.read(debtProvider.notifier).remove(debtId);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text("O'chirish", style: TextStyle(color: AppTheme.brandExpense(context))),
          ),
        ],
      ),
    );
  }
}