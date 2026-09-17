import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Android 13+ da bildirishnoma ruxsatini so'rash
  static Future<void> requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Har kuni belgilangan vaqtda "xarajatlarni kiriting" eslatmasi
  static Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await _plugin.zonedSchedule(
      id: 100,
      title: 'Kunlik eslatma',
      body: "Bugungi kirim/chiqimlaringizni PulNazorat'ga kiritishni unutmang 💰",
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Kunlik eslatmalar',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: 100);
  }

  /// Bo'lim byudjetining ma'lum foizi sarflanganda ogohlantirish
  static Future<void> showBudgetAlert(String categoryName, double percent) async {
    await _plugin.show(
      id: categoryName.hashCode,
      title: 'Byudjet ogohlantirishi',
      body: '"$categoryName" bo\'limida byudjetning ${percent.toStringAsFixed(0)}% sarflandi',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alert',
          'Byudjet ogohlantirishlari',
          importance: Importance.high,
        ),
      ),
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}