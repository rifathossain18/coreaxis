import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Single SQLite database for the whole app. Everything lives on-device -
/// there is no network call anywhere in this project.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'coreaxis.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // ---------------------------------------------------------------
    // entries: shared table for Car / Company Car / Boss / Outside
    // Worker / Supplier / Buyer / Audit. A single flexible table keeps
    // the in/out, search, and "who is currently inside" logic identical
    // for every module while `extra` (JSON) stores type-specific fields.
    // ---------------------------------------------------------------
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        subtitle TEXT,
        category TEXT,
        phone TEXT,
        card_number TEXT,
        extra TEXT,
        linked_entry_id INTEGER,
        in_time TEXT,
        out_time TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Saved "regulars" per type, used for one-click suggestion + entry.
    await db.execute('''
      CREATE TABLE frequent_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        subtitle TEXT,
        category TEXT,
        phone TEXT,
        card_number TEXT,
        extra TEXT,
        use_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Security guards master list.
    await db.execute('''
      CREATE TABLE guards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        id_number TEXT,
        phone TEXT,
        join_date TEXT,
        designation TEXT NOT NULL,
        shift_change_allowed INTEGER NOT NULL DEFAULT 1,
        current_shift TEXT NOT NULL DEFAULT 'A',
        off_day TEXT NOT NULL DEFAULT 'Saturday',
        on_duty INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Daily roster cells: one row per guard per date.
    await db.execute('''
      CREATE TABLE roster (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guard_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        shift_code TEXT NOT NULL,
        is_manual_override INTEGER NOT NULL DEFAULT 0,
        UNIQUE(guard_id, date),
        FOREIGN KEY (guard_id) REFERENCES guards (id) ON DELETE CASCADE
      )
    ''');

    // Phone directory.
    await db.execute('''
      CREATE TABLE phone_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        designation TEXT,
        department TEXT,
        mobile TEXT,
        telephone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Calendar events / reminders (e.g. "Chairman visiting on the 10th").
    await db.execute('''
      CREATE TABLE calendar_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        remind_day_before INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Single-row app settings.
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        company_name TEXT NOT NULL,
        shift_count INTEGER NOT NULL DEFAULT 2,
        shift_names TEXT NOT NULL,
        shift_times TEXT,
        setup_done INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_entries_type ON entries(type)');
    await db.execute('CREATE INDEX idx_entries_out ON entries(out_time)');
    await db.execute('CREATE INDEX idx_roster_date ON roster(date)');
    await db.execute('CREATE INDEX idx_roster_guard ON roster(guard_id)');
  }

  /// Wipes every table's rows but keeps the schema - used when the user
  /// changes the shift-count setting (2 <-> 3 shifts), which invalidates
  /// all existing roster/entry data per the app's onboarding rules.
  Future<void> wipeAllEntryData() async {
    final db = await database;
    await db.delete('roster');
    await db.delete('guards');
    await db.delete('entries');
    await db.delete('frequent_templates');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
