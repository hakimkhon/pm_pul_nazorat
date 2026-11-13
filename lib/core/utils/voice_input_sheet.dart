import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/voice_parser.dart';
import '../../models/category_model.dart';

/// Pastdan ochiladigan oyna: tinglaydi → tushunilganini ko'rsatadi → foydalanuvchi tasdiqlasa qoralamani qaytaradi.
Future<VoiceDraft?> showVoiceInputSheet(BuildContext context, List<CategoryModel> categories) {
  return showModalBottomSheet<VoiceDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VoiceSheet(categories: categories),
  );
}

enum _Phase { starting, listening, review, error }

class _VoiceSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  const _VoiceSheet({required this.categories});

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  final SpeechToText _stt = SpeechToText();
  _Phase _phase = _Phase.starting;
  String _words = '';
  double _level = 0; // 0..1
  VoiceDraft? _draft;
  String _error = '';
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.starting;
      _words = '';
      _level = 0;
      _draft = null;
      _finished = false;
      _error = '';
    });

    final ok = await _stt.initialize(onStatus: _onStatus, onError: _onError);
    if (!mounted) return;
    if (!ok) {
      _fail("Mikrofon ruxsati berilmagan yoki telefonda ovoz tanish xizmati yo'q. Sozlamalarda ilovaga mikrofon ruxsatini bering.");
      return;
    }

    // Faqat o'zbek tili: telefondagi mos til identifikatorini topamiz
    var localeId = 'uz_UZ';
    final locales = await _stt.locales();
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith('uz')) {
        localeId = l.localeId;
        break;
      }
    }

    if (!mounted) return;
    setState(() => _phase = _Phase.listening);

    await _stt.listen(
      onResult: _onResult,
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      onSoundLevelChange: (l) {
        if (mounted && _phase == _Phase.listening) setState(() => _level = (l.clamp(0, 10)) / 10);
      },
      listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: true, listenMode: ListenMode.dictation),
    );
  }

  void _onResult(SpeechRecognitionResult r) {
    if (!mounted) return;
    setState(() => _words = r.recognizedWords);
    if (r.finalResult) _finish();
  }

  void _onStatus(String status) {
    // Ba'zan finalResult kelmaydi — tinglash tugaganda o'zimiz yakunlaymiz
    if ((status == 'done' || status == 'notListening') && _phase == _Phase.listening && !_finished) {
      if (_words.trim().isEmpty) {
        _fail("Hech narsa eshitilmadi. Mikrofonga yaqinroq va aniqroq gapirib qayta urinib ko'ring.");
      } else {
        _finish();
      }
    }
  }

  void _onError(SpeechRecognitionError e) {
    if (!mounted || _finished) return;
    final msg = e.errorMsg;
    if (msg.contains('language')) {
      _fail("Telefoningizda o'zbek tilida ovoz tanish topilmadi. Sozlamalar → Google → Qidiruv va ovoz (yoki Ovoz yordamchisi) → Til bo'limidan o'zbek tilini qo'shing va yuklab oling.");
    } else if (msg.contains('permission')) {
      _fail("Mikrofon ruxsati yo'q. Sozlamalar → Ilovalar → PulNazorat → Ruxsatlar bo'limidan mikrofonni yoqing.");
    } else if (msg.contains('no_match') || msg.contains('timeout')) {
      _fail("Hech narsa eshitilmadi. Mikrofonga yaqinroq va aniqroq gapirib qayta urinib ko'ring.");
    } else if (msg.contains('network')) {
      _fail("Internet aloqasi kerak: telefoningizdagi o'zbekcha ovoz tanish xizmati internet orqali ishlaydi.");
    } else {
      _fail("Ovozni tanishda xatolik: $msg");
    }
  }

  void _fail(String text) {
    _finished = true;
    _stt.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _error = text;
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _stt.stop();
    final draft = parseVoiceText(_words, widget.categories);
    if (!mounted) return;
    setState(() {
      _draft = draft;
      _phase = _Phase.review;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            if (_phase == _Phase.review) _buildReview(context) else if (_phase == _Phase.error) _buildError(context) else _buildListening(context),
          ],
        ),
      ),
    );
  }

  Widget _buildListening(BuildContext context) {
    final color = AppTheme.brandPrimary(context);
    final size = 72.0 + 30.0 * _level;
    final listening = _phase == _Phase.listening;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(listening ? 'Tinglayapman… gapiring' : 'Tayyorlanmoqda…', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Text(
            _words.isEmpty ? "Masalan: «Bozorga ikki yuz ellik ming so'm sarfladim»" : _words,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _words.isEmpty ? AppTheme.mutedText(context) : Theme.of(context).colorScheme.onSurface,
                  fontStyle: _words.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: listening ? () => _stt.stop() : null,
            icon: const Icon(Icons.stop_rounded),
            label: const Text("Tugatdim"),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mic_off_rounded, size: 40, color: AppTheme.brandExpense(context)),
        const SizedBox(height: 10),
        Text(_error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _start, child: const Text('Qayta urinish'))),
          ],
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final d = _draft!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fmt = NumberFormat.decimalPattern('en_US');

    Widget row(String label, String? value, {Color? valueColor}) {
      final found = value != null && value.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(found ? Icons.check_circle_rounded : Icons.help_outline_rounded, size: 18, color: found ? AppTheme.brandIncome(context) : AppTheme.brandGold(context)),
            const SizedBox(width: 8),
            SizedBox(width: 64, child: Text(label, style: Theme.of(context).textTheme.labelSmall)),
            Expanded(
              child: Text(
                found ? value : 'tushunilmadi',
                style: TextStyle(fontWeight: found ? FontWeight.w700 : FontWeight.w500, color: found ? (valueColor ?? onSurface) : AppTheme.mutedText(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final typeText = d.type == null ? null : (d.type == 'income' ? 'Kirim' : 'Chiqim');
    final typeColor = d.type == 'income' ? AppTheme.brandIncome(context) : AppTheme.brandExpense(context);
    final dateText = d.date == null ? null : DateFormat('dd.MM.yyyy').format(d.date!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Siz aytdingiz:', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
          child: Text('«${d.rawText}»', style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text('Tushunilgani:', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        row('Tur', typeText, valueColor: typeColor),
        row('Summa', d.amount == null ? null : "${fmt.format(d.amount!.round()).replaceAll(',', ' ')} so'm"),
        row("Bo'lim", d.categoryName),
        row('Sana', dateText ?? 'bugun'),
        row('Izoh', d.note),
        const SizedBox(height: 4),
        Text("Tushunilmaganlarni keyingi oynada o'zingiz to'ldirasiz.", style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: _start, icon: const Icon(Icons.mic_rounded, size: 18), label: const Text('Qayta gapirish'))),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: d.isEmpty ? null : () => Navigator.pop(context, d),
                child: const Text("Formaga o'tkazish"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
