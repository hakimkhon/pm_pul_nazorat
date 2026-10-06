import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../models/recurring_transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../data/notification_service.dart';
import '../../data/notification_history.dart';
import 'balance_guard.dart';
import 'app_keys.dart';

DateTime nextOccurrenceAfter(DateTime from, String frequency, {int? anchorDay}) {
  switch (frequency) {
    case 'daily':
      return from.add(const Duration(days: 1));
    case 'weekly':
      return from.add(const Duration(days: 7));
    case 'once':
      return from; // takrorlanmaydi — sana surilmaydi
    default:
      // Oylik: asl kunga (anchorDay) qaytadi; oy qisqa bo'lsa oxirgi kunga tushadi (31 → 30/28)
      final y = from.month == 12 ? from.year + 1 : from.year;
      final m = from.month == 12 ? 1 : from.month + 1;
      final lastDay = DateTime(y, m + 1, 0).day;
      final wanted = anchorDay ?? from.day;
      return DateTime(y, m, wanted > lastDay ? lastDay : wanted, from.hour, from.minute);
  }
}

/// Keyingi davrga suradi (hozirgi vaqtdan keyingi birinchi sanagacha)
DateTime _advance(RecurringTransactionModel r) {
  if (r.frequency == 'once') return r.nextOccurrence; // cheksiz tsiklning oldini oladi
  var next = nextOccurrenceAfter(r.nextOccurrence, r.frequency, anchorDay: r.startDate.day);
  final now = DateTime.now();
  while (next.isBefore(now)) {
    next = nextOccurrenceAfter(next, r.frequency, anchorDay: r.startDate.day);
  }
  return next;
}

/// Natijani foydalanuvchiga ALBATTA ko'rsatadi: ilova ichida SnackBar + tizim bildirishnomasi
Future<void> _feedback(String title, String body, {bool error = false}) async {
  rootMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: error ? 8 : 4),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      content: Text('$title\n$body', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    ));
  if (error) {
    await NotificationService.showAlert(title, body);
  } else {
    await NotificationService.showInfo(title, body);
  }
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
    if (r.frequency == 'once') {
      // Takrorlanmaydigan: vaqti o'tib ketgan bo'lsa rejalanmaydi va keyingi davrga surilmaydi
      if (!target.isAfter(now.add(const Duration(seconds: 5)))) return;
    } else {
      var changed = false;
      while (target.isBefore(now.add(const Duration(seconds: 5)))) {
        target = nextOccurrenceAfter(target, r.frequency, anchorDay: r.startDate.day);
        changed = true;
      }
      if (changed) {
        r.nextOccurrence = target;
        await r.save();
      }
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
  final isOnce = r.frequency == 'once';

  // Takrorlanmaydigan qoida allaqachon yakunlangan bo'lsa, eski tugma qayta ishlamaydi
  if (isOnce && !r.isActive && action != 'snooze') return;

  // Bu bildirishnoma allaqachon o'tib ketgan davr uchunmi (qoida keyingi davrga surilgan)?
  final stale = occurrence != null && r.nextOccurrence.isAfter(occurrence);

  if (stale && action == 'snooze') {
    await NotificationService.showInfo('Eslatma eskirgan', '"$name" uchun keyingi davr allaqachon rejalangan');
    return;
  }

  var created = false;
  if (action == 'done') {
    if (r.type == 'expense' && r.amount > calculateCurrentBalance(ref)) {
      final fmt = NumberFormat('#,##0');
      final detail = '"$name" uchun ${fmt.format(r.amount)} so\'m kerak, balansda ${fmt.format(calculateCurrentBalance(ref))} so\'m bor';
      await NotificationHistory.add("Mablag' yetarli emas", detail);
      await _feedback("Mablag' yetarli emas ❌", '$detail. Tranzaksiya yaratilmadi.', error: true);
    } else {
      await ref.read(transactionProvider.notifier).addTransaction(TransactionModel(
            id: const Uuid().v4(),
            amount: r.amount,
            categoryId: r.categoryId,
            type: r.type,
            date: DateTime.now(), // tasdiqlangan payt — joriy oyda albatta ko'rinadi
            note: r.note,
            source: name,
            recurringId: r.id, // "bu yilgi jami" hisoblash uchun qoidaga bog'lanadi
          ));
      created = true;
      ref.read(transactionProvider.notifier).refresh();
      await NotificationHistory.add('Tranzaksiya qo\'shildi', '"$name" — ${r.amount.toStringAsFixed(0)} so\'m');
      await _feedback("Qo'shildi ✅", '"$name" — ${NumberFormat('#,##0').format(r.amount)} so\'m tranzaksiyalarga yozildi');
    }
    r.snoozeUntil = null;
    if (isOnce) {
      // Bir martalik: faqat tranzaksiya yaratilgandagina yakunlanadi (balans yetmasa qoida saqlanadi)
      if (created && !stale) r.isActive = false;
    } else if (!stale) {
      r.nextOccurrence = _advance(r);
    }
  } else if (action == 'cancel_action' || action == 'cancel') {
    await NotificationHistory.add('Bekor qilindi', '"$name" ushbu safar yaratilmadi');
    r.snoozeUntil = null;
    if (isOnce) {
      if (!stale) r.isActive = false;
    } else if (!stale) {
      r.nextOccurrence = _advance(r);
    }
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