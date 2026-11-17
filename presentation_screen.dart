import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'database_helper.dart';
import 'random_picker.dart';
import 'strings.dart';
import 'widgets.dart';

class _Choice {
  final String text;
  final bool correct;
  const _Choice(this.text, this.correct);
}

/// Classroom "Presentation Mode": big high-contrast question + 3 answers.
/// Correct answer => confetti + chime + spoken "أحسنت / Bravo ! / Well done!" + big banner.
class PresentationScreen extends StatefulWidget {
  final List<Question> questions;
  final List<Student> students;

  const PresentationScreen({super.key, required this.questions, required this.students});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final _rng = Random();
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  final _player = AudioPlayer();
  final _tts = FlutterTts();

  int _index = 0;
  int _score = 0;
  late List<_Choice> _choices;
  final Set<int> _wrong = {};
  int? _correctIndex;
  bool _answered = false;
  bool _firstTry = true;
  bool _bannerVisible = false;
  String? _student;

  @override
  void initState() {
    super.initState();
    _prepareQuestion();
    _initTts();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {/* TTS is optional: the app keeps working without it */}
  }

  String _ttsLocale(String lang) => switch (lang) {
        'ar' => 'ar',
        'fr' => 'fr-FR',
        _ => 'en-US',
      };

  void _prepareQuestion() {
    final q = widget.questions[_index];
    _choices = [
      _Choice(q.correct, true),
      _Choice(q.wrong1, false),
      _Choice(q.wrong2, false),
    ]..shuffle(_rng);
    _wrong.clear();
    _correctIndex = null;
    _answered = false;
    _firstTry = true;
    _bannerVisible = false;
  }

  Future<void> _celebrate(String lang, String phrase) async {
    _confetti.play();
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.wav'));
    } catch (_) {}
    try {
      await Future.delayed(const Duration(milliseconds: 600)); // let the chime ring first
      await _tts.setLanguage(_ttsLocale(lang));
      await _tts.speak(phrase);
    } catch (_) {}
  }

  void _onChoice(int i) {
    if (_answered || _wrong.contains(i)) return;

    if (_choices[i].correct) {
      final lang = context.lang;
      final phrase = context.t('bravo');
      setState(() {
        _answered = true;
        _correctIndex = i;
        _bannerVisible = true;
        if (_firstTry) _score++;
      });
      _celebrate(lang, phrase);
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _bannerVisible = false);
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong.add(i);
        _firstTry = false;
      });
    }
  }

  void _next() {
    if (_index >= widget.questions.length - 1) {
      _showResult();
    } else {
      setState(() {
        _index++;
        _prepareQuestion();
      });
    }
  }

  Future<void> _showResult() async {
    _confetti.play();
    final total = widget.questions.length;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(c.t('quizFinished'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 72, color: AppColors.amber),
            const SizedBox(height: 8),
            Text(
              '${c.t('score')}: $_score / $total',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'close'), child: Text(c.t('close'))),
          FilledButton(onPressed: () => Navigator.pop(c, 'restart'), child: Text(c.t('restart'))),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'restart') {
      setState(() {
        widget.questions.shuffle();
        _index = 0;
        _score = 0;
        _prepareQuestion();
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickStudent() async {
    if (widget.students.isEmpty) {
      showSnack(context, context.t('noStudents'));
      return;
    }
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RandomPickerDialog(names: widget.students.map((s) => s.name).toList()),
    );
    if (name != null && mounted) setState(() => _student = name);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_index];
    final total = widget.questions.length;
    final size = MediaQuery.of(context).size;
    final wide = size.width > size.height;
    final letters = context.lang == 'ar' ? ['أ', 'ب', 'ج'] : ['A', 'B', 'C'];
    final isLast = _index == total - 1;

    final questionCard = _QuestionCard(text: q.text);
    final choices = Column(
      children: [
        for (var i = 0; i < _choices.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _ChoiceTile(
                letter: letters[i],
                text: _choices[i].text,
                isCorrect: _correctIndex == i,
                isWrong: _wrong.contains(i),
                dimmed: _answered && _correctIndex != i,
                onTap: () => _onChoice(i),
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.deepIndigo,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                      ),
                      Text(
                        '${_index + 1} / $total',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      ActionChip(
                        avatar: const Icon(Icons.casino_rounded, size: 20, color: AppColors.ink),
                        label: Text(
                          _student ?? context.t('pickStudent'),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        backgroundColor: AppColors.amber,
                        side: BorderSide.none,
                        onPressed: _pickStudent,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        avatar: const Icon(Icons.star_rounded, color: AppColors.amber),
                        label: Text('$_score',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        backgroundColor: Colors.white12,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ),
                // Question + choices
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: wide
                        ? Row(
                            children: [
                              Expanded(flex: 5, child: questionCard),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: choices),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(flex: 4, child: questionCard),
                              const SizedBox(height: 10),
                              Expanded(flex: 6, child: choices),
                            ],
                          ),
                  ),
                ),
                // Next / Finish
                SizedBox(
                  height: 78,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _answered ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: IgnorePointer(
                        ignoring: !_answered,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.amber,
                            foregroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          onPressed: _next,
                          icon: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded),
                          label: Text(context.t(isLast ? 'finish' : 'next')),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Confetti (two emitters)
            Align(alignment: Alignment.topCenter, child: _confettiWidget()),
            Align(alignment: Alignment.center, child: _confettiWidget()),

            // Big "أحسنت / Bravo ! / Well done!" banner
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _bannerVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: AnimatedScale(
                      scale: _bannerVisible ? 1 : 0.6,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded, size: 56, color: AppColors.amber),
                            const SizedBox(width: 16),
                            Text(
                              context.t('bravo'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confettiWidget() => ConfettiWidget(
        confettiController: _confetti,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        emissionFrequency: 0.06,
        numberOfParticles: 30,
        maxBlastForce: 28,
        minBlastForce: 8,
        gravity: 0.25,
        colors: const [
          AppColors.emerald,
          AppColors.amber,
          Colors.white,
          Color(0xFF818CF8),
          Color(0xFFF472B6),
        ],
      );
}

class _QuestionCard extends StatelessWidget {
  final String text;
  const _QuestionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;
  final bool isWrong;
  final bool dimmed;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.letter,
    required this.text,
    required this.isCorrect,
    required this.isWrong,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isCorrect
        ? AppColors.emerald
        : isWrong
            ? const Color(0xFFFECACA)
            : Colors.white;
    final Color fg = isCorrect ? Colors.white : AppColors.ink;

    return AnimatedOpacity(
      opacity: dimmed || isWrong ? 0.55 : 1,
      duration: const Duration(milliseconds: 250),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCorrect ? AppColors.amber : Colors.transparent,
            width: 4,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isCorrect ? Colors.white : AppColors.indigo,
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isCorrect ? AppColors.emerald : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        text,
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: fg),
                      ),
                    ),
                  ),
                  if (isCorrect) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 38),
                  if (isWrong) const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 38),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
