import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/debt_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/debt_model.dart';
import '../../models/transaction_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/balance_guard.dart';
import '../../core/utils/debt_category_helper.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/utils/thousands_formatter.dart';
import 'debt_detail_screen.dart';

class DebtScreen extends ConsumerStatefulWidget {
  const DebtScreen({super.key});

  @override
  ConsumerState<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends ConsumerState<DebtScreen> {
  String _selectedType = 'lent';

  @override
  Widget build(BuildContext context) {
    final allDebts = ref.watch(debtProvider);
    final totalOwedToMe = ref.watch(totalOwedToMeProvider);
    final totalIOwe = ref.watch(totalIOweProvider);
    final list = allDebts.where((d) => d.type == _selectedType).toList()
      ..sort((a, b) {
        if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1; // ochiqlar tepada
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1; // muddati o'tganlar birinchi
        return b.date.compareTo(a.date);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Qarz-nasiya')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Menga qarzdorlik', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Text('${NumberFormat("#,##0").format(totalOwedToMe)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.brandIncome(context))),
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
                          Text('Mening qarzim', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Text('${NumberFormat("#,##0").format(totalIOwe)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.brandExpense(context))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: EqualSegmentedBar<String>(
              options: const {'Men bergan': 'lent', 'Men olgan': 'borrowed'},
              selected: _selectedType,
              onSelect: (v) => setState(() => _selectedType = v),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(
                        icon: Icons.handshake_outlined,
                        title: "Hozircha qarz yozuvi yo'q",
                        subtitle: 'Pastdagi + tugmasi orqali qo\'shing',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final d = list[index];
                      return FadeInItem(index: index, child: _DebtTile(debt: d));
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, initialType: _selectedType),
        icon: const Icon(Icons.add),
        label: const Text("Qo'shish"),
      ),
    );
  }

  void _openAddSheet(BuildContext context, {required String initialType}) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddDebtSheet(initialType: initialType));
  }
}

class _DebtTile extends StatelessWidget {
  final DebtModel debt;
  const _DebtTile({required this.debt});

  @override
  Widget build(BuildContext context) {
    final color = debt.isSettled ? AppTheme.mutedText(context) : (debt.isOverdue ? AppTheme.brandExpense(context) : AppTheme.brandPrimary(context));
    final progress = debt.totalAmount == 0 ? 0.0 : (debt.paidAmount / debt.totalAmount).clamp(0, 1).toDouble();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DebtDetailScreen(debtId: debt.id))),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        tint: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.14), child: Icon(debt.type == 'lent' ? Icons.call_made_rounded : Icons.call_received_rounded, color: color, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(debt.personName, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (debt.isSettled)
                            _Badge(text: "To'landi", color: AppTheme.brandIncome(context))
                          else if (debt.isOverdue)
                            _Badge(text: 'Muddati o\'tgan', color: AppTheme.brandExpense(context)),
                        ],
                      ),
                      if (debt.dueDate != null)
                        Text('Muddat: ${DateFormat('dd.MM.yyyy').format(debt.dueDate!)}', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${NumberFormat("#,##0").format(debt.remainingAmount)} so\'m qoldi', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                if (debt.paidAmount > 0) Text('${NumberFormat.compact().format(debt.paidAmount)} / ${NumberFormat.compact().format(debt.totalAmount)}', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            if (debt.paidAmount > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: color.withValues(alpha: 0.12), valueColor: AlwaysStoppedAnimation(color))),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _AddDebtSheet extends ConsumerStatefulWidget {
  final String initialType;
  const _AddDebtSheet({required this.initialType});

  @override
  ConsumerState<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<_AddDebtSheet> {
  late String _type;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

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
                Text('Yangi qarz yozuvi', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: onSurface)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ChoiceChip(label: const Text('Men berdim'), selected: _type == 'lent', showCheckmark: false, selectedColor: AppTheme.brandIncome(context), labelStyle: TextStyle(color: _type == 'lent' ? Colors.white : onSurface, fontWeight: FontWeight.w600), onSelected: (_) => setState(() => _type = 'lent'))),
                    const SizedBox(width: 8),
                    Expanded(child: ChoiceChip(label: const Text('Men oldim'), selected: _type == 'borrowed', showCheckmark: false, selectedColor: AppTheme.brandExpense(context), labelStyle: TextStyle(color: _type == 'borrowed' ? Colors.white : onSurface, fontWeight: FontWeight.w600), onSelected: (_) => setState(() => _type = 'borrowed'))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: _nameController, style: TextStyle(color: onSurface), decoration: const InputDecoration(labelText: 'Ism (kimga/kimdan)')),
                const SizedBox(height: 16),
                TextField(controller: _amountController, keyboardType: TextInputType.number, inputFormatters: [ThousandsFormatter()], style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700), decoration: const InputDecoration(labelText: 'Summa', suffixText: "so'm")),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Sana', style: TextStyle(color: onSurface)),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Qaytarish muddati (ixtiyoriy)', style: TextStyle(color: onSurface)),
                  subtitle: Text(_dueDate != null ? DateFormat('dd.MM.yyyy').format(_dueDate!) : 'Belgilanmagan'),
                  trailing: _dueDate != null
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null))
                      : const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                ),
                TextField(controller: _noteController, style: TextStyle(color: onSurface), decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)'), maxLines: 2),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _save, child: const Text("Qo'shish"))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    final amount = ThousandsFormatter.parse(_amountController.text);
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ismni kiriting')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("To'g'ri summa kiriting")));
      return;
    }

    // "Men berdim" — pul chiqadi (chiqim) => balans yetarli bo'lishi shart
    final isExpense = _type == 'lent';
    if (isExpense) {
      final balance = calculateCurrentBalance(ref);
      if (amount > balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Balansingizda yetarli mablag' yo'q. Joriy balans: ${NumberFormat("#,##0").format(balance)} so'm")),
        );
        return;
      }
    }

    final (expenseCatId, incomeCatId) = await ensureDebtCategories(ref);
    final categoryId = isExpense ? expenseCatId : incomeCatId;

    final txId = const Uuid().v4();
    final tx = TransactionModel(
      id: txId,
      amount: amount,
      categoryId: categoryId,
      type: isExpense ? 'expense' : 'income',
      date: _date,
      source: _nameController.text.trim(),
      note: isExpense ? 'Qarz berildi' : 'Qarz olindi',
    );
    await ref.read(transactionProvider.notifier).addTransaction(tx);

    final debt = DebtModel(
      id: const Uuid().v4(),
      personName: _nameController.text.trim(),
      type: _type,
      totalAmount: amount,
      date: _date,
      dueDate: _dueDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      initialTransactionId: txId,
    );
    await ref.read(debtProvider.notifier).add(debt);
    if (mounted) Navigator.pop(context);
  }
}