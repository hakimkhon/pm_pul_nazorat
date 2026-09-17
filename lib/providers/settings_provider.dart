import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/hive_service.dart';

final settingsBoxProvider = Provider<Box>((ref) => Hive.box(HiveService.settingsBox));

// ---------------- Tema rejimi ----------------
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Box box;
  ThemeModeNotifier(this.box) : super(_load(box));

  static ThemeMode _load(Box box) {
    final value = box.get('themeMode', defaultValue: 'system');
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setMode(ThemeMode mode) {
    state = mode;
    box.put('themeMode', mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(settingsBoxProvider));
});

// ---------------- Shrift o'lchami ----------------
// 0.9 = Kichik, 1.0 = O'rta, 1.15 = Katta, 1.3 = Juda katta
class FontScaleNotifier extends StateNotifier<double> {
  final Box box;
  FontScaleNotifier(this.box) : super((box.get('fontScale', defaultValue: 1.0) as num).toDouble());

  void setScale(double scale) {
    state = scale;
    box.put('fontScale', scale);
  }
}

final fontScaleProvider = StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier(ref.read(settingsBoxProvider));
});

// ---------------- Kunlik eslatma sozlamalari ----------------
class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;
  const ReminderSettings({required this.enabled, required this.hour, required this.minute});
}

class ReminderNotifier extends StateNotifier<ReminderSettings> {
  final Box box;
  ReminderNotifier(this.box)
      : super(ReminderSettings(
          enabled: box.get('reminderEnabled', defaultValue: false),
          hour: box.get('reminderHour', defaultValue: 20),
          minute: box.get('reminderMinute', defaultValue: 0),
        ));

  void update({bool? enabled, int? hour, int? minute}) {
    state = ReminderSettings(
      enabled: enabled ?? state.enabled,
      hour: hour ?? state.hour,
      minute: minute ?? state.minute,
    );
    box.put('reminderEnabled', state.enabled);
    box.put('reminderHour', state.hour);
    box.put('reminderMinute', state.minute);
  }
}

final reminderProvider = StateNotifierProvider<ReminderNotifier, ReminderSettings>((ref) {
  return ReminderNotifier(ref.read(settingsBoxProvider));
});

// ---------------- Foydalanuvchi ismi ----------------
class UserNameNotifier extends StateNotifier<String> {
  final Box box;
  UserNameNotifier(this.box) : super(box.get('userName', defaultValue: ''));

  void setName(String name) {
    state = name;
    box.put('userName', name);
  }
}

final userNameProvider = StateNotifierProvider<UserNameNotifier, String>((ref) {
  return UserNameNotifier(ref.read(settingsBoxProvider));
});

// ---------------- Byudjet ogohlantirishlarini yoqish/o'chirish ----------------
class BoolSettingNotifier extends StateNotifier<bool> {
  final Box box;
  final String key;
  BoolSettingNotifier(this.box, this.key, bool defaultValue) : super(box.get(key, defaultValue: defaultValue));

  void setValue(bool value) {
    state = value;
    box.put(key, value);
  }
}

final budgetAlertsEnabledProvider = StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier(ref.read(settingsBoxProvider), 'budgetAlertsEnabled', true);
});