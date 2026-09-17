import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_provider.dart';

/// Har bir faol takrorlanuvchi qoidani tekshirib, o'tkazib yuborilgan
/// barcha davrlar uchun haqiqiy tranzaksiyalarni avtomatik yaratadi.
/// Dastur ochilganda bir marta chaqiriladi.
Future<void> generateDueRecurringTransactions(WidgetRef ref) async {
  final recurrences = ref.read(recurringProvider);
  final now = DateTime.now();
  bool anyChange = false;

  for (var r in recurrences) {
    if (!r.isActive) continue;

    DateTime cursor = _nextDate(r.lastGeneratedDate, r.frequency);

    while (!cursor.isAfter(now)) {
      final tx = TransactionModel(
        id: const Uuid().v4(),
        amount: r.amount,
        categoryId: r.categoryId,
        type: r.type,
        date: cursor,
        note: r.note,
        source: r.source ?? 'Avtomatik (takrorlanuvchi)',
      );
      await ref.read(transactionProvider.notifier).addTransaction(tx);
      r.lastGeneratedDate = cursor;
      anyChange = true;
      cursor = _nextDate(cursor, r.frequency);
    }

    if (anyChange) await r.save();
  }

  if (anyChange) {
    ref.read(recurringProvider.notifier).refresh();
  }
}

DateTime _nextDate(DateTime from, String frequency) {
  switch (frequency) {
    case 'daily':
      return from.add(const Duration(days: 1));
    case 'weekly':
      return from.add(const Duration(days: 7));
    case 'monthly':
    default:
      final nextMonth = from.month == 12 ? DateTime(from.year + 1, 1, from.day) : DateTime(from.year, from.month + 1, from.day);
      return nextMonth;
  }
}