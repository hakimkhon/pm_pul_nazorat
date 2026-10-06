import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/recurring_transaction_model.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../core/utils/recurring_scheduler.dart';
import '../../core/utils/balance_guard.dart';
import '../../core/utils/app_keys.dart';
import '../../data/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

const _monthNames = [
  'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
];

/// Tanlangan davr: [start, end) — start 00:00 dan end 00:00 gacha
class _Range {
  final DateTime start;
  final DateTime end;
  const _Range(this.start, this.end);

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
}

_Range _rangeFor(String tab, DateTime anchor) {
  final d = DateTime(anchor.year, anchor.month, anchor.day);
  switch (tab) {
    case 'weekly':
      final start = d.subtract(Duration(days: d.weekday - 1)); // dushanba
      return _Range(start, start.add(const Duration(days: 7)));
    case 'yearly':
      return _Range(DateTime(d.year), DateTime(d.year + 1));
    case 'monthly':
    default:
      return _Range(DateTime(d.year, d.month), DateTime(d.year, d.month + 1));
  }
}

DateTime _shiftAnchor(DateTime a, String tab, int dir) {
  switch (tab) {
    case 'weekly':
      return a.add(Duration(days: 7 * dir));
    case 'yearly':
      return DateTime(a.year + dir, 1, 1);
    case 'monthly':
    default:
      return DateTime(a.year, a.month + dir, 1);
  }
}

String _rangeLabel(String tab, _Range r) {
  switch (tab) {
    case 'weekly':
      final last = r.end.subtract(const Duration(days: 1));
      return '${DateFormat('dd.MM').format(r.start)} – ${DateFormat('dd.MM.yyyy').format(last)}';
    case 'yearly':
      return '${r.start.year}';
    case 'monthly':
    default:
      return '${_monthNames[r.start.month - 1]} ${r.start.year}';
  }
}

int _daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Qoida tanlangan davrda necha marta sodir bo'lishi (boshlanish sanasidan hisoblanadi)
int _occurrencesIn(RecurringTransactionModel r, _Range range) {
  final first = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);

  switch (r.frequency) {
    case 'once':
      return range.contains(r.nextOccurrence) ? 1 : 0;

    case 'daily':
      final from = range.start.isAfter(first) ? range.start : first;
      final n = _daysBetween(from, range.end);
      return n > 0 ? n : 0;

    case 'weekly':
      var firstInRange = first;
      if (range.start.isAfter(first)) {
        final gap = _daysBetween(first, range.start);
        firstInRange = first.add(Duration(days: ((gap + 6) ~/ 7) * 7));
      }
      if (!firstInRange.isBefore(range.end)) return 0;
      return (_daysBetween(firstInRange, range.end) - 1) ~/ 7 + 1;

    case 'monthly':
    default:
      var count = 0;
      var y = range.start.year;
      var m = range.start.month;
      while (DateTime(y, m).isBefore(range.end)) {
        final lastDay = DateTime(y, m + 1, 0).day;
        final day = first.day > lastDay ? lastDay : first.day;
        final occ = DateTime(y, m, day);
        if (!occ.isBefore(first) && range.contains(occ)) count++;
        m++;
        if (m > 12) {
          m = 1;
          y++;
        }
      }
      return count;
  }
}

/// Qoidaning tanlangan davrdagi jami summasi
double _periodAmount(RecurringTransactionModel r, _Range range) => r.amount * _occurrencesIn(r, range);

String _frequencyLabel(String f) {
  switch (f) {
    case 'daily':
      return 'Har kuni';
    case 'weekly':
      return 'Har hafta';
    case 'once':
      return 'Bir marta';
    default:
      return 'Har oy';
  }
}

String _signed(double v) {
  final text = NumberFormat("#,##0").format(v.abs());
  if (v > 0) return '+$text';
  if (v < 0) return '−$text';
  return text;
}

void _openSheet(BuildContext context, {RecurringTransactionModel? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddRecurringSheet(existing: existing),
  );
}

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  String _periodTab = 'monthly'; // 'weekly' | 'monthly' | 'yearly'
  DateTime _anchor = DateTime.now(); // tanlangan davr shu sanani o'z ichiga oladi

  @override
  Widget build(BuildContext context) {
    final allRules = ref.watch(recurringProvider);
    final categories = ref.watch(categoryProvider);
    final transactions = ref.watch(transactionProvider);
    final activeRules = allRules.where((r) => r.isActive).toList();
    final range = _rangeFor(_periodTab, _anchor);
    final now = DateTime.now();
    final isCurrent = range.contains(now);

    int byDate(RecurringTransactionModel a, RecurringTransactionModel b) =>
        a.isActive == b.isActive ? a.nextOccurrence.compareTo(b.nextOccurrence) : (a.isActive ? -1 : 1);
    final incomeRules = allRules.where((r) => r.type == 'income').toList()..sort(byDate);
    final expenseRules = allRules.where((r) => r.type == 'expense').toList()..sort(byDate);

    double sum(Iterable<RecurringTransactionModel> rules, String type) =>
        rules.where((r) => r.type == type).fold(0.0, (acc, r) => acc + _periodAmount(r, range));

    final totalIncome = sum(activeRules, 'income');
    final totalExpense = sum(activeRules, 'expense');
    final allIncome = sum(allRules, 'income');
    final allExpense = sum(allRules, 'expense');

    // Har bir qoida bo'yicha TANLANGAN DAVRDA haqiqatda tasdiqlangan tranzaksiyalar
    final doneCount = <String, int>{};
    final doneSum = <String, double>{};
    for (final t in transactions) {
      final rid = t.recurringId;
      if (rid == null || !range.contains(t.date)) continue;
      doneCount[rid] = (doneCount[rid] ?? 0) + 1;
      doneSum[rid] = (doneSum[rid] ?? 0) + t.amount;
    }
    final periodWord = {'weekly': 'hafta', 'monthly': 'oy', 'yearly': 'yil'}[_periodTab]!;
    final periodPrefix = '${isCurrent ? 'Bu' : 'Shu'} $periodWord';

    Widget tile(RecurringTransactionModel r, int i) => FadeInItem(
          index: i,
          child: _RuleTile(
            rule: r,
            range: range,
            categoryName: _catName(categories, r.categoryId),
            periodPrefix: periodPrefix,
            doneCount: doneCount[r.id] ?? 0,
            doneSum: doneSum[r.id] ?? 0,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Takrorlanuvchi tranzaksiyalar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        children: [
          EqualSegmentedBar<String>(
            options: const {'Haftalik': 'weekly', 'Oylik': 'monthly', 'Yillik': 'yearly'},
            selected: _periodTab,
            onSelect: (v) => setState(() => _periodTab = v),
          ),
          const SizedBox(height: 4),
          // Qaysi hafta / oy / yil ekanini tanlash: strelkalar bilan oldinga-orqaga, nomiga bosilsa — joriy davr
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _anchor = _shiftAnchor(_anchor, _periodTab, -1)),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _anchor = DateTime.now()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_rangeLabel(_periodTab, range), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        if (!isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.brandPrimary(context).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Bugun', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.brandPrimary(context))),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() => _anchor = _shiftAnchor(_anchor, _periodTab, 1)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text("Kutilayotgan natija (so'm)", style: Theme.of(context).textTheme.labelSmall),
          ),
          _SummaryCard(income: totalIncome, expense: totalExpense),
          if (allRules.isNotEmpty) ...[
            const SizedBox(height: 6),
            _PausedTotalRow(income: allIncome, expense: allExpense),
          ],
          const SizedBox(height: 8),
          if (allRules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(icon: Icons.event_repeat_rounded, title: "Hali takrorlanuvchi tranzaksiya yo'q", subtitle: "Pastdagi tugma orqali qo'shing"),
            )
          else ...[
            SectionTitle('Kirimlar', trailing: Text('${incomeRules.length} ta', style: Theme.of(context).textTheme.labelSmall)),
            if (incomeRules.isEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text("Hozircha yo'q", style: Theme.of(context).textTheme.labelSmall))
            else
              ...List.generate(incomeRules.length, (i) => tile(incomeRules[i], i)),
            const SizedBox(height: 8),
            SectionTitle('Chiqimlar', trailing: Text('${expenseRules.length} ta', style: Theme.of(context).textTheme.labelSmall)),
            if (expenseRules.isEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text("Hozircha yo'q", style: Theme.of(context).textTheme.labelSmall))
            else
              ...List.generate(expenseRules.length, (i) => tile(expenseRules[i], i)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.add),
        label: const Text("Qo'shish"),
      ),
    );
  }

  String _catName(List categories, String id) {
    try {
      return categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return '—';
    }
  }
}

/// Jami kirim / chiqim / sof natija — bitta ixcham qatorda (faqat faol qoidalar)
class _SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  const _SummaryCard({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final netColor = net >= 0 ? AppTheme.brandIncome(context) : AppTheme.brandExpense(context);
    final fmt = NumberFormat("#,##0");
    final line = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);

    Widget stat(String label, String value, Color color, {bool padLeft = true}) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: padLeft ? 12 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
                ),
              ],
            ),
          ),
        );

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: IntrinsicHeight(
        child: Row(
          children: [
            stat('Kirim', fmt.format(income), AppTheme.brandIncome(context), padLeft: false),
            VerticalDivider(width: 1, thickness: 1, color: line),
            stat('Chiqim', fmt.format(expense), AppTheme.brandExpense(context)),
            VerticalDivider(width: 1, thickness: 1, color: line),
            stat('Sof natija', _signed(net), netColor),
          ],
        ),
      ),
    );
  }
}

/// Kulrang qator: to'xtatilgan qoidalar bilan birga umumiy jami
class _PausedTotalRow extends StatelessWidget {
  final double income;
  final double expense;
  const _PausedTotalRow({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final grey = AppTheme.mutedText(context);
    final fmt = NumberFormat("#,##0");
    final small = Theme.of(context).textTheme.labelSmall?.copyWith(color: grey);
    final bold = small?.copyWith(fontWeight: FontWeight.w700);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: "Jami (to'xtatilgan bilan)  ", style: bold),
          TextSpan(text: 'Kirim ', style: small),
          TextSpan(text: fmt.format(income), style: bold),
          TextSpan(text: '  •  Chiqim ', style: small),
          TextSpan(text: fmt.format(expense), style: bold),
          TextSpan(text: '  •  Sof ', style: small),
          TextSpan(text: _signed(income - expense), style: bold),
        ]),
      ),
    );
  }
}

/// Ixcham qoida kartasi: 3 qator matn + summa + menyu (tahrirlash / to'xtatish / o'chirish)
class _RuleTile extends ConsumerWidget {
  final RecurringTransactionModel rule;
  final _Range range;
  final String categoryName;
  final String periodPrefix; // "Bu oy" / "Shu hafta" ...
  final int doneCount;
  final double doneSum;
  const _RuleTile({required this.rule, required this.range, required this.categoryName, required this.periodPrefix, this.doneCount = 0, this.doneSum = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = rule;
    final isIncome = r.type == 'income';
    final color = isIncome ? AppTheme.brandIncome(context) : AppTheme.brandExpense(context);
    final muted = AppTheme.mutedText(context);
    final small = Theme.of(context).textTheme.labelSmall;
    final fmt = NumberFormat("#,##0");

    final isOnce = r.frequency == 'once';
    final amountText = isOnce ? fmt.format(r.amount) : fmt.format(_periodAmount(r, range));
    final overdue = isOnce && r.isActive && r.nextOccurrence.isBefore(DateTime.now());
    final dateText = !r.isActive
        ? (isOnce ? 'Yakunlangan' : "To'xtatilgan")
        : (overdue ? "Muddati o'tgan" : DateFormat('dd.MM.yyyy').format(r.nextOccurrence));
    final verb = isIncome ? 'olingan' : "to'langan";
    final verbNot = isIncome ? 'olinmagan' : "to'lanmagan";
    final planned = _occurrencesIn(r, range);
    final plannedHint = planned > 0 ? ' (reja: $planned marta)' : '';
    final yearText = doneCount == 0
        ? '$periodPrefix hali $verbNot$plannedHint'
        : '$periodPrefix $verb: $doneCount${planned > 0 ? ' / $planned' : ''} marta • ${fmt.format(doneSum)} so\'m';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
      tint: color,
      child: Opacity(
        opacity: r.isActive ? 1 : 0.55,
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.source ?? categoryName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '$categoryName • ${_frequencyLabel(r.frequency)} • $dateText',
                    style: small?.copyWith(color: overdue ? AppTheme.brandExpense(context) : null),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(yearText, style: small?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("$amountText so'm", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert_rounded, size: 20, color: muted),
              onSelected: (v) async {
                if (v == 'edit') {
                  _openSheet(context, existing: r);
                } else if (v == 'toggle') {
                  await ref.read(recurringProvider.notifier).toggleActive(r, !r.isActive);
                  await scheduleRecurringNotification(r);
                } else if (v == 'delete') {
                  _confirmDelete(context, ref, r);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                PopupMenuItem(value: 'toggle', child: Text(r.isActive ? "To'xtatish" : 'Davom ettirish')),
                const PopupMenuItem(value: 'delete', child: Text("O'chirish")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, RecurringTransactionModel r) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("O'chirish"),
        content: const Text("Bu qoidani o'chirmoqchimisiz? (Avval yaratilgan tranzaksiyalar saqlanib qoladi)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              NotificationService.cancelById(r.id.hashCode);
              ref.read(recurringProvider.notifier).remove(r.id);
              Navigator.pop(dialogContext);
            },
            child: Text("O'chirish", style: TextStyle(color: AppTheme.brandExpense(context))),
          ),
        ],
      ),
    );
  }
}

class _AddRecurringSheet extends ConsumerStatefulWidget {
  final RecurringTransactionModel? existing;
  const _AddRecurringSheet({this.existing});

  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  late String _type;
  late String _frequency;
  String? _categoryId;
  late final TextEditingController _amountController;
  late final TextEditingController _sourceController;
  late DateTime _startDate;
  late TimeOfDay _startTime;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'expense';
    _frequency = e?.frequency ?? 'once'; // yangi qo'shishda standart: Bir marta
    _categoryId = e?.categoryId;
    _amountController = TextEditingController(text: e != null ? NumberFormat("#,##0").format(e.amount) : '');
    _sourceController = TextEditingController(text: e?.source ?? '');
    // Yangi qoida uchun standart vaqt: keyingi soatning boshi (har doim kelajakda)
    final defaultWhen = DateTime.now().add(const Duration(hours: 1));
    _startDate = e?.nextOccurrence ?? e?.startDate ?? defaultWhen;
    _startTime = e != null ? TimeOfDay.fromDateTime(e.nextOccurrence) : TimeOfDay(hour: defaultWhen.hour, minute: 0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Widget _freqChip(String value, String label, Color onSurface) {
    final selected = _frequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: AppTheme.brandPrimary(context),
      labelStyle: TextStyle(color: selected ? Colors.white : onSurface, fontSize: 13),
      onSelected: (_) => setState(() => _frequency = value),
    );
  }

  Widget _typeChip(String value, String label, Color color, Color onSurface) {
    final selected = _type == value;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        selectedColor: color,
        labelStyle: TextStyle(color: selected ? Colors.white : onSurface, fontWeight: FontWeight.w600),
        onSelected: (_) => setState(() {
          _type = value;
          _categoryId = null;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider).where((c) => c.type == _type).toList();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? 'Tahrirlash' : "Yangi takrorlanuvchi qo'shish", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurface)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _typeChip('expense', 'Chiqim', AppTheme.brandExpense(context), onSurface),
                    const SizedBox(width: 8),
                    _typeChip('income', 'Kirim', AppTheme.brandIncome(context), onSurface),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  style: TextStyle(color: onSurface, fontSize: 17, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(labelText: 'Summa', suffixText: "so'm", isDense: true),
                ),
                const SizedBox(height: 12),
                Text("Bo'lim", style: TextStyle(fontWeight: FontWeight.w700, color: onSurface, fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: categories.map((c) {
                    final selected = c.id == _categoryId;
                    return ChoiceChip(
                      label: Text(c.name),
                      selected: selected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      selectedColor: Color(c.colorValue),
                      labelStyle: TextStyle(color: selected ? Colors.white : onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Qaysi vaqt davomida takrorlanadi', style: TextStyle(fontWeight: FontWeight.w700, color: onSurface, fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _freqChip('once', 'Bir marta', onSurface),
                    _freqChip('daily', 'Har kuni', onSurface),
                    _freqChip('weekly', 'Har hafta', onSurface),
                    _freqChip('monthly', 'Har oy', onSurface),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PickTile(
                        icon: Icons.calendar_today_rounded,
                        label: _frequency == 'once' ? 'Sana' : 'Boshlanish sanasi',
                        value: DateFormat('dd.MM.yyyy').format(_startDate),
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (picked != null) setState(() => _startDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PickTile(
                        icon: Icons.access_time_rounded,
                        label: 'Bildirishnoma vaqti',
                        value: _startTime.format(context),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: _startTime);
                          if (picked != null) setState(() => _startTime = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sourceController,
                  style: TextStyle(color: onSurface),
                  decoration: const InputDecoration(labelText: 'Nomi (masalan: Ish haqi, Kommunal)', isDense: true),
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: _save, child: Text(isEditing ? 'Saqlash' : "Qo'shish"))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    final amount = ThousandsFormatter.parse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Iltimos, to'g'ri summa kiriting")));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bo'limni tanlang")));
      return;
    }

    final combinedDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    if (_frequency == 'once' && !combinedDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bir martalik to'lov uchun kelajakdagi sana va vaqtni tanlang")));
      return;
    }
    await NotificationService.requestPermission();

    final sourceText = _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim();

    if (widget.existing != null) {
      final updated = widget.existing!;
      updated.amount = amount;
      updated.categoryId = _categoryId!;
      updated.type = _type;
      updated.frequency = _frequency;
      updated.startDate = combinedDateTime;
      updated.nextOccurrence = combinedDateTime;
      updated.source = sourceText;
      await ref.read(recurringProvider.notifier).update(updated);
      await scheduleRecurringNotification(updated);
    } else {
      final model = RecurringTransactionModel(
        id: const Uuid().v4(),
        amount: amount,
        categoryId: _categoryId!,
        type: _type,
        frequency: _frequency,
        startDate: combinedDateTime,
        nextOccurrence: combinedDateTime,
        source: sourceText,
      );
      await ref.read(recurringProvider.notifier).add(model);
      await scheduleRecurringNotification(model);
    }

    // Chiqim uchun mablag' yetmasa — saqlangandan keyin ham aniq ko'rinadigan ogohlantirish
    final balance = _type == 'expense' ? calculateCurrentBalance(ref) : 0.0;
    final lacking = _type == 'expense' && balance < amount;

    if (mounted) Navigator.pop(context);

    if (lacking) {
      final fmt = NumberFormat('#,##0');
      rootMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.red.shade700,
          content: Text(
            "Mablag' yetarli emas: balansda ${fmt.format(balance)} so'm bor, chiqim ${fmt.format(amount)} so'm. "
            "Tasdiqlash vaqtida ham yetmasa, tranzaksiya yaratilmaydi.",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ));
    }
  }
}

/// Sana / vaqt tanlash uchun ixcham katak
class _PickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: onSurface.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.brandPrimary(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
