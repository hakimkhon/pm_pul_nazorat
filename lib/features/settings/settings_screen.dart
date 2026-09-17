import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/settings_provider.dart';
import '../../data/notification_service.dart';
import '../../core/theme/app_theme.dart';
import 'backup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final reminder = ref.watch(reminderProvider);
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: AbsorbPointer(
        absorbing: _loading,
        child: Opacity(
          opacity: _loading ? 0.5 : 1,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- Profil ----
              GestureDetector(
                onTap: () => _editName(userName),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.brandPrimary(context),
                        AppTheme.brandPrimary(context).withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isNotEmpty
                                  ? userName
                                  : 'Ismingizni kiriting',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'PulNazorat foydalanuvchisi',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              _SectionTitle('Ko\'rinish'),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mavzu (tema)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _SegmentedRow(
                      options: const {
                        'Tizim': ThemeMode.system,
                        'Yorug\'': ThemeMode.light,
                        'Qorong\'i': ThemeMode.dark,
                      },
                      selected: themeMode,
                      onSelect: (m) =>
                          ref.read(themeModeProvider.notifier).setMode(m),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Shrift o\'lchami',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _SegmentedRow(
                      options: const {
                        'Kichik': 0.9,
                        'O\'rta': 1.0,
                        'Katta': 1.15,
                        'Juda katta': 1.3,
                      },
                      selected: fontScale,
                      onSelect: (s) =>
                          ref.read(fontScaleProvider.notifier).setScale(s),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              _SectionTitle('Bildirishnomalar'),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kunlik eslatma',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                reminder.enabled
                                    ? 'Har kuni ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}da'
                                    : 'O\'chirilgan',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: reminder.enabled,
                          onChanged: (value) => _run(() async {
                            if (value) {
                              await NotificationService.requestPermission();
                              await NotificationService.scheduleDailyReminder(
                                hour: reminder.hour,
                                minute: reminder.minute,
                              );
                            } else {
                              await NotificationService.cancelDailyReminder();
                            }
                            ref
                                .read(reminderProvider.notifier)
                                .update(enabled: value);
                          }),
                        ),
                      ],
                    ),
                    if (reminder.enabled) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _pickReminderTime(reminder),
                          icon: const Icon(Icons.access_time, size: 18),
                          label: const Text('Vaqtni o\'zgartirish'),
                        ),
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Byudjet ogohlantirishlari',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Limitning 80%/100%iga yetganda xabar bering',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: ref.watch(budgetAlertsEnabledProvider),
                          onChanged: (v) => ref
                              .read(budgetAlertsEnabledProvider.notifier)
                              .setValue(v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              _SectionTitle('Ma\'lumotlar'),
              _Tile(
                icon: Icons.cloud_sync_outlined,
                iconColor: AppTheme.brandPrimary(context),
                title: 'Zaxira nusxa va tiklash',
                subtitle: 'Eksport/import — JSON, Excel',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                ),
              ),
              _Tile(
                icon: Icons.delete_forever_outlined,
                iconColor: AppTheme.brandExpense(context),
                title: 'Barcha ma\'lumotlarni tozalash',
                subtitle: 'Diqqat: qaytarib bo\'lmaydi',
                onTap: _confirmClearAll,
              ),
              const SizedBox(height: 8),

              _SectionTitle('Til'),
              _Tile(
                icon: Icons.language,
                iconColor: AppTheme.brandGold(context),
                title: 'Til',
                subtitle: 'O\'zbekcha',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hozircha faqat o\'zbek tili mavjud'),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              _SectionTitle('Dastur haqida'),
              _Tile(
                icon: Icons.share_outlined,
                iconColor: AppTheme.brandPrimary(context),
                title: 'Do\'stlarga ulashish',
                subtitle: 'PulNazorat ilovasini tavsiya qilish',
                onTap: () => Share.share(
                  'PulNazorat — shaxsiy moliyani boshqarish ilovasi. Sinab ko\'ring!',
                ),
              ),
              _Tile(
                icon: Icons.star_border_rounded,
                iconColor: AppTheme.brandGold(context),
                title: 'Ilovani baholash',
                subtitle: 'Fikr-mulohaza qoldiring',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Play Store havolasi tez orada qo\'shiladi'),
                  ),
                ),
              ),
              _Tile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.grey,
                title: 'Maxfiylik siyosati',
                subtitle: 'Ma\'lumotlar qanday saqlanadi',
                onTap: () => _showInfoDialog(
                  'Maxfiylik siyosati',
                  'PulNazorat barcha ma\'lumotlaringizni FAQAT sizning qurilmangizda saqlaydi. '
                      'Hech qanday ma\'lumot serverga yuborilmaydi. Eksport qilingan zaxira nusxalar '
                      'faqat siz ulashgan joyda saqlanadi.',
                ),
              ),
              _Tile(
                icon: Icons.description_outlined,
                iconColor: Colors.grey,
                title: 'Foydalanish shartlari',
                subtitle: '',
                onTap: () => _showInfoDialog(
                  'Foydalanish shartlari',
                  'PulNazorat shaxsiy moliyani kuzatish uchun mo\'ljallangan yordamchi vositadir. '
                      'Moliyaviy qarorlar uchun mustaqil javobgarlik foydalanuvchi zimmasida qoladi.',
                ),
              ),
              _Tile(
                icon: Icons.mail_outline,
                iconColor: AppTheme.brandIncome(context),
                title: 'Yordam va aloqa',
                subtitle: 'Dasturchi bilan bog\'lanish',
                onTap: _showDeveloperInfo,
              ),
              _Tile(
                icon: Icons.info_outline,
                iconColor: Colors.grey,
                title: 'PulNazorat',
                subtitle: 'Versiya 1.0.0',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReminderTime(ReminderSettings reminder) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );
    if (time == null) return;
    await _run(() async {
      await NotificationService.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
      );
      ref
          .read(reminderProvider.notifier)
          .update(hour: time.hour, minute: time.minute);
    });
  }

  void _editName(String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ismingiz'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Ism'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(userNameProvider.notifier)
                  .setName(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diqqat!'),
        content: const Text(
          'Barcha bo\'lim, tranzaksiya va byudjetlar butunlay o\'chib ketadi. Bu amalni ORTGA QAYTARIB bo\'lmaydi. Davom etasizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu funksiya keyingi bosqichda ulanadi'),
                ),
              );
            },
            child: Text(
              'Tozalash',
              style: TextStyle(color: AppTheme.brandExpense(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloperInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Dasturchi haqida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ushbu dastur Sharifxonov Hakimxon tomonidan ishlab chiqilgan.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _ContactRow(
              icon: Icons.telegram,
              label: 'Telegram',
              value: '@Abduhamidxonovich',
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: Icons.phone_outlined,
              label: 'Telefon',
              value: '+998 93 567 55 20',
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'hakimkhon1994@gmail.com',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label nusxalandi: $value')));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.brandPrimary(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_outlined, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final Map<String, T> options;
  final T selected;
  final void Function(T) onSelect;

  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final isSelected = entry.value == selected;
        return GestureDetector(
          onTap: () => onSelect(entry.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.brandPrimary(context)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.key,
              style: TextStyle(
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkBg
                          : Colors.white)
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.14),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: Theme.of(context).textTheme.labelSmall)
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: Colors.grey)
            : null,
        onTap: onTap,
      ),
    );
  }
}
