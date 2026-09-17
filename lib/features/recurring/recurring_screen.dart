import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/recurring_transaction_model.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../core/theme/app_theme.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurrences = ref.watch(recurringProvider);
    final categories = ref.watch(categoryProvider);

    String categoryName(String id) =>
        categories.firstWhere((c) => c.id == id, orElse: () => categories.first).name;

    return Scaffold(
      appBar: AppBar(title: const Text('Takrorlanuvchi tranzaksiyalar')),
      body: recurrences.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew_rounded, size: 48, color: AppTheme.brandGold(context)),
                    const SizedBox(height: 12),
                    Text(
                      "Hali takrorlanuvchi tranzaksiya yo'q.\nMasalan: oylik ish haqi yoki kommunal to'lov.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recurrences.length,
              itemBuilder: (context, index) {
                final r = recurrences[index];
                final cat = categories.firstWhere((c) => c.id == r.categoryId, orElse: () => categories.first);
                final color = Color(cat.colorValue);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.14),
                        child: Icon(IconHelper.getIcon(cat.iconCode), color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.source ?? categoryName(r.categoryId), style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              '${_frequencyLabel(r.frequency)} • ${NumberFormat("#,##0").format(r.amount)} so\'m',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: r.isActive,
                        onChanged: (v) => ref.read(recurringProvider.notifier).toggleActive(r, v),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppTheme.brandExpense(context)),
                        onPressed: () => _confirmDelete(context, ref, r.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text("Qo'shish"),
      ),
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
          TextButton(
            onPressed: () {
              ref.read(recurringProvider.notifier).remove(id);
              Navigator.pop(context);
            },
            child: Text("O'chirish", style: TextStyle(color: AppTheme.brandExpense(context))),
          ),
        ],
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRecurringSheet(),
    );
  }
}

class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet();

  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  String _type = 'expense';
  String _frequency = 'monthly';
  String? _categoryId;
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider).where((c) => c.type == _type).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Yangi takrorlanuvchi qoida", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Chiqim'),
                      selected: _type == 'expense',
                      onSelected: (_) => setState(() { _type = 'expense'; _categoryId = null; }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Kirim'),
                      selected: _type == 'income',
                      onSelected: (_) => setState(() { _type = 'income'; _categoryId = null; }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                decoration: const InputDecoration(labelText: 'Summa', suffixText: "so'm"),
              ),
              const SizedBox(height: 16),

              Text("Bo'lim", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((c) {
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: c.id == _categoryId,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Text("Takrorlanish", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('Har kuni'), selected: _frequency == 'daily', onSelected: (_) => setState(() => _frequency = 'daily')),
                  ChoiceChip(label: const Text('Har hafta'), selected: _frequency == 'weekly', onSelected: (_) => setState(() => _frequency = 'weekly')),
                  ChoiceChip(label: const Text('Har oy'), selected: _frequency == 'monthly', onSelected: (_) => setState(() => _frequency = 'monthly')),
                ],
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Boshlanish sanasi'),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),

              TextField(
                controller: _sourceController,
                decoration: const InputDecoration(labelText: 'Nomi (masalan: Ish haqi, Kommunal)'),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(onPressed: _save, child: const Text('Saqlash')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final amount = ThousandsFormatter.parse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Iltimos, to'g'ri summa kiriting")));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bo'limni tanlang")));
      return;
    }

    final model = RecurringTransactionModel(
      id: const Uuid().v4(),
      amount: amount,
      categoryId: _categoryId!,
      type: _type,
      frequency: _frequency,
      startDate: _startDate,
      lastGeneratedDate: _startDate.subtract(const Duration(days: 1)), // birinchi generatsiya darrov ishlashi uchun
      source: _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
    );

    ref.read(recurringProvider.notifier).add(model);
    Navigator.pop(context);
  }
}