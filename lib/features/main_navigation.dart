import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/statistics/statistics_screen.dart';
import '../features/profile/profile_screen.dart';
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
    ProfileScreen(),
  ];

  void _openAdd() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => const AddTransactionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved), child: FadeTransition(opacity: curved, child: child));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: SizedBox(
        width: 62,
        height: 62,
        child: FloatingActionButton(
          backgroundColor: AppTheme.brandGold(context),
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _openAdd,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // SafeArea — FABni telefonning pastki tizim navigatsiya paneli (gesture bar) ustiga ko'taradi
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          color: Theme.of(context).cardColor,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          height: 74,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Bosh sahifa', selected: _index == 0, onTap: () => setState(() => _index = 0)),
              _NavItem(icon: Icons.category_outlined, activeIcon: Icons.category, label: "Bo'limlar", selected: _index == 1, onTap: () => setState(() => _index = 1)),
              const SizedBox(width: 56),
              _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Statistika', selected: _index == 2, onTap: () => setState(() => _index = 2)),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil', selected: _index == 3, onTap: () => setState(() => _index = 3)),
            ],
          ),
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
    // Bottom navigatsiya yorlig'lari shrift o'lchami sozlamasidan mustasno —
    // aks holda "Katta"/"Juda katta" tanlanganda joyga sig'maydi
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? activeIcon : icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}