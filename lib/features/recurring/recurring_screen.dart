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

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  String _frequencyLabel(String f) {
    switch (f) {
      case 'daily': return 'Har kuni';
      case 'weekly': return 'Har hafta';
      default: return 'Har oy';
    }
  }

  DateTime _nextOccurrence(RecurringTransactionModel r) => r.nextOccurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurrences = ref.watch(recurringProvider);
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Takrorlanuvchi tranzaksiyalar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.brandGold(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.brandGold(context), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Bu yerda har oy/hafta/kun takrorlanadigan kirim yoki chiqimlarni (ish haqi, ijara, kommunal) belgilab qo'ysangiz, dastur ularni siz uchun avtomatik yaratib boradi — har safar qo'lda kiritish shart emas.",
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: recurrences.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(icon: Icons.autorenew_rounded, title: "Hali takrorlanuvchi tranzaksiya yo'q", subtitle: 'Pastdagi + tugmasi orqali qo\'shing'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recurrences.length,
                    itemBuilder: (context, index) {
                      final r = recurrences[index];
                      final cat = categories.firstWhere((c) => c.id == r.categoryId, orElse: () => categories.first);
                      final color = Color(cat.colorValue);
                      final next = _nextOccurrence(r);

                      return FadeInItem(
                        index: index,
                        child: AppCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          tint: color,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CategoryAvatar(category: cat),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.source ?? cat.name, style: Theme.of(context).textTheme.titleMedium),
                                        Text('${_frequencyLabel(r.frequency)} • ${NumberFormat("#,##0").format(r.amount)} so\'m', style: Theme.of(context).textTheme.labelSmall),
                                      ],
                                    ),
                                  ),
                                  Switch(value: r.isActive, onChanged: (v) async {
                                    await ref.read(recurringProvider.notifier).toggleActive(r, v);
                                    await scheduleRecurringNotification(r);
                                  }),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.event_repeat_rounded, size: 14, color: AppTheme.mutedText(context)),
                                      const SizedBox(width: 4),
                                      Text(r.isActive ? 'Keyingisi: ${DateFormat('dd.MM.yyyy HH:mm').format(next)}' : 'To\'xtatilgan', style: Theme.of(context).textTheme.labelSmall),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: AppTheme.brandPrimary(context)), onPressed: () => _openSheet(context, existing: r), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                      const SizedBox(width: 16),
                                      IconButton(icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.brandExpense(context)), onPressed: () => _confirmDelete(context, ref, r.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openSheet(context), icon: const Icon(Icons.add), label: const Text("Qo'shish")),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("O'chirish"),
        content: const Text('Bu takrorlanuvchi qoidani o\'chirmoqchimisiz? (Avval yaratilgan tranzaksiyalar saqlanib qoladi)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(onPressed: () { NotificationService.cancelById(id.hashCode); ref.read(recurringProvider.notifier).remove(id); Navigator.pop(context); }, child: Text("O'chirish", style: TextStyle(color: AppTheme.brandExpense(context)))),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, {RecurringTransactionModel? existing}) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddRecurringSheet(existing: existing));
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
                Text("Takrorlanish", style: TextStyle(fontWeight: FontWeight.w700, color: onSurface, fontSize: 15)),
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