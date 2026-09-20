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
  ConsumerState<AddEditCategorySheet> createState() =>
      _AddEditCategorySheetState();
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
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
                      color: onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  isEditing ? "Bo'limni tahrirlash" : "Yangi bo'lim qo'shish",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Bo'lim nomi"),
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: onSurface),
                ),
                const SizedBox(height: 20),

                Text(
                  'Rang',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: IconHelper.colorPalette.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final color = IconHelper.colorPalette[index];
                      final selected =
                          color.toARGB32() == _selectedColor.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: color,
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Ikonka',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
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
                          decoration: BoxDecoration(
                            color: selected
                                ? _selectedColor.withValues(alpha: 0.2)
                                : onSurface.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: _selectedColor, width: 1.5)
                                : null,
                          ),
                          child: Icon(
                            icon,
                            color: selected
                                ? _selectedColor
                                : onSurface.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary(context),
                    ),
                    onPressed: _save,
                    child: Text(
                      isEditing ? 'Saqlash' : "Qo'shish",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bo'lim nomini kiriting")));
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
