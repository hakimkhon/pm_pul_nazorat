import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../core/utils/icon_helper.dart';
import '../core/theme/app_theme.dart';

/// Summani "+"/"-" belgi va rang bilan ko'rsatadi (kirim=yashil, chiqim=qizil)
class MoneyText extends StatelessWidget {
  final double amount;
  final String type; // 'income' | 'expense'
  final double fontSize;
  final FontWeight weight;

  const MoneyText({super.key, required this.amount, required this.type, this.fontSize = 14, this.weight = FontWeight.w700});

  @override
  Widget build(BuildContext context) {
    final color = type == 'income' ? AppTheme.brandIncome(context) : AppTheme.brandExpense(context);
    final sign = type == 'income' ? '+' : '-';
    return Text(
      '$sign${NumberFormat("#,##0").format(amount)}',
      style: TextStyle(color: color, fontWeight: weight, fontSize: fontSize),
    );
  }
}

/// Bo'lim ikonkasi — rangli doira ichida
class CategoryAvatar extends StatelessWidget {
  final CategoryModel category;
  final double radius;
  final double iconSize;

  const CategoryAvatar({super.key, required this.category, this.radius = 22, this.iconSize = 20});

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.14),
      child: Icon(IconHelper.getIcon(category.iconCode), color: color, size: iconSize),
    );
  }
}

/// Bitta tranzaksiya qatori — bosh sahifa, kategoriya tafsiloti, qidiruv natijasida ishlatiladi
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel category;
  final bool showCategoryAsSubtitle;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    this.showCategoryAsSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final subtitle = (t.note != null && t.note!.isNotEmpty)
        ? t.note!
        : (showCategoryAsSubtitle ? category.name : DateFormat('dd.MM.yyyy').format(t.date));

    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CategoryAvatar(category: category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.source ?? category.name,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.mutedText(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(amount: t.amount, type: t.type),
              const SizedBox(height: 2),
              Text(DateFormat('HH:mm').format(t.date), style: TextStyle(fontSize: 11, color: AppTheme.mutedText(context))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Har doim ishlatiladigan karta konteyneri (fon, radius, soya) — temaga moslashadi
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? tint;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin = EdgeInsets.zero, this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.softShadow(tint: tint ?? AppTheme.deepTeal, opacity: 0.04),
      ),
      child: child,
    );
  }
}

/// Bo'lim sarlavhasi (masalan "So'nggi tranzaksiyalar")
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    if (trailing == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8, left: 4),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: Theme.of(context).textTheme.titleMedium),
          trailing!,
        ],
      ),
    );
  }
}

/// Bo'sh holat ko'rsatkichi (ma'lumot yo'q bo'lganda)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.brandGold(context).withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.brandGold(context), size: 30),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Ro'yxat elementlarini ketma-ket, sekin-sekin paydo bo'lishini ta'minlaydi
class FadeInItem extends StatelessWidget {
  final int index;
  final Widget child;
  final bool slideUp;

  const FadeInItem({super.key, required this.index, required this.child, this.slideUp = true});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 240 + index * 35),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: slideUp ? Transform.translate(offset: Offset(0, (1 - v) * 12), child: c) : Transform.scale(scale: 0.9 + (0.1 * v), child: c),
      ),
      child: child,
    );
  }
}

/// Teng kenglikdagi segmentlar qatori (masalan Kunlik/Haftalik/Oylik/Yillik) —
/// tanlangan segment aniq ko'rinadigan yuqori kontrast bilan
class EqualSegmentedBar<T> extends StatelessWidget {
  final Map<String, T> options;
  final T selected;
  final void Function(T) onSelect;

  const EqualSegmentedBar({super.key, required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = entry.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(entry.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.brandPrimary(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: isSelected ? (isDark ? AppTheme.darkBg : Colors.white) : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Kirim/Chiqim mini-statistika: qorong'i/yorug' rejimda ham ikonka aniq ko'rinishi uchun
/// TO'LIQ RANGLI (alpha past emas) doira fon + oq ikonka ishlatiladi
class ContrastStatChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const ContrastStatChip({super.key, required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(NumberFormat.compact().format(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PillSelector<T> extends StatelessWidget {
  final Map<String, T> options;
  final T selected;
  final void Function(T) onSelect;

  const PillSelector({super.key, required this.options, required this.selected, required this.onSelect});

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
              color: isSelected ? AppTheme.brandPrimary(context) : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.key,
              style: TextStyle(
                color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBg : Colors.white) : Theme.of(context).colorScheme.onSurface,
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