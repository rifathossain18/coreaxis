import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/misc_models.dart';

class PhoneProvider extends ChangeNotifier {
  List<PhoneContact> _contacts = [];

  List<PhoneContact> get contacts => _contacts;

  List<String> get departments =>
      _contacts.map((c) => c.department ?? 'Other').toSet().toList()..sort();

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('phone_contacts', orderBy: 'name ASC');
    _contacts = rows.map(PhoneContact.fromMap).toList();
    notifyListeners();
  }

  Future<void> add(PhoneContact contact) async {
    final db = await DatabaseHelper.instance.database;
    final map = contact.toMap();
    map.remove('id');
    final id = await db.insert('phone_contacts', map);
    _contacts.add(PhoneContact(
      id: id,
      name: contact.name,
      designation: contact.designation,
      department: contact.department,
      mobile: contact.mobile,
      telephone: contact.telephone,
      createdAt: contact.createdAt,
    ));
    notifyListeners();
  }

  Future<void> update(PhoneContact contact) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('phone_contacts', contact.toMap(), where: 'id = ?', whereArgs: [contact.id]);
    final idx = _contacts.indexWhere((c) => c.id == contact.id);
    if (idx != -1) _contacts[idx] = contact;
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('phone_contacts', where: 'id = ?', whereArgs: [id]);
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  List<PhoneContact> byDepartment(String dept) =>
      _contacts.where((c) => (c.department ?? 'Other') == dept).toList();

  List<PhoneContact> search(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return [];
    return _contacts
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            (c.designation ?? '').toLowerCase().contains(query) ||
            (c.department ?? '').toLowerCase().contains(query) ||
            (c.mobile ?? '').contains(query) ||
            (c.telephone ?? '').contains(query))
        .toList();
  }
}

class CalendarProvider extends ChangeNotifier {
  List<CalendarEventModel> _events = [];

  List<CalendarEventModel> get events => _events;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('calendar_events', orderBy: 'date ASC');
    _events = rows.map(CalendarEventModel.fromMap).toList();
    notifyListeners();
  }

  Future<void> add(CalendarEventModel event) async {
    final db = await DatabaseHelper.instance.database;
    final map = event.toMap();
    map.remove('id');
    final id = await db.insert('calendar_events', map);
    _events.add(CalendarEventModel(
      id: id,
      title: event.title,
      date: event.date,
      notes: event.notes,
      remindDayBefore: event.remindDayBefore,
      createdAt: event.createdAt,
    ));
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<CalendarEventModel> onDate(DateTime date) => _events
      .where((e) => e.date.year == date.year && e.date.month == date.month && e.date.day == date.day)
      .toList();

  /// Events happening tomorrow that want a "day before" reminder - shown
  /// as a notice banner at the top of the Dashboard.
  List<CalendarEventModel> get remindersForTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _events
        .where((e) =>
            e.remindDayBefore &&
            e.date.year == tomorrow.year &&
            e.date.month == tomorrow.month &&
            e.date.day == tomorrow.day)
        .toList();
  }
}
