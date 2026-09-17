import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as ex;
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import 'repositories/category_repository.dart';
import 'repositories/transaction_repository.dart';

enum ImportMode { merge, replace }

class BackupService {
  final CategoryRepository _categoryRepo = CategoryRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  // ---------- JSON EXPORT ----------
  Future<File> exportToJson() async {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'categories': _categoryRepo.getAll().map((c) => c.toJson()).toList(),
      'transactions': _transactionRepo.getAll().map((t) => t.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final fileName = 'pulnazorat_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<void> exportAndShareJson() async {
    final file = await exportToJson();
    await Share.shareXFiles([XFile(file.path)], text: 'PulNazorat backup fayli');
  }

  // ---------- JSON IMPORT ----------
  Future<Map<String, int>> importFromJsonFile(ImportMode mode) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('Fayl tanlanmadi');
    }

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    final categoriesJson = (data['categories'] as List?) ?? [];
    final transactionsJson = (data['transactions'] as List?) ?? [];

    final categories = categoriesJson.map((e) => CategoryModel.fromJson(e)).toList();
    final transactions = transactionsJson.map((e) => TransactionModel.fromJson(e)).toList();

    if (mode == ImportMode.replace) {
      // Avval hammasini tozalaymiz
      for (var c in _categoryRepo.getAll()) {
        await _categoryRepo.delete(c.id);
      }
      for (var t in _transactionRepo.getAll()) {
        await _transactionRepo.delete(t.id);
      }
    }

    int addedCategories = 0;
    int addedTransactions = 0;

    for (var c in categories) {
      await _categoryRepo.add(c); // put — id bir xil bo'lsa, ustidan yoziladi (xavfsiz)
      addedCategories++;
    }
    for (var t in transactions) {
      await _transactionRepo.add(t);
      addedTransactions++;
    }

    return {'categories': addedCategories, 'transactions': addedTransactions};
  }

  // ---------- EXCEL EXPORT ----------
  Future<File> exportToExcel() async {
    final excelFile = ex.Excel.createExcel();

    // Tranzaksiyalar varag'i
    final sheet = excelFile['Tranzaksiyalar'];
    excelFile.delete('Sheet1');

    sheet.appendRow([
      ex.TextCellValue('Sana'),
      ex.TextCellValue('Turi'),
      ex.TextCellValue("Bo'lim"),
      ex.TextCellValue('Summa'),
      ex.TextCellValue('Manba/Izoh'),
    ]);

    final categories = _categoryRepo.getAll();
    String categoryName(String id) =>
        categories.firstWhere((c) => c.id == id, orElse: () => categories.first).name;

    for (var t in _transactionRepo.getAll()) {
      sheet.appendRow([
        ex.TextCellValue(DateFormat('dd.MM.yyyy').format(t.date)),
        ex.TextCellValue(t.type == 'income' ? 'Kirim' : 'Chiqim'),
        ex.TextCellValue(categoryName(t.categoryId)),
        ex.DoubleCellValue(t.amount),
        ex.TextCellValue(t.source ?? t.note ?? ''),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final fileName = 'pulnazorat_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$fileName');
    final bytes = excelFile.encode();
    await file.writeAsBytes(bytes!);
    return file;
  }

  Future<void> exportAndShareExcel() async {
    final file = await exportToExcel();
    await Share.shareXFiles([XFile(file.path)], text: 'PulNazorat backup fayli');
  }
}