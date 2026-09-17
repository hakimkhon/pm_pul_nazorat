import 'dart:convert';
import 'package:hive/hive.dart';
import 'hive_service.dart';

/// Bildirishnomalar tarixini (byudjet ogohlantirishlari) saqlash uchun
/// yengil xotira — alohida Hive model kerak emas, oddiy JSON ro'yxati.
class NotificationHistory {
  static Box get _box => Hive.box(HiveService.settingsBox);
  static const _key = 'notificationHistory';

  static List<Map<String, dynamic>> getAll() {
    final raw = _box.get(_key, defaultValue: '[]') as String;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.reversed.toList(); // eng yangisi tepada
  }

  static Future<void> add(String title, String body) async {
    final raw = _box.get(_key, defaultValue: '[]') as String;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    list.add({'title': title, 'body': body, 'date': DateTime.now().toIso8601String()});
    // Faqat oxirgi 50 tasini saqlaymiz
    final trimmed = list.length > 50 ? list.sublist(list.length - 50) : list;
    await _box.put(_key, jsonEncode(trimmed));
  }

  static Future<void> clear() async {
    await _box.put(_key, '[]');
  }
}