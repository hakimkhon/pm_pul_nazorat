import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/notification_history.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final history = NotificationHistory.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirishnomalar'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Barchasini tozalash',
              onPressed: () async {
                await NotificationHistory.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.mutedText(context)),
                    const SizedBox(height: 12),
                    Text('Hozircha bildirishnoma yo\'q', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.brandGold(context).withValues(alpha: 0.14),
                        child: Icon(Icons.pie_chart_outline, color: AppTheme.brandGold(context), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(item['body'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd.MM.yyyy HH:mm').format(date), style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}