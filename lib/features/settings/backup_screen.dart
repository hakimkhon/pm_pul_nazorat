import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/backup_service.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _backupService = BackupService();
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zaxira nusxa va tiklash')),
      body: AbsorbPointer(
        absorbing: _loading,
        child: Opacity(
          opacity: _loading ? 0.5 : 1,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle('Eksport qilish'),
              _Tile(
                icon: Icons.upload_file_outlined,
                iconColor: AppTheme.brandPrimary(context),
                title: 'JSON sifatida eksport qilish',
                subtitle: "Barcha ma'lumotlarni faylga saqlab, ulashish",
                onTap: () => _run(() => _backupService.exportAndShareJson()),
              ),
              _Tile(
                icon: Icons.grid_on_outlined,
                iconColor: AppTheme.brandIncome(context),
                title: 'Excel sifatida eksport qilish',
                subtitle: 'Tranzaksiyalarni Excel jadvaliga chiqarish',
                onTap: () => _run(() => _backupService.exportAndShareExcel()),
              ),
              const SizedBox(height: 8),
              _SectionTitle('Import qilish (tiklash)'),
              _Tile(
                icon: Icons.add_box_outlined,
                iconColor: AppTheme.brandIncome(context),
                title: "Qo'shib import qilish",
                subtitle: "Mavjud ma'lumotlar saqlanadi, yangilari qo'shiladi",
                onTap: () => _confirmImport(ImportMode.merge),
              ),
              _Tile(
                icon: Icons.restore_page_outlined,
                iconColor: AppTheme.brandExpense(context),
                title: 'Almashtirib import qilish',
                subtitle: "Diqqat: mavjud barcha ma'lumotlar o'chiriladi!",
                onTap: () => _confirmImport(ImportMode.replace),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.brandGold(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.brandGold(context), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tavsiya: ma'lumotlaringizni har hafta eksport qilib, telefon xotirasidan tashqarida (Google Drive, Telegram, kompyuter) saqlab qo'ying.",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmImport(ImportMode mode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(mode == ImportMode.replace ? 'Almashtirib import qilish' : "Qo'shib import qilish"),
        content: Text(
          mode == ImportMode.replace
              ? "Diqqat! Mavjud barcha bo'lim va tranzaksiyalar o'chirib tashlanadi, o'rniga fayldagi ma'lumotlar yoziladi. Davom etasizmi?"
              : "Fayldagi ma'lumotlar mavjudlarga qo'shiladi. Davom etasizmi?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _run(() async {
                final res = await _backupService.importFromJsonFile(mode);
                ref.read(categoryProvider.notifier).refresh();
                ref.read(transactionProvider.notifier).refresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${res['categories']} bo'lim, ${res['transactions']} tranzaksiya import qilindi")),
                  );
                }
              });
            },
            child: Text(
              'Davom etish',
              style: TextStyle(color: mode == ImportMode.replace ? AppTheme.brandExpense(context) : AppTheme.brandPrimary(context)),
            ),
          ),
        ],
      ),
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
      child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _Tile({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.onTap});

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
        trailing: onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
        onTap: onTap,
      ),
    );
  }
}