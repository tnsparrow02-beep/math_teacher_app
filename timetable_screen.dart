import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'strings.dart';
import 'widgets.dart';

/// Weekly timetable: Monday–Saturday x 8 periods. Tap a cell to assign a class and a room.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const List<String> kPeriodTimes = [
    '08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00',
  ];
  static const double _timeColWidth = 68;
  static const double _cellWidth = 98;
  static const double _cellHeight = 76;

  final _db = DatabaseHelper.instance;
  Map<String, TimetableEntry> _grid = {};
  List<SchoolClass> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _db.getTimetable();
    final classes = await _db.getClasses();
    if (!mounted) return;
    setState(() {
      _grid = {for (final e in entries) '${e.day}-${e.slot}': e};
      _classes = classes;
      _loading = false;
    });
  }

  Future<void> _editSlot(int day, int slot) async {
    if (_classes.isEmpty) {
      showSnack(context, context.t('noClasses'));
      return;
    }
    final existing = _grid['$day-$slot'];
    int? selected = existing?.classId;
    final room = TextEditingController(text: existing?.room ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: Text('${c.t('d$day')} • ${c.t('period')} ${slot + 1} (${kPeriodTimes[slot]})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.t('pickClassForSlot'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final cls in _classes)
                      ChoiceChip(
                        label: Text(cls.name),
                        selected: selected == cls.id,
                        onSelected: (_) => setLocal(() => selected = cls.id),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: room, decoration: fieldDecoration(c.t('room'))),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.pop(c, 'clear'),
                child: Text(c.t('clearSlot'), style: const TextStyle(color: AppColors.danger)),
              ),
            TextButton(onPressed: () => Navigator.pop(c), child: Text(c.t('cancel'))),
            FilledButton(
              onPressed: selected == null ? null : () => Navigator.pop(c, 'save'),
              child: Text(c.t('save')),
            ),
          ],
        ),
      ),
    );

    if (result == 'save' && selected != null) {
      await _db.setTimetableSlot(day, slot, selected!, room.text.trim());
    } else if (result == 'clear') {
      await _db.clearTimetableSlot(day, slot);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final today = DateTime.now().weekday; // 1 = Monday

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Day headers
              Row(
                children: [
                  const SizedBox(width: _timeColWidth),
                  for (var d = 1; d <= 6; d++)
                    Container(
                      width: _cellWidth,
                      height: 46,
                      margin: const EdgeInsets.all(3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: d == today ? AppColors.amber : AppColors.indigo,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        context.t('d$d'),
                        style: TextStyle(
                          color: d == today ? AppColors.ink : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                ],
              ),
              // Period rows
              for (var slot = 0; slot < kPeriodTimes.length; slot++)
                Row(
                  children: [
                    SizedBox(
                      width: _timeColWidth,
                      child: Column(
                        children: [
                          Text(
                            '${context.t('period')} ${slot + 1}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            kPeriodTimes[slot],
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    for (var d = 1; d <= 6; d++) _cell(d, slot),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(int day, int slot) {
    final entry = _grid['$day-$slot'];
    final color = entry == null ? Colors.grey : kClassColors[entry.classId % kClassColors.length];

    return GestureDetector(
      onTap: () => _editSlot(day, slot),
      child: Container(
        width: _cellWidth,
        height: _cellHeight,
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: entry == null ? Colors.white : color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: entry == null ? Colors.grey.shade300 : color,
            width: entry == null ? 1 : 2,
          ),
        ),
        child: entry == null
            ? Icon(Icons.add_rounded, color: Colors.grey.shade400)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.className,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color),
                  ),
                  if (entry.room.isNotEmpty)
                    Text(
                      entry.room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                ],
              ),
      ),
    );
  }
}
