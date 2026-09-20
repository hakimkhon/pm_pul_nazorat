import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../add_transaction/add_transaction_screen.dart';
import '../recurring/recurring_screen.dart';
import '../notifications/notifications_screen.dart';
import '../debts/debt_screen.dart';

void _confirmDeleteTransaction(BuildContext context, WidgetRef ref, String id) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("O'chirish"),
      content: const Text("Bu tranzaksiyani o'chirmoqchimisiz?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Bekor qilish'),
        ),
        TextButton(
          onPressed: () {
            ref.read(transactionProvider.notifier).deleteTransaction(id);
            Navigator.pop(dialogContext);
          },
          child: Text(
            "O'chirish",
            style: TextStyle(color: AppTheme.brandExpense(context)),
          ),
        ),
      ],
    ),
  );
}

const List<String> uzMonths = [
  'Yanvar',
  'Fevral',
  'Mart',
  'Aprel',
  'May',
  'Iyun',
  'Iyul',
  'Avgust',
  'Sentabr',
  'Oktabr',
  'Noyabr',
  'Dekabr',
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  double _slideDir = 1;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _goPrev() {
    setState(() {
      _slideDir = -1;
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
  }

  void _goNext() {
    if (_isCurrentMonth) return;
    setState(() {
      _slideDir = 1;
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      1,
    ).subtract(const Duration(seconds: 1));

    final monthTransactions = transactions
        .where(
          (t) =>
              t.date.year == _selectedMonth.year &&
              t.date.month == _selectedMonth.month,
        )
        .toList();
    final monthIncome = monthTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final monthExpense = monthTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final carryover = transactions
        .where((t) => !t.date.isAfter(monthEnd))
        .fold(0.0, (s, t) => s + (t.type == 'income' ? t.amount : -t.amount));

    final priorTransactions = transactions
        .where((t) => t.date.isBefore(startOfMonth))
        .toList();
    final hasPriorData = priorTransactions.isNotEmpty;
    final previousBalance = priorTransactions.fold(
      0.0,
      (s, t) => s + (t.type == 'income' ? t.amount : -t.amount),
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.brandPrimary(context),
          onRefresh: () async =>
              ref.read(transactionProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(),
              const SizedBox(height: 20),
              _BalanceCard(
                selectedMonth: _selectedMonth,
                isCurrentMonth: _isCurrentMonth,
                carryover: carryover,
                monthIncome: monthIncome,
                monthExpense: monthExpense,
                canGoNext: !_isCurrentMonth,
                slideDir: _slideDir,
                onPrev: _goPrev,
                onNext: _goNext,
              ),
              const SizedBox(height: 20),
              SectionTitle(
                '${uzMonths[_selectedMonth.month - 1]} oyidagi tranzaksiyalar',
                trailing: monthTransactions.isNotEmpty
                    ? Text(
                        '${monthTransactions.length} ta',
                        style: Theme.of(context).textTheme.labelSmall,
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              if (hasPriorData)
                FadeInItem(
                  index: 0,
                  child: _PreviousBalanceTile(amount: previousBalance),
                ),
              if (monthTransactions.isEmpty && !hasPriorData)
                const EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: "Hozircha tranzaksiya yo'q",
                  subtitle: "Pastdagi + tugmasi orqali qo'shing",
                )
              else if (monthTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: "Bu oyda tranzaksiya yo'q",
                  ),
                )
              else
                ...List.generate(monthTransactions.length, (index) {
                  final t = monthTransactions[index];
                  final cat = categories.firstWhere(
                    (c) => c.id == t.categoryId,
                    orElse: () => categories.first,
                  );
                  return FadeInItem(
                    index: index + 1,
                    child: TransactionTile(
                      transaction: t,
                      category: cat,
                      showCategoryAsSubtitle: true,
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(existing: t),
                        ),
                      ),
                      onDelete: () =>
                          _confirmDeleteTransaction(context, ref, t.id),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xush kelibsiz',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'PulNazorat',
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            _HeaderIcon(
              icon: Icons.notifications_none_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: Icons.handshake_outlined,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DebtScreen())),
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: Icons.autorenew_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecurringScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.softShadow(opacity: 0.05),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 22,
        ),
      ),
    );
  }
}

class _PreviousBalanceTile extends StatelessWidget {
  final double amount;
  const _PreviousBalanceTile({required this.amount});

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    final color = isPositive
        ? AppTheme.brandIncome(context)
        : AppTheme.brandExpense(context);
    final sign = isPositive ? '+' : '-';

    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      tint: color,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "O'tgan oydan qolgan balans",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '$sign${NumberFormat("#,##0").format(amount.abs())}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final DateTime selectedMonth;
  final bool isCurrentMonth;
  final double carryover;
  final double monthIncome;
  final double monthExpense;
  final bool canGoNext;
  final double slideDir;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _BalanceCard({
    required this.selectedMonth,
    required this.isCurrentMonth,
    required this.carryover,
    required this.monthIncome,
    required this.monthExpense,
    required this.canGoNext,
    required this.slideDir,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // Joriy oyda "kelasi oyga o'tadigan mablag'", o'tgan oylarda esa doimiy "mavjud mablag'" yozuvi
    final label = isCurrentMonth
        ? "Oy oxiriga\nqolgan mablag'"
        : "Shu oy oxiridagi\nmavjud mablag'";

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandPrimary(context),
            AppTheme.brandPrimary(context).withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow(opacity: 0.18),
      ),
      child: Stack(
        children: [
          // ---- Dekorativ fon: to'lqin chiziqlar + tanga shakllari (Visualizer'da loyihalashtirilgan) ----
          Positioned.fill(child: CustomPaint(painter: _WavePatternPainter())),
          Positioned(
            right: -10,
            top: -10,
            child: _CoinShape(size: 90, label: '\$', opacity: 0.10),
          ),
          Positioned(
            left: -6,
            bottom: -6,
            child: _CoinShape(size: 70, label: "so'm", opacity: 0.12),
          ),
          Positioned(right: 70, bottom: 20, child: _Dot(size: 14)),
          Positioned(right: 30, bottom: 50, child: _Dot(size: 10)),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ArrowButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: onPrev,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) {
                            final offset = Tween<Offset>(
                              begin: Offset(slideDir * 0.4, 0),
                              end: Offset.zero,
                            ).animate(animation);
                            return SlideTransition(
                              position: offset,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            '${uzMonths[selectedMonth.month - 1]} ${selectedMonth.year}',
                            key: ValueKey(
                              '${selectedMonth.year}-${selectedMonth.month}',
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ArrowButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: canGoNext ? onNext : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            tween: Tween(begin: 0, end: carryover),
                            builder: (context, v, _) => FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                NumberFormat('#,##0').format(v),
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "so'm",
                            style: TextStyle(
                              color: AppTheme.expense,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ContrastStatChip(
                        label: 'Bu oy kirim',
                        value: monthIncome,
                        color: AppTheme.emerald,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 34,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ContrastStatChip(
                        label: 'Bu oy chiqim',
                        value: monthExpense,
                        color: AppTheme.coral,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Balans kartasi fonidagi to'lqinsimon chiziqlar (Visualizer'da loyihalashtirilgan naqsh asosida)
class _WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final yOffset in [0.25, 0.42, 0.6]) {
      final path = Path();
      final baseY = size.height * yOffset;
      path.moveTo(-20, baseY);
      path.quadraticBezierTo(
        size.width * 0.25,
        baseY - 24,
        size.width * 0.5,
        baseY,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        baseY + 24,
        size.width + 20,
        baseY,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoinShape extends StatelessWidget {
  final double size;
  final String label;
  final double opacity;
  const _CoinShape({
    required this.size,
    required this.label,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity * 4),
          fontSize: size * 0.26,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  const _Dot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: disabled ? 0.06 : 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: disabled ? 0.3 : 1),
          size: 26,
        ),
      ),
    );
  }
}
