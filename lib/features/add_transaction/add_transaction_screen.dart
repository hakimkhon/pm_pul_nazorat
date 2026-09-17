import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/thousands_formatter.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String _type = 'expense'; // yoki 'income'
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref
        .watch(categoryProvider)
        .where((c) => c.type == _type)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Yangi tranzaksiya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kirim / Chiqim tanlash
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Chiqim',
                    color: AppTheme.coral,
                    selected: _type == 'expense',
                    onTap: () => setState(() {
                      _type = 'expense';
                      _selectedCategoryId = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Kirim',
                    color: AppTheme.emerald,
                    selected: _type == 'income',
                    onTap: () => setState(() {
                      _type = 'income';
                      _selectedCategoryId = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
                decoration: InputDecoration(
                  labelText: 'Summa',
                  suffixText: "so'm",
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bo'lim tanlash
            const Text(
              'Bo\'lim',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                final selected = c.id == _selectedCategoryId;
                return ChoiceChip(
                  label: Text(c.name),
                  selected: selected,
                  selectedColor: Color(c.colorValue).withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Sana
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sana'),
              subtitle: Text(
                '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const SizedBox(height: 8),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vaqt'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),
            const SizedBox(height: 8),

            // Manba (qayerdan/qayerga)
            TextField(
              controller: _sourceController,
              decoration: InputDecoration(
                labelText: _type == 'income'
                    ? 'Qayerdan keldi (masalan: Ish haqi)'
                    : 'Qayerga sarflandi (masalan: Do\'kon)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Izoh
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Izoh (ixtiyoriy)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'income'
                      ? AppTheme.income
                      : AppTheme.expense,
                ),
                child: const Text(
                  'Saqlash',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    final amount = ThousandsFormatter.parse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Iltimos, to'g'ri summa kiriting")),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Iltimos, bo'limni tanlang")),
      );
      return;
    }

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      type: _type,
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      source: _sourceController.text.trim().isEmpty
          ? null
          : _sourceController.text.trim(),
    );

    ref.read(transactionProvider.notifier).addTransaction(transaction);
    Navigator.of(context).pop();
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
