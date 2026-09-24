import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../models/recurring_transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../data/notification_service.dart';
import '../../data/notification_history.dart';
import 'balance_guard.dart';

/// Keyingi davr uchun sana+vaqtni hisoblaydi (vaqtni saqlab qoladi)
DateTime nextOccurrenceAfter(DateTime from, String frequency) {
  switch (frequency) {
    case 'daily':
      return from.add(const Duration(days: 1));
    case 'weekly':
      return from.add(const Duration(days: 7));
    case 'monthly':
    default:
      final nextMonth = from.month == 12 ? DateTime(from.year + 1, 1, from.day, from.hour, from.minute) : DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
      return nextMonth;
  }
}

/// Bitta qoida uchun tasdiqlash bildirishnomasini (qayta) rejalashtiradi.
/// isActive=false bo'lsa, avvalgi bildirishnoma bekor qilinadi.
/// Agar nextOccurrence allaqachon O'TIB KETGAN bo'lsa (masalan dastur yopiq turgan
/// yoki o'tmish vaqt tanlangan bo'lsa), keyingi to'g'ri vaqtgacha avtomatik suriladi.
Future<void> scheduleRecurringNotification(RecurringTransactionModel r) async {
  await NotificationService.cancelById(r.id.hashCode);
  if (!r.isActive) return;

  var target = r.nextOccurrence;
  final now = DateTime.now();
  bool changed = false;
  while (target.isBefore(now.add(const Duration(seconds: 5)))) {
    target = nextOccurrenceAfter(target, r.frequency);
    changed = true;
  }
  if (changed) {
    r.nextOccurrence = target;
    await r.save();
  }

  await NotificationService.scheduleRecurringConfirmation(
    id: r.id.hashCode,
    title: 'Takrorlanuvchi tranzaksiya',
    body: '"${r.source ?? 'Tranzaksiya'}" — ${r.amount.toStringAsFixed(0)} so\'m. Tasdiqlaysizmi?',
    scheduledDate: r.nextOccurrence,
    payload: r.id,
  );
}

/// Dastur ochilganda — barcha FAOL qoidalar uchun bildirishnomalarni qayta rejalashtiradi
/// (masalan qurilma o'chib-yonganda yo'qolgan eslatmalarni tiklash uchun)
Future<void> rescheduleAllRecurring(WidgetRef ref) async {
  final list = ref.read(recurringProvider);
  for (var r in list) {
    if (r.isActive) await scheduleRecurringNotification(r);
  }
}

/// Bildirishnoma tugmasi ('done' | 'snooze' | 'cancel_action') bosilganda chaqiriladi
Future<void> handleRecurringAction(WidgetRef ref, String recurringId, String action) async {
  final list = ref.read(recurringProvider);
  RecurringTransactionModel? r;
  try {
    r = list.firstWhere((x) => x.id == recurringId);
  } catch (_) {
    return;
  }

  if (action == 'done') {
    if (r.type == 'expense' && r.amount > calculateCurrentBalance(ref)) {
      await NotificationHistory.add(
        "Yetarli mablag' yo'q",
        '"${r.source ?? r.categoryId}" — ${r.amount.toStringAsFixed(0)} so\'m yaratilmadi (balans yetarli emas)',
      );
      r.nextOccurrence = nextOccurrenceAfter(r.nextOccurrence, r.frequency);
      await r.save();
      ref.read(recurringProvider.notifier).refresh();
      if (r.isActive) await scheduleRecurringNotification(r);
      return;
    }

    final tx = TransactionModel(
      id: const Uuid().v4(),
      amount: r.amount,
      categoryId: r.categoryId,
      type: r.type,
      date: r.nextOccurrence,
      note: r.note,
      source: r.source ?? 'Avtomatik (takrorlanuvchi)',
    );
    await ref.read(transactionProvider.notifier).addTransaction(tx);
    await NotificationHistory.add('Takrorlanuvchi tranzaksiya tasdiqlandi', '"${r.source ?? r.categoryId}" — ${r.amount.toStringAsFixed(0)} so\'m qo\'shildi');
    r.nextOccurrence = nextOccurrenceAfter(r.nextOccurrence, r.frequency);
  } else if (action == 'cancel_action' || action == 'cancel') {
    await NotificationHistory.add('Takrorlanuvchi tranzaksiya bekor qilindi', '"${r.source ?? r.categoryId}" ushbu safar yaratilmadi');
    r.nextOccurrence = nextOccurrenceAfter(r.nextOccurrence, r.frequency);
  } else if (action == 'snooze') {
    r.nextOccurrence = r.nextOccurrence.add(const Duration(hours: 2));
  }

  await r.save();
  ref.read(recurringProvider.notifier).refresh();

  if (r.isActive) {
    await scheduleRecurringNotification(r);
  }
}