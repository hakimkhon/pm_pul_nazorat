import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';

/// Joriy umumiy balansni hisoblaydi (barcha vaqt uchun, kirim - chiqim).
/// excludeTransactionId berilsa, shu tranzaksiya hisobga olinmaydi
/// (mavjud tranzaksiyani TAHRIRLASHDA ishlatiladi — o'zining eski summasi
/// balansdan avval ayirilgan bo'lgani uchun, uni qaytarib qo'shib hisoblash kerak).
double calculateCurrentBalance(WidgetRef ref, {String? excludeTransactionId}) {
  final transactions = ref.read(transactionProvider);
  double balance = 0;
  for (var t in transactions) {
    if (t.id == excludeTransactionId) continue;
    balance += t.type == 'income' ? t.amount : -t.amount;
  }
  return balance;
}