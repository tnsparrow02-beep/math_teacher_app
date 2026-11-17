import 'package:flutter/material.dart';

import 'app_state.dart';
import 'database_helper.dart';
import 'random_picker.dart';
import 'strings.dart';
import 'widgets.dart';

/// List of classes (7ème B1, 8ème B2, Bac Math...). Tap a class to manage its students.
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _db = DatabaseHelper.instance;
  List<SchoolClass> _classes = [];
  Map<int, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final classes = await _db.getClasses();
    final counts = await _db.getStudentCounts();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _counts = counts;
      _loading = false;
    });
  }

  Future<void> _addClass() async {
    final name = await promptText(
      context,
      title: context.t('addClass'),
      label: context.t('className'),
      hint: context.t('classHint'),
    );
    if (name == null || name.isEmpty) return;
    final id = await _db.insertClass(name);
    // The first class created becomes the active one automatically.
    if (AppState.activeClassId.value == null) await AppState.setActiveClass(id);
    _load();
  }

  Future<void> _rename(SchoolClass c) async {
    final name = await promptText(
      context,
      title: context.t('rename'),
      label: context.t('className'),
      initial: c.name,
    );
    if (name == null || name.isEmpty) return;
    await _db.renameClass(c.id!, name);
    _load();
  }

  Future<void> _delete(SchoolClass c) async {
    if (!await confirmDelete(context, what: c.name)) return;
    await _db.deleteClass(c.id!);
    if (AppState.activeClassId.value == c.id) await AppState.setActiveClass(null);
    _load();
  }

  Future<void> _open(SchoolClass c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClassDetailScreen(schoolClass: c)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClass,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('addClass')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? EmptyState(icon: Icons.groups_outlined, message: context.t('noClassesYet'))
              : ValueListenableBuilder<int?>(
                  valueListenable: AppState.activeClassId,
                  builder: (context, activeId, _) {
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _classes.length,
                      itemBuilder: (_, i) {
                        final c = _classes[i];
                        final color = kClassColors[c.id! % kClassColors.length];
                        final isActive = c.id == activeId;
                        return SoftCard(
                          onTap: () => _open(c),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.groups_rounded, color: color),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '${_counts[c.id] ?? 0} ${context.t('studentsCount')}',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: context.t('setActive'),
                                onPressed: () => AppState.setActiveClass(c.id),
                                icon: Icon(
                                  isActive ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: AppColors.amber,
                                  size: 30,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) => v == 'rename' ? _rename(c) : _delete(c),
                                itemBuilder: (_) => [
                                  PopupMenuItem(value: 'rename', child: Text(context.t('rename'))),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(context.t('delete'),
                                        style: const TextStyle(color: AppColors.danger)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

/// Students of one class: add (one or many at once), edit, delete, random draw.
class ClassDetailScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const ClassDetailScreen({super.key, required this.schoolClass});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final _db = DatabaseHelper.instance;
  List<Student> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await _db.getStudents(widget.schoolClass.id!);
    if (!mounted) return;
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final text = await promptText(
      context,
      title: context.t('addStudents'),
      label: context.t('studentName'),
      hint: context.t('oneNamePerLine'),
      multiline: true,
    );
    if (text == null) return;
    final names = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (names.isEmpty) return;
    await _db.insertStudents(widget.schoolClass.id!, names);
    _load();
  }

  Future<void> _edit(Student s) async {
    final name = await promptText(
      context,
      title: context.t('editStudent'),
      label: context.t('studentName'),
      initial: s.name,
    );
    if (name == null || name.isEmpty) return;
    await _db.renameStudent(s.id!, name);
    _load();
  }

  Future<void> _delete(Student s) async {
    if (!await confirmDelete(context, what: s.name)) return;
    await _db.deleteStudent(s.id!);
    _load();
  }

  Future<void> _draw() async {
    if (_students.isEmpty) {
      showSnack(context, context.t('noStudents'));
      return;
    }
    await showDialog<String>(
      context: context,
      builder: (_) => RandomPickerDialog(names: _students.map((s) => s.name).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schoolClass.name),
        actions: [
          IconButton(
            tooltip: context.t('randomStudent'),
            onPressed: _draw,
            icon: const Icon(Icons.casino_rounded, color: AppColors.amber),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(context.t('addStudents')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? EmptyState(icon: Icons.person_outline_rounded, message: context.t('noStudentsYet'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: _students.length,
                  itemBuilder: (_, i) {
                    final s = _students[i];
                    return SoftCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: AppColors.indigo,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: context.t('edit'),
                            onPressed: () => _edit(s),
                            icon: const Icon(Icons.edit_rounded, color: AppColors.indigo),
                          ),
                          IconButton(
                            tooltip: context.t('delete'),
                            onPressed: () => _delete(s),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
