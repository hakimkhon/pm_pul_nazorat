import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Bildirishnoma tugmasi bosilganda (dastur ochiq/fonda bo'lganda) shu yerga keladi
  static final StreamController<NotificationResponse> responseStream = StreamController.broadcast();

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
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) => responseStream.add(response),
    );
    _initialized = true;
  }

  /// Dastur bildirishnoma tugmasi bosilib OCHILGAN bo'lsa, shu javobni qaytaradi — Splash'da tekshiriladi.
  static Future<NotificationResponse?> getLaunchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      return details.notificationResponse;
    }
    return null;
  }

  static Future<void> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await _plugin.zonedSchedule(
      id: 100,
      title: 'Kunlik eslatma',
      body: "Bugungi kirim/chiqimlaringizni PulNazorat'ga kiritishni unutmang 💰",
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('daily_reminder', 'Kunlik eslatmalar', importance: Importance.defaultImportance),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() async => await _plugin.cancel(id: 100);

  static Future<void> showBudgetAlert(String categoryName, double percent) async {
    await _plugin.show(
      id: categoryName.hashCode,
      title: 'Byudjet ogohlantirishi',
      body: '"$categoryName" bo\'limida byudjetning ${percent.toStringAsFixed(0)}% sarflandi',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('budget_alert', 'Byudjet ogohlantirishlari', importance: Importance.high),
      ),
    );
  }

  static Future<void> showDebtOverdueAlert(String personName, String type, String amountText) async {
    final message = type == 'lent'
        ? '$personName sizga $amountText so\'m qaytarishi kerak edi — muddati o\'tdi'
        : '$personName ga $amountText so\'m to\'lashingiz kerak edi — muddati o\'tdi';
    await _plugin.show(
      id: (personName + type).hashCode,
      title: "Qarz muddati o'tdi",
      body: message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('debt_overdue', 'Qarz ogohlantirishlari', importance: Importance.high),
      ),
    );
  }

  /// Takrorlanuvchi tranzaksiya uchun 3 tugmali tasdiqlash bildirishnomasi.
  /// payload — RecurringTransactionModel.id (harakat qaysi qoidaga tegishli ekanini bilish uchun)
  static Future<void> scheduleRecurringConfirmation({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'recurring_confirm',
        'Takrorlanuvchi tranzaksiya tasdiqlash',
        importance: Importance.max,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction('done', 'Bajarildi', showsUserInterface: false),
          AndroidNotificationAction('snooze', 'Keyinroq (2soat)', showsUserInterface: false),
          AndroidNotificationAction('cancel_action', "Bekor qilish", showsUserInterface: false, cancelNotification: true),
        ],
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        payload: payload,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Aniq vaqt ruxsati yo'q bo'lsa (tizim cheklovi) — taxminiy vaqtda ishlaydigan rejimga o'tamiz
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        payload: payload,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// FAQAT diagnostika uchun: 3 tugmali bildirishnomani DARHOL ko'rsatadi
  /// (rejalashtirish/vaqt bilan bog'liq emas — tugmalar ishlayaptimi, shuni tekshirish uchun)
  static Future<void> showTestRecurringNotification() async {
    await _plugin.show(
      id: 999999,
      title: 'Sinov bildirishnomasi',
      body: 'Agar shu bildirishnomada 3 ta tugma ko\'rinsa — mexanizm ishlayapti ✅',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'recurring_confirm',
          'Takrorlanuvchi tranzaksiya tasdiqlash',
          importance: Importance.max,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction('done', 'Bajarildi', showsUserInterface: false),
            AndroidNotificationAction('snooze', 'Keyinroq (2soat)', showsUserInterface: false),
            AndroidNotificationAction('cancel_action', "Bekor qilish", showsUserInterface: false, cancelNotification: true),
          ],
        ),
      ),
      payload: 'test',
    );
  }

  static Future<void> cancelById(int id) async => await _plugin.cancel(id: id);

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}