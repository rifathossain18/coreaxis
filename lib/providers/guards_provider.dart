import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/guard_model.dart';

class GuardsProvider extends ChangeNotifier {
  List<GuardModel> _guards = [];

  List<GuardModel> get guards => _guards;
  List<GuardModel> get activeGuards => _guards.where((g) => g.active).toList();
  List<GuardModel> get onDutyGuards => _guards.where((g) => g.active && g.onDuty).toList();

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('guards', orderBy: 'name ASC');
    _guards = rows.map(GuardModel.fromMap).toList();
    notifyListeners();
  }

  Future<GuardModel> addGuard(GuardModel guard) async {
    final db = await DatabaseHelper.instance.database;
    final map = guard.toMap();
    map.remove('id');
    final id = await db.insert('guards', map);
    final created = guard.copyWith(id: id);
    _guards.add(created);
    notifyListeners();
    return created;
  }

  Future<void> updateGuard(GuardModel guard) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('guards', guard.toMap(), where: 'id = ?', whereArgs: [guard.id]);
    final idx = _guards.indexWhere((g) => g.id == guard.id);
    if (idx != -1) _guards[idx] = guard;
    notifyListeners();
  }

  Future<void> deleteGuard(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('guards', where: 'id = ?', whereArgs: [id]);
    _guards.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<void> setOnDuty(int id, bool onDuty) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('guards', {'on_duty': onDuty ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
    final idx = _guards.indexWhere((g) => g.id == id);
    if (idx != -1) _guards[idx] = _guards[idx].copyWith(onDuty: onDuty);
    notifyListeners();
  }

  GuardModel? byId(int id) {
    try {
      return _guards.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
