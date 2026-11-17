import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'strings.dart';
import 'widgets.dart';

/// "Tirage au sort": names flash by faster, then slow down and stop on the winner.
/// Returns the chosen name when the teacher taps OK (or null if dismissed).
class RandomPickerDialog extends StatefulWidget {
  final List<String> names;
  const RandomPickerDialog({super.key, required this.names});

  @override
  State<RandomPickerDialog> createState() => _RandomPickerDialogState();
}

class _RandomPickerDialogState extends State<RandomPickerDialog> {
  final _rng = Random();
  String _display = '?';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _spin());
  }

  Future<void> _spin() async {
    final names = widget.names;
    if (names.isEmpty) return;
    setState(() => _done = false);

    final steps = 24 + _rng.nextInt(8);
    var lastIndex = -1;
    for (var i = 0; i < steps; i++) {
      int next;
      do {
        next = _rng.nextInt(names.length);
      } while (names.length > 1 && next == lastIndex);
      lastIndex = next;
      if (!mounted) return;
      setState(() => _display = names[next]);
      HapticFeedback.selectionClick();
      // Delay grows each step => the "wheel" slows down.
      await Future.delayed(Duration(milliseconds: 45 + (i * i * 0.4).round()));
    }
    if (!mounted) return;
    setState(() => _done = true);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.indigo, Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _done ? Icons.celebration_rounded : Icons.casino_rounded,
              color: AppColors.amber,
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              context.t(_done ? 'pickStudent' : 'picking'),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                color: _done ? AppColors.amber : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                child: Text(
                  _display,
                  key: ValueKey(_display),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _done ? 38 : 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white38,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _done ? _spin : null,
                    child: Text(context.t('drawAgain')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _done ? () => Navigator.pop(context, _display) : null,
                    child: Text(context.t('ok')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
