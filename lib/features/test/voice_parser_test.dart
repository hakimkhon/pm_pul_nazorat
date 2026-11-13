// import 'package:flutter_test/flutter_test.dart';
// import 'package:pulnazorat/core/utils/voice_parser.dart';
// import 'package:pulnazorat/models/category_model.dart';

// CategoryModel _c(String id, String name, String type) =>
//     CategoryModel(id: id, name: name, iconCode: 'x', colorValue: 0xFF000000, type: type, isDefault: true);

// void main() {
//   final cats = [
//     _c('food', 'Oziq-ovqat', 'expense'),
//     _c('health', 'Dori-darmon', 'expense'),
//     _c('utilities', 'Kommunal', 'expense'),
//     _c('salary', 'Ish haqi', 'income'),
//   ];
//   final now = DateTime(2026, 10, 6, 12);

//   test("summa: so'zlar bilan", () {
//     final d = parseVoiceText("Bozorga ikki yuz ellik ming so'm sarfladim", cats, now: now);
//     expect(d.amount, 250000);
//     expect(d.type, 'expense');
//     expect(d.categoryId, 'food');
//   });

//   test('summa: million + ming', () {
//     final d = parseVoiceText('Ish haqi bir million besh yuz ming so\'m oldim', cats, now: now);
//     expect(d.amount, 1500000);
//     expect(d.type, 'income');
//     expect(d.categoryId, 'salary');
//   });

//   test('summa: raqam + ming, kecha', () {
//     final d = parseVoiceText("kecha 150 ming so'mga non oldim", cats, now: now);
//     expect(d.amount, 150000);
//     expect(d.date, DateTime(2026, 10, 5, 12));
//     expect(d.categoryId, 'food');
//   });

//   test('summa: bir yarim million, kommunal', () {
//     final d = parseVoiceText("bir yarim million so'm kommunal to'ladim", cats, now: now);
//     expect(d.amount, 1500000);
//     expect(d.type, 'expense');
//     expect(d.categoryId, 'utilities');
//   });

//   test('guruhlangan raqam: 1 250 000', () {
//     final d = parseVoiceText("1 250 000 so'm svet uchun to'ladim", cats, now: now);
//     expect(d.amount, 1250000);
//     expect(d.categoryId, 'utilities');
//   });

//   test('n kun oldin', () {
//     final d = parseVoiceText('ikki kun oldin dori sotib oldim 80 ming', cats, now: now);
//     expect(d.amount, 80000);
//     expect(d.categoryId, 'health');
//     expect(d.date, DateTime(2026, 10, 4, 12));
//   });
// }
