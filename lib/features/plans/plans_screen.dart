import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  String _periodType = 'daily';

  @override
  Widget build(BuildContext context) {
    final allPlans = ref.watch(planProvider);
    final list = allPlans.where((p) => p.periodType == _periodType).toList()
      ..sort((a, b) {
        if (a.status == 'done' && b.status != 'done') return 1;
        if (a.status != 'done' && b.status == 'done') return -1;
        return b.date.compareTo(a.date);
      });

    final doneCount = list.where((p) => p.status == 'done').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Rejalar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: EqualSegmentedBar<String>(
              options: const {'Kunlik': 'daily', 'Haftalik': 'weekly', 'Oylik': 'monthly'},
              selected: _periodType,
              onSelect: (v) => setState(() => _periodType = v),
            ),
          ),
          if (list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bajarilgan: $doneCount / ${list.length}', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(
                      width: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: list.isEmpty ? 0 : doneCount / list.length, minHeight: 6, backgroundColor: AppTheme.brandIncome(context).withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation(AppTheme.brandIncome(context))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(icon: Icons.checklist_rounded, title: "Hali reja yo'q", subtitle: 'Pastdagi + tugmasi orqali qo\'shing'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: list.length,
                    itemBuilder: (context, index) => FadeInItem(index: index, child: _PlanTile(plan: list[index])),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openAddSheet(context, _periodType), icon: const Icon(Icons.add), label: const Text("Qo'shish")),
    );
  }

  void _openAddSheet(BuildContext context, String periodType) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddPlanSheet(initialPeriodType: periodType));
  }
}

class _PlanTile extends ConsumerWidget {
  final PlanModel plan;
  const _PlanTile({required this.plan});

  Color _statusColor(BuildContext context) {
    switch (plan.status) {
      case 'done': return AppTheme.brandIncome(context);
      case 'inProgress': return AppTheme.brandGold(context);
      case 'notDone': return AppTheme.brandExpense(context);
      default: return AppTheme.mutedText(context);
    }
  }

  String _statusLabel() {
    switch (plan.status) {
      case 'done': return 'Bajarildi';
      case 'inProgress': return 'Jarayonda';
      case 'notDone': return 'Bajarilmadi';
      default: return 'Kutilmoqda';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: plan.status == 'done' ? TextDecoration.lineThrough : null,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                child: Text(_statusLabel(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => ref.read(planProvider.notifier).remove(plan.id)),
            ],
          ),
          if (plan.note != null && plan.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(plan.note!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(DateFormat('dd.MM.yyyy').format(plan.date), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          // ---- Tezkor amal tugmalari ----
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickButton(label: 'Bajarildi', icon: Icons.check_circle_outline, color: AppTheme.brandIncome(context), active: plan.status == 'done', onTap: () => ref.read(planProvider.notifier).updateStatus(plan, 'done')),
              _QuickButton(label: 'Jarayonda', icon: Icons.hourglass_bottom_rounded, color: AppTheme.brandGold(context), active: plan.status == 'inProgress', onTap: () => ref.read(planProvider.notifier).updateStatus(plan, 'inProgress')),
              _QuickButton(label: 'Bajarilmadi', icon: Icons.cancel_outlined, color: AppTheme.brandExpense(context), active: plan.status == 'notDone', onTap: () => ref.read(planProvider.notifier).updateStatus(plan, 'notDone')),
              _QuickButton(label: 'Keyinroq eslat', icon: Icons.snooze_rounded, color: AppTheme.mutedText(context), active: false, onTap: () {
                ref.read(planProvider.notifier).snooze(plan, const Duration(hours: 2));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2 soatdan keyin qayta eslatiladi')));
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _QuickButton({required this.label, required this.icon, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: active ? color : color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}

class _AddPlanSheet extends ConsumerStatefulWidget {
  final String initialPeriodType;
  const _AddPlanSheet({required this.initialPeriodType});

  @override
  ConsumerState<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends ConsumerState<_AddPlanSheet> {
  late String _periodType;
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _periodType = widget.initialPeriodType;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yangi reja', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: onSurface)),
                const SizedBox(height: 16),
                TextField(controller: _titleController, style: TextStyle(color: onSurface), decoration: const InputDecoration(labelText: 'Reja nomi')),
                const SizedBox(height: 16),
                TextField(controller: _noteController, style: TextStyle(color: onSurface), decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)'), maxLines: 2),
                const SizedBox(height: 16),
                Text('Turi', style: TextStyle(fontWeight: FontWeight.w700, color: onSurface, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('Kunlik'), selected: _periodType == 'daily', showCheckmark: false, selectedColor: AppTheme.brandPrimary(context), labelStyle: TextStyle(color: _periodType == 'daily' ? Colors.white : onSurface), onSelected: (_) => setState(() => _periodType = 'daily')),
                    ChoiceChip(label: const Text('Haftalik'), selected: _periodType == 'weekly', showCheckmark: false, selectedColor: AppTheme.brandPrimary(context), labelStyle: TextStyle(color: _periodType == 'weekly' ? Colors.white : onSurface), onSelected: (_) => setState(() => _periodType = 'weekly')),
                    ChoiceChip(label: const Text('Oylik'), selected: _periodType == 'monthly', showCheckmark: false, selectedColor: AppTheme.brandPrimary(context), labelStyle: TextStyle(color: _periodType == 'monthly' ? Colors.white : onSurface), onSelected: (_) => setState(() => _periodType = 'monthly')),
                  ],
                ),
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
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _save, child: const Text("Qo'shish"))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reja nomini kiriting')));
      return;
    }
    final plan = PlanModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      periodType: _periodType,
      date: _date,
      createdAt: DateTime.now(),
    );
    ref.read(planProvider.notifier).add(plan);
    Navigator.pop(context);
  }
}