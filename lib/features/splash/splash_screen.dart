import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/recurring_generator.dart';
import '../../core/utils/debt_alert_checker.dart';
import '../main_navigation.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    // Ilova ochilganda muddati kelgan takrorlanuvchi tranzaksiyalarni yaratamiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      generateDueRecurringTransactions(ref);
      checkDebtOverdueAlerts(ref);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.deepTeal,
      body: FadeTransition(
        opacity: _fadeController,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Lottie.asset(
                  'assets/animations/splash.json',
                  repeat: false,
                  onLoaded: (composition) {
                    // Animatsiya tugagach, ozgina kutib, bosh sahifaga o'tamiz
                    Future.delayed(composition.duration + const Duration(milliseconds: 300), _goNext);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Agar animatsiya fayli topilmasa — 1.2s kutib, oddiy o'tish
                    Future.delayed(const Duration(milliseconds: 1200), _goNext);
                    return Icon(Icons.savings_rounded, color: AppTheme.goldBright, size: 90);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'PulNazorat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pulingiz nazoratingiz ostida',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}