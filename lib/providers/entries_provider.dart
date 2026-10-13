import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/entry_model.dart';

/// Handles every module built on the shared `entries` table: Car, Company
/// Car, Boss, Outside Worker, Supplier, Buyer, Audit.
class EntriesProvider extends ChangeNotifier {
  List<EntryModel> _all = [];
  List<FrequentTemplate> _templates = [];

  List<EntryModel> get all => _all;

  List<EntryModel> byType(String type) => _all.where((e) => e.type == type).toList()
    ..sort((a, b) => (b.inTime ?? b.createdAt).compareTo(a.inTime ?? a.createdAt));

  /// Entries of [type] that are currently inside the company (checked in,
  /// not checked out yet). This is exactly what the Dashboard should show.
  List<EntryModel> currentlyInside(String type) =>
      byType(type).where((e) => e.isInside).toList();

  List<EntryModel> get allCurrentlyInside => _all.where((e) => e.isInside).toList();

  List<FrequentTemplate> templatesFor(String type) =>
      _templates.where((t) => t.type == type).toList()
        ..sort((a, b) => b.useCount.compareTo(a.useCount));

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final entryRows = await db.query('entries', orderBy: 'created_at DESC');
    _all = entryRows.map(EntryModel.fromMap).toList();
    final tplRows = await db.query('frequent_templates');
    _templates = tplRows.map(FrequentTemplate.fromMap).toList();
    notifyListeners();
  }

  Future<EntryModel> checkIn(EntryModel entry, {bool saveAsFrequent = false}) async {
    final db = await DatabaseHelper.instance.database;
    final map = entry.copyWith(inTime: entry.inTime ?? DateTime.now()).toMap();
    map.remove('id');
    final id = await db.insert('entries', map);
    final created = entry.copyWith(id: id, inTime: entry.inTime ?? DateTime.now());
    _all.insert(0, created);

    if (saveAsFrequent) {
      await _upsertTemplate(created);
    }
    notifyListeners();
    return created;
  }

  Future<void> checkOut(int entryId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    await db.update('entries', {'out_time': now.toIso8601String()},
        where: 'id = ?', whereArgs: [entryId]);
    final idx = _all.indexWhere((e) => e.id == entryId);
    if (idx != -1) {
      _all[idx] = _all[idx].copyWith(outTime: now);
    }
    notifyListeners();
  }

  /// Re-open (undo checkout) - used by the edit screen if a mistake is made.
  Future<void> reopen(int entryId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('entries', {'out_time': null}, where: 'id = ?', whereArgs: [entryId]);
    final idx = _all.indexWhere((e) => e.id == entryId);
    if (idx != -1) {
      _all[idx] = _all[idx].copyWith(clearOutTime: true);
    }
    notifyListeners();
  }

  Future<void> updateEntry(EntryModel entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
    final idx = _all.indexWhere((e) => e.id == entry.id);
    if (idx != -1) _all[idx] = entry;
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
    _all.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> _upsertTemplate(EntryModel entry) async {
    final db = await DatabaseHelper.instance.database;
    final existing = _templates.firstWhere(
      (t) => t.type == entry.type && t.name.toLowerCase() == entry.name.toLowerCase(),
      orElse: () => FrequentTemplate(type: entry.type, name: '__none__'),
    );
    if (existing.name == '__none__') {
      final tpl = FrequentTemplate(
        type: entry.type,
        name: entry.name,
        subtitle: entry.subtitle,
        category: entry.category,
        phone: entry.phone,
        cardNumber: entry.cardNumber,
        extra: entry.extra,
        useCount: 1,
      );
      final map = tpl.toMap();
      map.remove('id');
      final id = await db.insert('frequent_templates', map);
      _templates.add(FrequentTemplate(
        id: id,
        type: tpl.type,
        name: tpl.name,
        subtitle: tpl.subtitle,
        category: tpl.category,
        phone: tpl.phone,
        cardNumber: tpl.cardNumber,
        extra: tpl.extra,
        useCount: tpl.useCount,
      ));
    } else {
      await db.update('frequent_templates', {'use_count': existing.useCount + 1},
          where: 'id = ?', whereArgs: [existing.id]);
      final idx = _templates.indexWhere((t) => t.id == existing.id);
      _templates[idx] = FrequentTemplate(
        id: existing.id,
        type: existing.type,
        name: existing.name,
        subtitle: existing.subtitle,
        category: existing.category,
        phone: existing.phone,
        cardNumber: existing.cardNumber,
        extra: existing.extra,
        useCount: existing.useCount + 1,
      );
    }
  }

  /// Registers a "regular" template directly (e.g. pre-registering a
  /// company car or a frequent boss/worker/supplier) WITHOUT creating a
  /// live entries row. Use this instead of checkIn() when you just want
  /// the name to show up as a one-click suggestion later.
  Future<FrequentTemplate> addTemplateOnly(FrequentTemplate tpl) async {
    final db = await DatabaseHelper.instance.database;
    final map = tpl.toMap();
    map.remove('id');
    final id = await db.insert('frequent_templates', map);
    final created = FrequentTemplate(
      id: id,
      type: tpl.type,
      name: tpl.name,
      subtitle: tpl.subtitle,
      category: tpl.category,
      phone: tpl.phone,
      cardNumber: tpl.cardNumber,
      extra: tpl.extra,
      useCount: tpl.useCount,
      createdAt: tpl.createdAt,
    );
    _templates.add(created);
    notifyListeners();
    return created;
  }

  /// One-click check-in using a saved template (used everywhere the
  /// requirements ask for "type the name, tap the suggestion, done").
  Future<EntryModel> oneClickCheckIn(FrequentTemplate tpl) async {
    return checkIn(tpl.toNewEntry());
  }

  Future<void> markTemplateUsed(FrequentTemplate tpl) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('frequent_templates', {'use_count': tpl.useCount + 1},
        where: 'id = ?', whereArgs: [tpl.id]);
  }

  Future<void> deleteTemplate(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('frequent_templates', where: 'id = ?', whereArgs: [id]);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Full-text-ish search across name / subtitle / phone / card number,
  /// optionally scoped to one type.
  List<EntryModel> search(String query, {String? type}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _all.where((e) {
      if (type != null && e.type != type) return false;
      return e.name.toLowerCase().contains(q) ||
          (e.subtitle ?? '').toLowerCase().contains(q) ||
          (e.phone ?? '').toLowerCase().contains(q) ||
          (e.cardNumber ?? '').toLowerCase().contains(q) ||
          e.extra.values.any((v) => v.toString().toLowerCase().contains(q));
    }).toList();
  }

  /// Boss auto check-in linked to a car that just checked in (the
  /// "boss riding in this car" shortcut described in the requirements).
  Future<EntryModel> checkInBossWithCar({
    required String bossName,
    required String designation,
    required String category,
    required int carEntryId,
  }) async {
    final entry = EntryModel(
      type: 'boss',
      name: bossName,
      subtitle: designation,
      category: category,
      extra: {'designation': designation, 'source': 'car'},
      linkedEntryId: carEntryId,
      inTime: DateTime.now(),
    );
    return checkIn(entry);
  }

  /// When a car linked to a boss checks out, also check the boss out.
  Future<void> checkOutLinkedBoss(int carEntryId) async {
    final linked = _all.where((e) => e.type == 'boss' && e.linkedEntryId == carEntryId && e.isInside);
    for (final b in linked) {
      await checkOut(b.id!);
    }
  }
}
