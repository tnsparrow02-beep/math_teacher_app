import 'package:flutter/material.dart';
import 'database_helper.dart';

/// Tiny global state: current language and the active class (used by the quiz).
/// Both values are saved in the local database so they survive app restarts.
class AppState {
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));
  static final ValueNotifier<int?> activeClassId = ValueNotifier(null);

  static Future<void> load() async {
    final db = DatabaseHelper.instance;
    locale.value = Locale(await db.getSetting('lang') ?? 'ar');
    activeClassId.value = int.tryParse(await db.getSetting('activeClass') ?? '');
  }

  static Future<void> setLocale(String code) async {
    locale.value = Locale(code);
    await DatabaseHelper.instance.setSetting('lang', code);
  }

  static Future<void> setActiveClass(int? id) async {
    activeClassId.value = id;
    await DatabaseHelper.instance.setSetting('activeClass', id?.toString() ?? '');
  }
}
