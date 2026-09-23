import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/settings_provider.dart';
import '../../data/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../settings/backup_screen.dart';
import '../plans/plans_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
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
      appBar: AppBar(title: const Text('Profil')),
      body: AbsorbPointer(
        absorbing: _loading,
        child: Opacity(
          opacity: _loading ? 0.5 : 1,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- Profil bosh qismi (doim ko'rinadi) ----
              GestureDetector(
                onTap: () => setState(() {}), // shunchaki placeholder, pastdagi ExpansionTile orqali tahrirlanadi
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.brandPrimary(context), AppTheme.brandPrimary(context).withValues(alpha: 0.75)]),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'P', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName.isNotEmpty ? userName : 'Ismingizni kiriting', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            Text('PulNazorat foydalanuvchisi', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- 1. Profil ma'lumotlari (akkordion — bosilganda pastida ochiladi) ----
              _AccordionCard(
                icon: Icons.person_outline_rounded,
                title: 'Profil ma\'lumotlari',
                iconColor: AppTheme.brandPrimary(context),
                child: _ProfileEditForm(currentName: userName),
              ),

              // ---- 2. Rejalar — bu YANGI SAHIFA talab qiladi ----
              _NavTile(
                icon: Icons.checklist_rounded,
                iconColor: AppTheme.brandGold(context),
                title: 'Rejalar',
                subtitle: 'Kunlik, haftalik, oylik rejalarni boshqarish',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansScreen())),
              ),

              // ---- 3. Bildirishnomalar (akkordion) ----
              _AccordionCard(
                icon: Icons.notifications_none_rounded,
                title: 'Bildirishnomalar',
                iconColor: AppTheme.brandPrimary(context),
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
                              Text('Kunlik eslatma', style: Theme.of(context).textTheme.titleMedium),
                              Text(reminder.enabled ? 'Har kuni ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}da' : 'O\'chirilgan', style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                        Switch(
                          value: reminder.enabled,
                          onChanged: (value) => _run(() async {
                            if (value) {
                              await NotificationService.requestPermission();
                              await NotificationService.scheduleDailyReminder(hour: reminder.hour, minute: reminder.minute);
                            } else {
                              await NotificationService.cancelDailyReminder();
                            }
                            ref.read(reminderProvider.notifier).update(enabled: value);
                          }),
                        ),
                      ],
                    ),
                    if (reminder.enabled)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(onPressed: () => _pickReminderTime(reminder), icon: const Icon(Icons.access_time, size: 18), label: const Text('Vaqtni o\'zgartirish')),
                      ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Byudjet ogohlantirishlari', style: Theme.of(context).textTheme.titleMedium),
                              Text('Limitning 80%/100%iga yetganda xabar bering', style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                        Switch(value: ref.watch(budgetAlertsEnabledProvider), onChanged: (v) => ref.read(budgetAlertsEnabledProvider.notifier).setValue(v)),
                      ],
                    ),
                  ],
                ),
              ),

              // ---- 4. Ma'lumotlarni zahiralash — YANGI SAHIFA talab qiladi ----
              _NavTile(
                icon: Icons.cloud_sync_outlined,
                iconColor: AppTheme.brandPrimary(context),
                title: 'Ma\'lumotlarni zahiralash',
                subtitle: 'Eksport/import — JSON, Excel',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
              ),

              // ---- 5. Ko'rinish sozlamalari (akkordion) ----
              _AccordionCard(
                icon: Icons.palette_outlined,
                title: 'Ko\'rinish',
                iconColor: AppTheme.brandGold(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mavzu (tema)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    PillSelector<ThemeMode>(options: const {'Tizim': ThemeMode.system, 'Yorug\'': ThemeMode.light, 'Qorong\'i': ThemeMode.dark}, selected: themeMode, onSelect: (m) => ref.read(themeModeProvider.notifier).setMode(m)),
                    const SizedBox(height: 20),
                    Text('Shrift o\'lchami', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    PillSelector<double>(options: const {'Kichik': 0.9, 'O\'rta': 1.0, 'Katta': 1.1, 'Juda katta': 1.2}, selected: fontScale, onSelect: (s) => ref.read(fontScaleProvider.notifier).setScale(s)),
                  ],
                ),
              ),

              // ---- 6. Ma'lumotlarni tozalash (akkordion — tasdiqlash bilan) ----
              _AccordionCard(
                icon: Icons.delete_forever_outlined,
                title: 'Ma\'lumotlarni tozalash',
                iconColor: AppTheme.brandExpense(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Barcha bo\'lim, tranzaksiya va byudjetlar butunlay o\'chib ketadi. Bu amalni ortga qaytarib bo\'lmaydi.', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu funksiya keyingi bosqichda ulanadi'))),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.brandExpense(context), side: BorderSide(color: AppTheme.brandExpense(context))),
                        child: const Text('Barchasini tozalash'),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- 7. Dastur haqida (akkordion) ----
              _AccordionCard(
                icon: Icons.info_outline,
                title: 'Dastur haqida',
                iconColor: Colors.grey,
                child: Column(
                  children: [
                    _SimpleRow(icon: Icons.share_outlined, label: 'Do\'stlarga ulashish', onTap: () => Share.share('PulNazorat — shaxsiy moliyani boshqarish ilovasi. Sinab ko\'ring!')),
                    _SimpleRow(icon: Icons.star_border_rounded, label: 'Ilovani baholash', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Play Store havolasi tez orada qo\'shiladi')))),
                    _SimpleRow(icon: Icons.privacy_tip_outlined, label: 'Maxfiylik siyosati', onTap: () => _showInfoDialog('Maxfiylik siyosati', 'PulNazorat barcha ma\'lumotlaringizni FAQAT sizning qurilmangizda saqlaydi. Hech qanday ma\'lumot serverga yuborilmaydi.')),
                    _SimpleRow(icon: Icons.description_outlined, label: 'Foydalanish shartlari', onTap: () => _showInfoDialog('Foydalanish shartlari', 'PulNazorat shaxsiy moliyani kuzatish uchun mo\'ljallangan yordamchi vositadir.')),
                    _SimpleRow(icon: Icons.mail_outline, label: 'Yordam va aloqa', onTap: _showDeveloperInfo),
                    const Divider(height: 20),
                    Text('PulNazorat — Versiya 1.0.0', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReminderTime(ReminderSettings reminder) async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute));
    if (time == null) return;
    await _run(() async {
      await NotificationService.scheduleDailyReminder(hour: time.hour, minute: time.minute);
      ref.read(reminderProvider.notifier).update(hour: time.hour, minute: time.minute);
    });
  }

  void _showDeveloperInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dasturchi haqida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ushbu dastur Sharifxonov Hakimxon tomonidan ishlab chiqilgan.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _ContactRow(icon: Icons.telegram, label: 'Telegram', value: '@Abduhamidxonovich'),
            const SizedBox(height: 10),
            _ContactRow(icon: Icons.phone_outlined, label: 'Telefon', value: '+998 93 567 55 20'),
            const SizedBox(height: 10),
            _ContactRow(icon: Icons.email_outlined, label: 'Email', value: 'hakimkhon1994@gmail.com'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish'))],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(title), content: SingleChildScrollView(child: Text(content)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish'))]),
    );
  }
}

/// Bosilganda pastida ochiladigan (yangi sahifa OCHMAYDIGAN) bo'lim
class _AccordionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _AccordionCard({required this.icon, required this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          leading: CircleAvatar(backgroundColor: iconColor.withValues(alpha: 0.14), child: Icon(icon, color: iconColor, size: 20)),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [child],
        ),
      ),
    );
  }
}

/// Haqiqatan yangi sahifaga o'tadigan qator
class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(backgroundColor: iconColor.withValues(alpha: 0.14), child: Icon(icon, color: iconColor, size: 20)),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SimpleRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.mutedText(context), size: 20),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label nusxalandi: $value')));
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
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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

/// Profil ismini akkordion ICHIDA, yangi sahifasiz tahrirlash formasi
class _ProfileEditForm extends ConsumerStatefulWidget {
  final String currentName;
  const _ProfileEditForm({required this.currentName});

  @override
  ConsumerState<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<_ProfileEditForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: _controller, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), decoration: const InputDecoration(labelText: 'Ismingiz')),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ref.read(userNameProvider.notifier).setName(_controller.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saqlandi')));
            },
            child: const Text('Saqlash'),
          ),
        ),
      ],
    );
  }
}