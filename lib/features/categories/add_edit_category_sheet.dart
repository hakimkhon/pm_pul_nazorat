import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/theme/app_theme.dart';

class AddEditCategorySheet extends ConsumerStatefulWidget {
  final CategoryModel? existing;
  final String type;

  const AddEditCategorySheet({super.key, this.existing, required this.type});

  @override
  ConsumerState<AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<AddEditCategorySheet> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon = widget.existing?.iconCode ?? IconHelper.iconMap.keys.first;
    _selectedColor = widget.existing != null
        ? Color(widget.existing!.colorValue)
        : IconHelper.colorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              isEditing ? "Bo'limni tahrirlash" : "Yangi bo'lim qo'shish",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Bo'lim nomi"),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            const Text('Rang', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: IconHelper.colorPalette.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = IconHelper.colorPalette[index];
                  final selected = color.toARGB32() == _selectedColor.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: color,
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            const Text('Ikonka', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: IconHelper.iconMap.length,
                itemBuilder: (context, index) {
                  final code = IconHelper.iconMap.keys.elementAt(index);
                  final icon = IconHelper.iconMap[code]!;
                  final selected = code == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = code),
                    child: Container(
                      width: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? _selectedColor.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: selected ? Border.all(color: _selectedColor, width: 1.5) : null,
                      ),
                      child: Icon(icon, color: selected ? _selectedColor : Colors.grey.shade600, size: 20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: _save,
                child: Text(isEditing ? 'Saqlash' : "Qo'shish", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bo'lim nomini kiriting")),
      );
      return;
    }

    if (widget.existing != null) {
      final updated = CategoryModel(
        id: widget.existing!.id,
        name: name,
        iconCode: _selectedIcon,
        colorValue: _selectedColor.toARGB32(),
        type: widget.type,
        isDefault: widget.existing!.isDefault,
      );
      ref.read(categoryProvider.notifier).updateCategory(updated);
    } else {
      final newCategory = CategoryModel(
        id: const Uuid().v4(),
        name: name,
        iconCode: _selectedIcon,
        colorValue: _selectedColor.toARGB32(),
        type: widget.type,
        isDefault: false,
      );
      ref.read(categoryProvider.notifier).addCategory(newCategory);
    }

    Navigator.pop(context);
  }
}