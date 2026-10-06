import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/recurring_transaction_model.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../core/utils/recurring_scheduler.dart';
import '../../data/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Har xil chastotadagi qoidalarni solishtirish uchun — yiliga nechta marta takrorlanadi
double _occurrencesPerYear(String frequency) {
  switch (frequency) {
    case 'daily':
      return 365;
    case 'weekly':
      return 52;
    case 'monthly':
    default:
      return 12;
  }
}

/// Qoidaning tanlangan davr (hafta/oy/yil) uchun ekvivalent summasi
double _projectedAmount(RecurringTransactionModel r, String periodTab) {
  final perYear = r.amount * _occurrencesPerYear(r.frequency);
  switch (periodTab) {
    case 'weekly':
      return perYear / 52;
    case 'monthly':
      return perYear / 12;
    case 'yearly':
    default:
      return perYear;
  }
}

String _frequencyLabel(String f) {
  switch (f) {
    case 'daily':
      return 'Har kuni';
    case 'weekly':
      return 'Har hafta';
    default:
      return 'Har oy';
  }
}

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  String _periodTab = 'monthly'; // 'weekly' | 'monthly' | 'yearly'

  @override
  Widget build(BuildContext context) {
      final allRules = ref.watch(recurringProvider);
      final categories = ref.watch(categoryProvider);
      final activeRules = allRules.where((r) => r.isActive).toList();

      final incomeRules = allRules.where((r) => r.type == 'income').toList()
        ..sort((a, b) => a.isActive == b.isActive ? a.nextOccurrence.compareTo(b.nextOccurrence) : (a.isActive ? -1 : 1));
      final expenseRules = allRules.where((r) => r.type == 'expense').toList()
        ..sort((a, b) => a.isActive == b.isActive ? a.nextOccurrence.compareTo(b.nextOccurrence) : (a.isActive ? -1 : 1));

      final totalIncome = activeRules.where((r) => r.type == 'income').fold(0.0, (s, r) => s + _projectedAmount(r, _periodTab));
      final totalExpense = activeRules.where((r) => r.type == 'expense').fold(0.0, (s, r) => s + _projectedAmount(r, _periodTab));

      final periodNoun = {'weekly': 'haftalik', 'monthly': 'oylik', 'yearly': 'yillik'}[_periodTab]!;

      return Scaffold(
        appBar: AppBar(title: const Text('Takrorlanuvchi tranzaksiyalar')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EqualSegmentedBar<String>(
              options: const {'Haftalik': 'weekly', 'Oylik': 'monthly', 'Yillik': 'yearly'},
              selected: _periodTab,
              onSelect: (v) => setState(() => _periodTab = v),
            ),
            const SizedBox(height: 14),
            Text('Kutilayotgan $periodNoun natija', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jami kirim', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Text('${NumberFormat("#,##0").format(totalIncome)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.brandIncome(context))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jami chiqim', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Text('${NumberFormat("#,##0").format(totalExpense)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.brandExpense(context))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (allRules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(icon: Icons.event_repeat_rounded, title: "Hali takrorlanuvchi tranzaksiya yo'q", subtitle: 'Pastdagi + tugmasi orqali qo\'shing'),
              )
            else ...[
              SectionTitle('Kirimlar', trailing: Text('${incomeRules.length} ta', style: Theme.of(context).textTheme.labelSmall)),
              if (incomeRules.isEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: Text("Hozircha yo'q", style: Theme.of(context).textTheme.labelSmall))
              else
                ...incomeRules.map((r) => FadeInItem(index: incomeRules.indexOf(r), child: _RuleTile(rule: r, periodTab: _periodTab, categoryName: _catName(categories, r.categoryId)))),
              const SizedBox(height: 16),

              SectionTitle('Chiqimlar', trailing: Text('${expenseRules.length} ta', style: Theme.of(context).textTheme.labelSmall)),
              if (expenseRules.isEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: Text("Hozircha yo'q", style: Theme.of(context).textTheme.labelSmall))
              else
                ...expenseRules.map((r) => FadeInItem(index: expenseRules.indexOf(r), child: _RuleTile(rule: r, periodTab: _periodTab, categoryName: _catName(categories, r.categoryId)))),
            ],
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _openSheet(context), icon: const Icon(Icons.add), label: const Text("Qo'shish")),
      );
  }

  String _catName(List categories, String id) {
    try {
      return categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return '—';
    }
  }

  void _openSheet(BuildContext context, {RecurringTransactionModel? existing}) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddRecurringSheet(existing: existing));
  }
}

class _RuleTile extends ConsumerWidget {
  final RecurringTransactionModel rule;
  final String periodTab;
  final String categoryName;
  const _RuleTile({required this.rule, required this.periodTab, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = rule;
    final color = r.type == 'income' ? AppTheme.brandIncome(context) : AppTheme.brandExpense(context);
    final projected = _projectedAmount(r, periodTab);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      tint: color,
      child: Opacity(
        opacity: r.isActive ? 1 : 0.5,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.14), child: Icon(r.type == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.source ?? categoryName, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('$categoryName • ${_frequencyLabel(r.frequency)}', style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Switch(
                  value: r.isActive,
                  onChanged: (v) async {
                    await ref.read(recurringProvider.notifier).toggleActive(r, v);
                    await scheduleRecurringNotification(r);
                  },
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('≈ ${NumberFormat("#,##0").format(projected)} so\'m', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                Row(
                  children: [
                    Icon(Icons.event_repeat_rounded, size: 13, color: AppTheme.mutedText(context)),
                    const SizedBox(width: 4),
                    Text(r.isActive ? DateFormat('dd.MM.yyyy').format(r.nextOccurrence) : "To'xtatilgan", style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(width: 12),
                    IconButton(icon: Icon(Icons.edit_outlined, size: 17, color: AppTheme.brandPrimary(context)), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddRecurringSheet(existing: r))),
                    const SizedBox(width: 12),
                    IconButton(icon: Icon(Icons.delete_outline, size: 17, color: AppTheme.brandExpense(context)), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _confirmDelete(context, ref, r)),
                  ],
                ),
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
      builder: (_) => AlertDialog(
        title: const Text("O'chirish"),
        content: const Text('Bu takrorlanuvchi qoidani o\'chirmoqchimisiz? (Avval yaratilgan tranzaksiyalar saqlanib qoladi)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              NotificationService.cancelById(r.id.hashCode);
              ref.read(recurringProvider.notifier).remove(r.id);
              Navigator.pop(context);
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
    _frequency = e?.frequency ?? 'monthly';
    _categoryId = e?.categoryId;
    _amountController = TextEditingController(text: e != null ? NumberFormat("#,##0").format(e.amount) : '');
    _sourceController = TextEditingController(text: e?.source ?? '');
    _startDate = e?.startDate ?? DateTime.now();
    _startTime = TimeOfDay.fromDateTime(e?.nextOccurrence ?? e?.startDate ?? DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? "Qoidani tahrirlash" : "Yangi takrorlanuvchi qoida", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: onSurface)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ChoiceChip(label: const Text('Chiqim'), selected: _type == 'expense', showCheckmark: false, selectedColor: AppTheme.brandExpense(context), labelStyle: TextStyle(color: _type == 'expense' ? Colors.white : onSurface, fontWeight: FontWeight.w600), onSelected: (_) => setState(() { _type = 'expense'; _categoryId = null; }))),
                    const SizedBox(width: 8),
                    Expanded(child: ChoiceChip(label: const Text('Kirim'), selected: _type == 'income', showCheckmark: false, selectedColor: AppTheme.brandIncome(context), labelStyle: TextStyle(color: _type == 'income' ? Colors.white : onSurface, fontWeight: FontWeight.w600), onSelected: (_) => setState(() { _type = 'income'; _categoryId = null; }))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController, keyboardType: TextInputType.number, inputFormatters: [ThousandsFormatter()],
                  style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(labelText: 'Summa', suffixText: "so'm"),
                ),
                const SizedBox(height: 16),
                Text("Bo'lim", style: TextStyle(fontWeight: FontWeight.w700, color: onSurface, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: categories.map((c) {
                    final catColor = Color(c.colorValue);
                    final selected = c.id == _categoryId;
                    return ChoiceChip(
                      label: Text(c.name), selected: selected, showCheckmark: false,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      selectedColor: catColor,
                      labelStyle: TextStyle(color: selected ? Colors.white : onSurface, fontWeight: FontWeight.w600),
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text("Qaysi vaqt davomida takrorlanadi", style: TextStyle(fontWeight: FontWeight.w700, color: onSurface, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('Har kuni'), selected: _frequency == 'daily', showCheckmark: false, selectedColor: AppTheme.brandPrimary(context), labelStyle: TextStyle(color: _frequency == 'daily' ? Colors.white : onSurface), onSelected: (_) => setState(() => _frequency = 'daily')),
                    ChoiceChip(label: const Text('Har hafta'), selected: _frequency == 'weekly', showCheckmark: false, selectedColor: AppTheme.brandPrimary(context), labelStyle: TextStyle(color: _frequency == 'weekly' ? Colors.white : onSurface), onSelected: (_) => setState(() => _frequency = 'weekly')),
                    ChoiceChip(label: const Text('Har oy'), selected: _frequency == 'monthly', showCheckmark: false, selectedColor: AppTheme.brandPrimary(context), labelStyle: TextStyle(color: _frequency == 'monthly' ? Colors.white : onSurface), onSelected: (_) => setState(() => _frequency = 'monthly')),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Boshlanish sanasi', style: TextStyle(color: onSurface)),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (picked != null) setState(() => _startDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Vaqt (bildirishnoma shu vaqtda keladi)', style: TextStyle(color: onSurface)),
                  subtitle: Text(_startTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _startTime);
                    if (picked != null) setState(() => _startTime = picked);
                  },
                ),
                TextField(controller: _sourceController, style: TextStyle(color: onSurface), decoration: const InputDecoration(labelText: 'Nomi (masalan: Ish haqi, Kommunal)')),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _save, child: Text(isEditing ? 'Saqlash' : "Qo'shish"))),
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
    await NotificationService.requestPermission();

    if (widget.existing != null) {
      final updated = widget.existing!;
      updated.amount = amount;
      updated.categoryId = _categoryId!;
      updated.type = _type;
      updated.frequency = _frequency;
      updated.startDate = combinedDateTime;
      updated.nextOccurrence = combinedDateTime;
      updated.source = _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim();
      await ref.read(recurringProvider.notifier).update(updated);
      await scheduleRecurringNotification(updated);
    } else {
      final model = RecurringTransactionModel(
        id: const Uuid().v4(), amount: amount, categoryId: _categoryId!, type: _type, frequency: _frequency,
        startDate: combinedDateTime, nextOccurrence: combinedDateTime,
        source: _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
      );
      await ref.read(recurringProvider.notifier).add(model);
      await scheduleRecurringNotification(model);
    }
    if (mounted) Navigator.pop(context);
  }
}