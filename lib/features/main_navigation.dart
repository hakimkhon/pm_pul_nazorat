import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/statistics/statistics_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/add_transaction/add_transaction_screen.dart';
import '../core/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  void _openAdd() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => const AddTransactionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).cardColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Bosh sahifa', selected: _index == 0, onTap: () => setState(() => _index = 0)),
            _NavItem(icon: Icons.category_outlined, activeIcon: Icons.category, label: "Bo'limlar", selected: _index == 1, onTap: () => setState(() => _index = 1)),
            const SizedBox(width: 48), // FAB uchun bo'sh joy
            _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Statistika', selected: _index == 2, onTap: () => setState(() => _index = 2)),
            _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Sozlamalar', selected: _index == 3, onTap: () => setState(() => _index = 3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.brandPrimary(context) : AppTheme.mutedText(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}