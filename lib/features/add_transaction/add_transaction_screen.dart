import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../core/utils/budget_alert_checker.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late String _type;
  late final TextEditingController _amountController;
  late final TextEditingController _sourceController;
  late final TextEditingController _noteController;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'expense';
    _amountController = TextEditingController(text: e != null ? NumberFormat("#,##0").format(e.amount) : '');
    _sourceController = TextEditingController(text: e?.source ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _selectedCategoryId = e?.categoryId;
    _selectedDate = e?.date ?? DateTime.now();
    _selectedTime = e != null ? TimeOfDay.fromDateTime(e.date) : TimeOfDay.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider).where((c) => c.type == _type).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Tranzaksiyani tahrirlash' : 'Yangi tranzaksiya')),
      // ---- Asosiy forma: scroll qilinadigan qism ----
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _TypeButton(label: 'Chiqim', color: AppTheme.brandExpense(context), selected: _type == 'expense', onTap: () => setState(() { _type = 'expense'; _selectedCategoryId = null; }))),
                  const SizedBox(width: 12),
                  Expanded(child: _TypeButton(label: 'Kirim', color: AppTheme.brandIncome(context), selected: _type == 'income', onTap: () => setState(() { _type = 'income'; _selectedCategoryId = null; }))),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Summa', suffixText: "so'm"),
              ),
              const SizedBox(height: 16),

              Text('Bo\'lim', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: categories.map((c) {
                  final catColor = Color(c.colorValue);
                  final selected = c.id == _selectedCategoryId;
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: selected,
                    showCheckmark: false,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    selectedColor: catColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(color: selected ? catColor : Colors.transparent),
                    onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sana'),
                subtitle: Text('${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vaqt'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                  if (picked != null) setState(() => _selectedTime = picked);
                },
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _sourceController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(labelText: _type == 'income' ? 'Qayerdan keldi (masalan: Ish haqi)' : 'Qayerga sarflandi (masalan: Do\'kon)'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _noteController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12), // Pastdagi tugma bilan urilib qolmasligi uchun kichik bo'shliq
            ],
          ),
        ),
      ),
      // ---- Saqlash tugmasi: HAR DOIM ekranning pastida, kontent qanchalik ko'p bo'lmasin ----
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(backgroundColor: _type == 'income' ? AppTheme.brandIncome(context) : AppTheme.brandExpense(context)),
              child: Text(widget.existing != null ? 'Saqlash' : 'Saqlash', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }

  void _saveTransaction() async {
    final amount = ThousandsFormatter.parse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Iltimos, to'g'ri summa kiriting")));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Iltimos, bo'limni tanlang")));
      return;
    }

    final transaction = TransactionModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      type: _type,
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      source: _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
    );

    if (widget.existing != null) {
      ref.read(transactionProvider.notifier).updateTransaction(transaction);
    } else {
      ref.read(transactionProvider.notifier).addTransaction(transaction);
    }

    if (_type == 'expense') {
      await checkBudgetAlerts(ref);
    }

    if (mounted) Navigator.of(context).pop();
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))] : [],
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w700, fontSize: 15),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}