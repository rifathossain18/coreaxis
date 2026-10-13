import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/guard_model.dart';
import '../utils/roster_generator.dart';

class RosterProvider extends ChangeNotifier {
  /// date string 'yyyy-MM-dd' -> shift code, per guard id
  final Map<int, Map<String, String>> _cellsByGuard = {};
  final Set<String> _holidays = {}; // company-wide holidays, 'yyyy-MM-dd'
  final Map<int, Set<String>> _leavesByGuard = {};

  Set<String> get holidays => _holidays;

  Map<String, String> cellsFor(int guardId) => _cellsByGuard[guardId] ?? {};

  Set<String> leavesFor(int guardId) => _leavesByGuard[guardId] ?? {};

  Future<void> loadMonth(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final rows = await db.query(
      'roster',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_fmt(start), _fmt(end)],
    );
    _cellsByGuard.clear();
    for (final r in rows) {
      final guardId = r['guard_id'] as int;
      final date = r['date'] as String;
      final code = r['shift_code'] as String;
      _cellsByGuard.putIfAbsent(guardId, () => {})[date] = code;
    }
    notifyListeners();
  }

  Future<void> loadHolidaysAndLeaves(int year, int month) async {
    // Holidays and leaves are represented as roster cells with code H / L,
    // already loaded by loadMonth(); this just re-derives the quick-lookup
    // sets used by the generator and the UI badges.
    _holidays.clear();
    _leavesByGuard.clear();
    _cellsByGuard.forEach((guardId, dateMap) {
      dateMap.forEach((date, code) {
        if (code == 'H') _holidays.add(date);
        if (code == 'L') {
          _leavesByGuard.putIfAbsent(guardId, () => {}).add(date);
        }
      });
    });
    notifyListeners();
  }

  /// Regenerates the month for every guard, respecting manual overrides
  /// and already-marked holidays/leaves. Safe to call repeatedly (e.g. at
  /// the start of a new month) since it never overwrites manual cells.
  Future<void> generateForMonth({
    required List<GuardModel> guards,
    required int year,
    required int month,
    required int shiftCount,
  }) async {
    await loadMonth(year, month);
    await loadHolidaysAndLeaves(year, month);

    final db = await DatabaseHelper.instance.database;

    for (final guard in guards) {
      if (guard.id == null) continue;
      final existingManualRows = await db.query(
        'roster',
        where: 'guard_id = ? AND date >= ? AND date <= ? AND is_manual_override = 1',
        whereArgs: [guard.id, _fmt(DateTime(year, month, 1)), _fmt(DateTime(year, month + 1, 0))],
      );
      final manualMap = {
        for (final r in existingManualRows) r['date'] as String: r['shift_code'] as String
      };
      final cells = RosterGenerator.generateMonth(
        guard: guard,
        year: year,
        month: month,
        shiftCount: shiftCount,
        existingManual: manualMap,
        holidays: _holidays,
        leaves: _leavesByGuard[guard.id] ?? {},
      );
      for (final cell in cells) {
        await db.insert(
          'roster',
          cell.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await loadMonth(year, month);
    await loadHolidaysAndLeaves(year, month);
  }

  Future<void> setCell({
    required int guardId,
    required DateTime date,
    required String shiftCode,
    bool manual = true,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'roster',
      {
        'guard_id': guardId,
        'date': _fmt(date),
        'shift_code': shiftCode,
        'is_manual_override': manual ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cellsByGuard.putIfAbsent(guardId, () => {})[_fmt(date)] = shiftCode;
    if (shiftCode == 'H') _holidays.add(_fmt(date));
    if (shiftCode == 'L') _leavesByGuard.putIfAbsent(guardId, () => {}).add(_fmt(date));
    notifyListeners();
  }

  /// Mark a holiday for ALL guards on a given date (company-wide holiday).
  Future<void> setHolidayForAll({
    required List<GuardModel> guards,
    required DateTime date,
  }) async {
    for (final g in guards) {
      if (g.id == null) continue;
      await setCell(guardId: g.id!, date: date, shiftCode: 'H', manual: true);
    }
  }

  Future<void> setLeave({required int guardId, required DateTime date}) async {
    await setCell(guardId: guardId, date: date, shiftCode: 'L', manual: true);
  }

  String? shiftCodeOn(int guardId, DateTime date) => _cellsByGuard[guardId]?[_fmt(date)];

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
