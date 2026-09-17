import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextField'ga kiritilayotgan raqamni real vaqtda "1 250 000" ko'rinishida formatlaydi.
class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('en_US'); // "," beradi, keyin bo'shliqqa almashtiramiz

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Faqat raqamlarni qoldiramiz
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Boshidagi ortiqcha nollarni olib tashlaymiz (lekin bitta "0" qolsin)
    digitsOnly = digitsOnly.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final number = int.parse(digitsOnly);
    final formatted = _formatter.format(number).replaceAll(',', ' ');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Formatlangan matndan ("1 250 000") haqiqiy sonni ("1250000") olish uchun
  static double? parse(String formatted) {
    final digitsOnly = formatted.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return null;
    return double.tryParse(digitsOnly);
  }
}