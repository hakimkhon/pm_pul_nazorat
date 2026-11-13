import '../../models/category_model.dart';

/// Ovozdan tushunilgan tranzaksiya qoralamasi. null maydon = "tushunilmadi".
class VoiceDraft {
  final String rawText;
  final double? amount;
  final String? type; // 'income' | 'expense'
  final String? categoryId;
  final String? categoryName;
  final DateTime? date;
  final String note;

  const VoiceDraft({
    required this.rawText,
    this.amount,
    this.type,
    this.categoryId,
    this.categoryName,
    this.date,
    this.note = '',
  });

  bool get isEmpty => amount == null && type == null && categoryId == null && date == null && note.isEmpty;
}

class _Tok {
  final String orig; // apostrofli (izohga yoziladi)
  final String norm; // apostrofsiz (solishtirish uchun)
  bool used = false;
  _Tok(this.orig) : norm = orig.replaceAll("'", '');
}

// Kirill -> Lotin (ayrim qurilmalar kirillcha natija qaytaradi)
const Map<String, String> _cyr = {
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'j', 'з': 'z',
  'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r',
  'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'ъ': "'",
  'ы': 'i', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya', 'ў': "o'", 'қ': 'q', 'ғ': "g'", 'ҳ': 'h',
};

// Raqam so'zlari (apostrofsiz shaklda)
const Map<String, double> _units = {
  'bir': 1, 'ikki': 2, 'uch': 3, 'tort': 4, 'besh': 5, 'olti': 6, 'yetti': 7, 'sakkiz': 8, 'toqqiz': 9,
};
const Map<String, double> _tens = {
  'on': 10, 'yigirma': 20, 'ottiz': 30, 'qirq': 40, 'ellik': 50, 'oltmish': 60, 'yetmish': 70, 'sakson': 80, 'toqson': 90,
};
const Map<String, double> _mults = {
  'ming': 1e3, 'million': 1e6, 'milyon': 1e6, 'mln': 1e6, 'milliard': 1e9, 'miliard': 1e9, 'mlrd': 1e9,
};
const Set<String> _currency = {'som', 'sum', 'somga', 'sumga', 'somni', 'sumni', 'somlik', 'sumlik', 'soum'};

// Tur aniqlash so'zlari (prefiks bo'yicha)
const List<String> _expPrefix = [
  'sarf', 'xarajat', 'harajat', 'xarid', 'harid', 'tola', 'tolov', 'chiqim', 'berdim', 'berdik', 'ketdi', 'yoqotdim',
];
const List<String> _incPrefix = [
  'kirim', 'daromad', 'maosh', 'oylik', 'tushdi', 'tushum', 'topdim', 'topdik', 'keldi', 'qaytard', 'qaytarish',
  'pensiya', 'stipendiya', 'foyda', 'sovga', 'avans', 'berishdi',
];

// Bo'lim nomiga qo'shimcha sinonimlar: bo'lim nomida [kalit] bo'lsa, shu so'zlar ham mos keladi
const Map<String, List<String>> _synonyms = {
  'ovqat': ['non', 'gosht', 'sabzi', 'meva', 'bozor', 'bozorlik', 'market', 'dokon', 'restoran', 'kafe', 'tushlik', 'kechki', 'nonushta', 'sut', 'guruch', 'choy', 'taom'],
  'oziq': ['non', 'gosht', 'sabzi', 'meva', 'bozor', 'bozorlik', 'market', 'dokon', 'restoran', 'kafe', 'tushlik', 'kechki', 'nonushta', 'sut', 'guruch', 'choy', 'taom'],
  'dori': ['apteka', 'shifokor', 'doktor', 'kasalxona', 'klinika', 'davo', 'vrach', 'tabletka'],
  'kommunal': ['svet', 'elektr', 'tok', 'gaz', 'suv', 'internet', 'telefon', 'chiqindi', 'isitish'],
  'ish haqi': ['maosh', 'oylik', 'avans'],
  'daromad': ['foyda', 'sovga', 'pensiya', 'stipendiya'],
};

String _latin(String input) {
  final sb = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    sb.write(_cyr[ch] ?? ch);
  }
  return sb.toString().replaceAll(RegExp(r"[ʻʼ’‘`´]"), "'");
}

final RegExp _digitTok = RegExp(r'^\d+([.,]\d+)?$');

List<_Tok> _tokenize(String input) {
  var s = _latin(input);
  // 250,000 / 1.250.000 kabi ming ajratgichlarni olib tashlaymiz
  s = s.replaceAllMapped(RegExp(r'\b\d{1,3}(?:[.,]\d{3})+\b'), (m) => m.group(0)!.replaceAll(RegExp(r'[.,]'), ''));
  s = s.replaceAll(RegExp(r"[^a-z0-9'.,\s]"), ' ');

  final raw = s
      .split(RegExp(r'\s+'))
      .map((t) => t.replaceAll(RegExp(r"^[.,']+|[.,']+$"), ''))
      .where((t) => t.isNotEmpty)
      .toList();

  // "1 250 000" kabi guruhlangan raqamlarni birlashtiramiz
  final merged = <String>[];
  var i = 0;
  while (i < raw.length) {
    var cur = raw[i];
    if (RegExp(r'^\d{1,3}$').hasMatch(cur)) {
      while (i + 1 < raw.length && RegExp(r'^\d{3}$').hasMatch(raw[i + 1])) {
        cur += raw[i + 1];
        i++;
      }
    }
    merged.add(cur);
    i++;
  }
  return merged.map((t) => _Tok(t)).toList();
}

bool _isNum(String t) =>
    _digitTok.hasMatch(t) || _units.containsKey(t) || _tens.containsKey(t) || _mults.containsKey(t) || t == 'yuz' || t == 'yarim';

double? _evalRun(List<String> run) {
  var total = 0.0;
  var current = 0.0;
  for (final t in run) {
    if (_digitTok.hasMatch(t)) {
      current += double.parse(t.replaceAll(',', '.'));
    } else if (_units.containsKey(t)) {
      current += _units[t]!;
    } else if (_tens.containsKey(t)) {
      current += _tens[t]!;
    } else if (t == 'yarim') {
      current += 0.5;
    } else if (t == 'yuz') {
      current = (current == 0 ? 1 : current) * 100;
    } else if (_mults.containsKey(t)) {
      total += (current == 0 ? 1 : current) * _mults[t]!;
      current = 0;
    }
  }
  final v = total + current;
  return v > 0 ? v : null;
}

/// Eng katta qiymatli raqamlar ketma-ketligini summa deb oladi
double? _extractAmount(List<_Tok> toks) {
  double? best;
  var bestStart = -1;
  var bestEnd = -1;
  var i = 0;
  while (i < toks.length) {
    if (toks[i].used || !_isNum(toks[i].norm)) {
      i++;
      continue;
    }
    var j = i;
    while (j < toks.length && !toks[j].used && _isNum(toks[j].norm)) {
      j++;
    }
    final v = _evalRun(toks.sublist(i, j).map((t) => t.norm).toList());
    if (v != null && (best == null || v > best)) {
      best = v;
      bestStart = i;
      bestEnd = j;
    }
    i = j;
  }
  if (best != null) {
    for (var k = bestStart; k < bestEnd; k++) {
      toks[k].used = true;
    }
  }
  return best;
}

DateTime? _extractDate(List<_Tok> toks, DateTime now) {
  DateTime? date;
  for (var i = 0; i < toks.length; i++) {
    final t = toks[i].norm;
    if (t == 'bugun') {
      date = now;
      toks[i].used = true;
    } else if (t == 'kecha') {
      date = now.subtract(const Duration(days: 1));
      toks[i].used = true;
    } else if (t == 'kun' && i + 1 < toks.length && toks[i + 1].norm == 'oldin' && i > 0) {
      // "ikki kun oldin"
      final prev = toks[i - 1].norm;
      final n = _digitTok.hasMatch(prev) ? double.tryParse(prev.replaceAll(',', '.')) : (_units[prev] ?? _tens[prev]);
      if (n != null && n >= 1 && n <= 60) {
        date = now.subtract(Duration(days: n.round()));
        toks[i - 1].used = true;
        toks[i].used = true;
        toks[i + 1].used = true;
      }
    }
  }
  return date;
}

bool _stemMatch(String t, String w) {
  if (t == w) return true;
  if (w.length <= 3) {
    return t.startsWith(w) && t.length <= w.length + 3;
  }
  final n = t.length < w.length ? t.length : w.length;
  if (n < 4) return false;
  var k = 0;
  while (k < n && t[k] == w[k]) {
    k++;
  }
  return k >= n - 1 && k >= 4;
}

String _normName(String s) => _latin(s).replaceAll("'", '');

CategoryModel? _bestCategory(List<_Tok> toks, List<CategoryModel> pool) {
  CategoryModel? best;
  var bestScore = 0;
  // Tur so'zlari ham (masalan "oylik", "to'lov") bo'limni aniqlashga yordam beradi, shuning uchun used filtri yo'q
  final words = toks.map((t) => t.norm).toList();
  for (final c in pool) {
    final name = _normName(c.name);
    final nameWords = name.split(RegExp(r'[^a-z0-9]+')).where((w) => w.length >= 3);
    var score = 0;
    for (final w in nameWords) {
      if (words.any((t) => _stemMatch(t, w))) score += 3;
    }
    for (final e in _synonyms.entries) {
      if (name.contains(e.key) && words.any((t) => e.value.any((kw) => _stemMatch(t, kw)))) {
        score += 2;
        break;
      }
    }
    if (score > bestScore) {
      bestScore = score;
      best = c;
    }
  }
  return bestScore >= 2 ? best : null;
}

/// Ovozdan olingan matnni (o'zbekcha) summa, tur, bo'lim, sana va izohga ajratadi.
VoiceDraft parseVoiceText(String text, List<CategoryModel> categories, {DateTime? now}) {
  final toks = _tokenize(text);
  final today = now ?? DateTime.now();

  final date = _extractDate(toks, today);
  final amount = _extractAmount(toks);

  // valyuta so'zlari
  for (final t in toks) {
    if (_currency.contains(t.norm)) t.used = true;
  }

  // tur ballari
  var inc = 0.0;
  var exp = 0.0;
  for (var i = 0; i < toks.length; i++) {
    final t = toks[i];
    if (t.used) continue;
    if (t.norm == 'sotib' && i + 1 < toks.length && toks[i + 1].norm.startsWith('old')) {
      exp += 3;
      t.used = true;
      toks[i + 1].used = true;
    } else if (t.norm == 'oldim' || t.norm == 'oldik') {
      exp += 0.5;
      t.used = true;
    } else if (t.norm == 'berdi') {
      inc += 2;
      t.used = true;
    } else if (_incPrefix.any((p) => t.norm.startsWith(p))) {
      inc += 2;
      t.used = true;
    } else if (_expPrefix.any((p) => t.norm.startsWith(p))) {
      exp += 2;
      t.used = true;
    }
  }

  String? type;
  final strong = (inc - exp).abs() >= 2;
  if (strong) type = inc > exp ? 'income' : 'expense';

  final pool = type == null ? categories : categories.where((c) => c.type == type).toList();
  final match = _bestCategory(toks, pool);
  if (match != null) {
    if (!strong) type = match.type;
  } else if (!strong && (inc != 0 || exp != 0)) {
    type = inc > exp ? 'income' : 'expense';
  }

  final note = toks.where((t) => !t.used).map((t) => t.orig).join(' ').trim();

  return VoiceDraft(
    rawText: text,
    amount: amount,
    type: type,
    categoryId: match?.id,
    categoryName: match?.name,
    date: date,
    note: note.isEmpty ? '' : note[0].toUpperCase() + note.substring(1),
  );
}
