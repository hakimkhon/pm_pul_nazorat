import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../models/recurring_transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../data/notification_service.dart';
import '../../data/notification_history.dart';
import 'balance_guard.dart';

DateTime nextOccurrenceAfter(DateTime from, String frequency) {
  switch (frequency) {
    case 'daily':
      return from.add(const Duration(days: 1));
    case 'weekly':
      return from.add(const Duration(days: 7));
    default:
      return from.month == 12
          ? DateTime(from.year + 1, 1, from.day, from.hour, from.minute)
          : DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
  }
}

/// Keyingi davrga suradi (hozirgi vaqtdan keyingi birinchi sanagacha)
DateTime _advance(RecurringTransactionModel r) {
  var next = nextOccurrenceAfter(r.nextOccurrence, r.frequency);
  final now = DateTime.now();
  while (next.isBefore(now)) {
    next = nextOccurrenceAfter(next, r.frequency);
  }
  return next;
}

/// Bir xil tugma ikki marta ishlab ketmasligi uchun himoya
final Map<String, DateTime> _recentActions = {};
bool _isDuplicate(String key) {
  final now = DateTime.now();
  _recentActions.removeWhere((_, t) => now.difference(t).inSeconds > 15);
  if (_recentActions.containsKey(key)) return true;
  _recentActions[key] = now;
  return false;
}

Future<void> scheduleRecurringNotification(RecurringTransactionModel r) async {
  await NotificationService.cancelById(r.id.hashCode);
  if (!r.isActive) return;

  final now = DateTime.now();
  DateTime target;

  if (r.snoozeUntil != null && r.snoozeUntil!.isAfter(now)) {
    target = r.snoozeUntil!;
  } else {
    if (r.snoozeUntil != null) {
      r.snoozeUntil = null;
      await r.save();
    }
    target = r.nextOccurrence;
    var changed = false;
    while (target.isBefore(now.add(const Duration(seconds: 5)))) {
      target = nextOccurrenceAfter(target, r.frequency);
      changed = true;
    }
    if (changed) {
      r.nextOccurrence = target;
      await r.save();
    }
  }

  await NotificationService.scheduleRecurringConfirmation(
    id: r.id.hashCode,
    title: 'Takrorlanuvchi tranzaksiya',
    body: '"${r.source ?? 'Tranzaksiya'}" — ${r.amount.toStringAsFixed(0)} so\'m. Tasdiqlaysizmi?',
    scheduledDate: target,
    // payload: "<id>|<qaysi sana uchun, ms>" — eski bildirishnoma keyin bosilsa ham
    // tranzaksiya to'g'ri sanaga yoziladi va qoida ikki marta surilib ketmaydi
    payload: '${r.id}|${r.nextOccurrence.millisecondsSinceEpoch}',
  );
}

Future<void> rescheduleAllRecurring(WidgetRef ref) async {
  for (var r in ref.read(recurringProvider)) {
    if (r.isActive) await scheduleRecurringNotification(r);
  }
}

/// Bildirishnoma tugmasi: 'done' | 'snooze' | 'cancel_action'
Future<void> handleRecurringAction(WidgetRef ref, String payload, String action) async {
  try {
    await _handleRecurringAction(ref, payload, action);
  } catch (e) {
    // Xato jim yutilib ketmasin — Bildirishnomalar tarixida ko'rinadi
    await NotificationHistory.add('Xatolik (tugma)', '$action: $e');
  }
}

Future<void> _handleRecurringAction(WidgetRef ref, String payload, String action) async {
  if (_isDuplicate('$payload|$action')) return;

  // payload: "<id>|<ms>" (yoki eski format: faqat "<id>")
  final parts = payload.split('|');
  final recurringId = parts.first;
  DateTime? occurrence;
  if (parts.length > 1) {
    final ms = int.tryParse(parts[1]);
    if (ms != null) occurrence = DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // Sinov bildirishnomasi — faqat tugmalar ishlayotganini ko'rsatadi
  if (recurringId == 'test') {
    await NotificationHistory.add('Sinov bildirishnomasi', '"$action" tugmasi ishladi ✅');
    await NotificationService.showInfo('Sinov', '"$action" tugmasi ishladi ✅');
    return;
  }

  RecurringTransactionModel? r;
  try {
    r = ref.read(recurringProvider).firstWhere((x) => x.id == recurringId);
  } catch (_) {
    await NotificationHistory.add('Qoida topilmadi', 'Tugma bosildi ($action), lekin takrorlanuvchi qoida topilmadi');
    return;
  }
  final name = r.source ?? 'Tranzaksiya';

  // Bu bildirishnoma allaqachon o'tib ketgan davr uchunmi (qoida keyingi davrga surilgan)?
  final stale = occurrence != null && r.nextOccurrence.isAfter(occurrence);

  if (stale && action == 'snooze') {
    await NotificationService.showInfo('Eslatma eskirgan', '"$name" uchun keyingi davr allaqachon rejalangan');
    return;
  }

  if (action == 'done') {
    if (r.type == 'expense' && r.amount > calculateCurrentBalance(ref)) {
      await NotificationHistory.add("Yetarli mablag' yo'q", '"$name" yaratilmadi (balans yetarli emas)');
      await NotificationService.showInfo("Yetarli mablag' yo'q", '"$name" yaratilmadi');
    } else {
      await ref.read(transactionProvider.notifier).addTransaction(TransactionModel(
            id: const Uuid().v4(),
            amount: r.amount,
            categoryId: r.categoryId,
            type: r.type,
            date: DateTime.now(), // tasdiqlangan payt — joriy oyda albatta ko'rinadi
            note: r.note,
            source: name,
          ));
      ref.read(transactionProvider.notifier).refresh();
      await NotificationHistory.add('Tranzaksiya qo\'shildi', '"$name" — ${r.amount.toStringAsFixed(0)} so\'m');
      await NotificationService.showInfo("Qo'shildi ✅", '"$name" tranzaksiyalarga yozildi');
    }
    r.snoozeUntil = null;
    if (!stale) r.nextOccurrence = _advance(r);
  } else if (action == 'cancel_action' || action == 'cancel') {
    await NotificationHistory.add('Bekor qilindi', '"$name" ushbu safar yaratilmadi');
    r.snoozeUntil = null;
    if (!stale) r.nextOccurrence = _advance(r);
  } else if (action == 'snooze') {
    r.snoozeUntil = DateTime.now().add(const Duration(hours: 2));
    await NotificationHistory.add('Keyinroq eslatiladi', '"$name" — 2 soatdan keyin');
  } else {
    return;
  }

  await r.save();
  ref.read(recurringProvider.notifier).refresh();
  if (r.isActive) await scheduleRecurringNotification(r);
}