import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/hive_service.dart';
import 'data/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'providers/settings_provider.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/utils/recurring_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.init();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<NotificationResponse>? _sub;

    @override
  void initState() {
    super.initState();
    _sub = NotificationService.responseStream.stream.listen((response) {
      final payload = response.payload;
      final actionId = response.actionId;
      if (payload != null && actionId != null) {
        handleRecurringAction(ref, payload, actionId);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final launch = await NotificationService.getLaunchResponse();
      if (launch?.payload != null && launch?.actionId != null) {
        await handleRecurringAction(ref, launch!.payload!, launch.actionId!);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp(
      title: 'PulNazorat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Status va navigatsiya panelini joriy temaga moslab, har doim
        // aniq ko'rinadigan qilib qo'yamiz (soat/batareya/bildirishnoma).
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: isDark ? AppTheme.darkBg : Colors.white,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}