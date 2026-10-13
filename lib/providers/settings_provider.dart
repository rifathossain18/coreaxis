import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/misc_models.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettingsModel settings = AppSettingsModel.defaults();
  ThemeMode themeMode = ThemeMode.light;
  bool loading = true;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings', where: 'id = 1');
    if (rows.isNotEmpty) {
      final r = rows.first;
      settings = AppSettingsModel(
        companyName: r['company_name'] as String,
        shiftCount: r['shift_count'] as int,
        shiftNames: List<String>.from(jsonDecode(r['shift_names'] as String)),
        shiftTimes: r['shift_times'] != null
            ? Map<String, String>.from(jsonDecode(r['shift_times'] as String))
            : {},
        setupDone: (r['setup_done'] as int) == 1,
      );
    }
    loading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String companyName,
    required int shiftCount,
    required List<String> shiftNames,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'app_settings',
      {
        'id': 1,
        'company_name': companyName,
        'shift_count': shiftCount,
        'shift_names': jsonEncode(shiftNames),
        'shift_times': jsonEncode({}),
        'setup_done': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    settings = AppSettingsModel(
      companyName: companyName,
      shiftCount: shiftCount,
      shiftNames: shiftNames,
      shiftTimes: const {},
      setupDone: true,
    );
    notifyListeners();
  }

  /// Changing the shift count later wipes all entry / roster data, per
  /// the app's rules (announced to the user via a confirmation dialog
  /// before this is called).
  Future<void> changeShiftConfig({
    required int shiftCount,
    required List<String> shiftNames,
  }) async {
    await DatabaseHelper.instance.wipeAllEntryData();
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'app_settings',
      {
        'shift_count': shiftCount,
        'shift_names': jsonEncode(shiftNames),
      },
      where: 'id = 1',
    );
    settings = settings.copyWith(shiftCount: shiftCount, shiftNames: shiftNames);
    notifyListeners();
  }

  Future<void> updateCompanyName(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('app_settings', {'company_name': name}, where: 'id = 1');
    settings = settings.copyWith(companyName: name);
    notifyListeners();
  }

  Future<void> updateShiftTimes(Map<String, String> times) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('app_settings', {'shift_times': jsonEncode(times)}, where: 'id = 1');
    settings = settings.copyWith(shiftTimes: times);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }
}
