import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/category_model.dart';
import 'add_edit_category_sheet.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final expenseList = categories.where((c) => c.type == 'expense').toList();
    final incomeList = categories.where((c) => c.type == 'income').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bo'limlar"),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGrid ? "Ro'yxat ko'rinishi" : "Grid ko'rinishi",
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, size: 26),
            tooltip: "Yangi bo'lim",
            color: AppTheme.brandPrimary(context),
            onPressed: () => _openAddEditSheet(type: _tabController.index == 0 ? 'expense' : 'income'),
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brandPrimary(context),
          unselectedLabelColor: AppTheme.mutedText(context),
          indicatorColor: AppTheme.brandGold(context),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [Tab(text: 'Chiqim'), Tab(text: 'Kirim')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryListOrGrid(categories: expenseList, isGrid: _isGrid),
          _CategoryListOrGrid(categories: incomeList, isGrid: _isGrid),
        ],
      ),
    );
  }

  void _openAddEditSheet({CategoryModel? existing, required String type}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditCategorySheet(existing: existing, type: type),
    );
  }
}

/// Bir xil ma'lumotni ikki xil ko'rinishda (grid/list) chiqaradi
class _CategoryListOrGrid extends ConsumerWidget {
  final List<CategoryModel> categories;
  final bool isGrid;
  const _CategoryListOrGrid({required this.categories, required this.isGrid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return const EmptyState(icon: Icons.category_outlined, title: "Bo'limlar mavjud emas");
    }
    final budgets = ref.watch(budgetProvider);
    double? limitFor(String categoryId) {
      try {
        return budgets.firstWhere((b) => b.categoryId == categoryId).monthlyLimit;
      } catch (_) {
        return null;
      }
    }

    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 3 / 2),
        itemCount: categories.length,
        itemBuilder: (context, index) => FadeInItem(
          index: index, slideUp: false,
          child: _CategoryGridTile(category: categories[index], budgetLimit: limitFor(categories[index].id)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) => FadeInItem(
        index: index,
        child: _CategoryListTile(category: categories[index], budgetLimit: limitFor(categories[index].id)),
      ),
    );
  }
}

class _CategoryGridTile extends StatefulWidget {
  final CategoryModel category;
  final double? budgetLimit;
  const _CategoryGridTile({required this.category, this.budgetLimit});

  @override
  State<_CategoryGridTile> createState() => _CategoryGridTileState();
}

class _CategoryGridTileState extends State<_CategoryGridTile> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: c))),
      onLongPress: () => showCategoryOptions(context, c),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          tint: Color(c.colorValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryAvatar(category: c, radius: 16, iconSize: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(c.isDefault ? 'Standart' : 'Uzoqroq bosing', style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (widget.budgetLimit != null)
                    Text(NumberFormat.compact().format(widget.budgetLimit), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.brandGold(context))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  final CategoryModel category;
  final double? budgetLimit;
  const _CategoryListTile({required this.category, this.budgetLimit});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 10),
      tint: Color(category.colorValue),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: category))),
        onLongPress: () => showCategoryOptions(context, category),
        leading: CategoryAvatar(category: category),
        title: Text(category.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(category.isDefault ? 'Standart bo\'lim' : 'Foydalanuvchi bo\'limi', style: Theme.of(context).textTheme.labelSmall),
        trailing: budgetLimit != null
            ? Text('${NumberFormat.compact().format(budgetLimit)} so\'m', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.brandGold(context)))
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

// ==================== UMUMIY: uzoq bosish menyusi (Consumer ichida chaqiriladi) ====================
void showCategoryOptions(BuildContext context, CategoryModel category) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge))),
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        double? limit;
        try {
          limit = ref.watch(budgetProvider).firstWhere((b) => b.categoryId == category.id).monthlyLimit;
        } catch (_) {
          limit = null;
        }
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: AppTheme.brandPrimary(context)),
                title: const Text("Tahrirlash"),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                    builder: (_) => AddEditCategorySheet(existing: category, type: category.type),
                  );
                },
              ),
              if (category.type == 'expense')
                ListTile(
                  leading: Icon(Icons.pie_chart_outline, color: AppTheme.brandGold(context)),
                  title: Text(limit == null ? 'Byudjet belgilash' : 'Byudjetni tahrirlash'),
                  subtitle: limit != null ? Text('Joriy: ${NumberFormat("#,##0").format(limit)} so\'m/oy') : null,
                  onTap: () {
                    Navigator.pop(context);
                    _showBudgetDialog(context, category, limit);
                  },
                ),
              if (!category.isDefault)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppTheme.brandExpense(context)),
                  title: Text("O'chirish", style: TextStyle(color: AppTheme.brandExpense(context))),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, category);
                  },
                )
              else
                const Padding(padding: EdgeInsets.all(16), child: Text("Standart bo'limlarni o'chirib bo'lmaydi", style: TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          ),
        );
      },
    ),
  );
}

void _showBudgetDialog(BuildContext context, CategoryModel category, double? currentLimit) {
  final controller = TextEditingController(text: currentLimit != null ? NumberFormat("#,##0").format(currentLimit) : '');
  showDialog(
    context: context,
    builder: (dialogContext) => Consumer(
      builder: (context, ref, _) => AlertDialog(
        title: Text('"${category.name}" uchun oylik byudjet'),
        content: TextField(
          controller: controller, keyboardType: TextInputType.number, inputFormatters: [ThousandsFormatter()],
          autofocus: true, decoration: const InputDecoration(labelText: 'Oylik chegara', suffixText: "so'm"),
        ),
        actions: [
          if (currentLimit != null)
            TextButton(
              onPressed: () { ref.read(budgetProvider.notifier).removeBudget(category.id); Navigator.pop(context); },
              child: Text("O'chirish", style: TextStyle(color: AppTheme.brandExpense(context))),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              final value = ThousandsFormatter.parse(controller.text);
              if (value != null && value > 0) ref.read(budgetProvider.notifier).setBudget(category.id, value);
              Navigator.pop(context);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    ),
  );
}

void _confirmDelete(BuildContext context, CategoryModel category) {
  showDialog(
    context: context,
    builder: (dialogContext) => Consumer(
      builder: (context, ref, _) => AlertDialog(
        title: const Text("Bo'limni o'chirish"),
        content: Text('"${category.name}" bo\'limini o\'chirmoqchimisiz?\nBu bo\'limga tegishli tranzaksiyalar saqlanib qoladi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () { ref.read(categoryProvider.notifier).deleteCategory(category.id); Navigator.pop(context); },
            child: Text("O'chirish", style: TextStyle(color: AppTheme.brandExpense(context))),
          ),
        ],
      ),
    ),
  );
}