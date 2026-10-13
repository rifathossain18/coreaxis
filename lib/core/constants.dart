/// Central place for every fixed list / enum-like string used across the app.
/// Kept as plain strings (not Dart enums) so they can be stored directly in
/// SQLite and JSON without extra mapping code.
library constants;

/// The different "entry" types that all share the same underlying table
/// (see db/database_helper.dart -> entries table) but render with different
/// forms / icons / highlight colors.
class EntryType {
  static const car = 'car'; // visiting car (not owned by the company)
  static const companyCar = 'company_car'; // pre-registered company car
  static const boss = 'boss'; // chairman / MD / director / guest / regular
  static const outsideWorker = 'outside_worker';
  static const supplier = 'supplier';
  static const buyer = 'buyer';
  static const audit = 'audit';

  static const all = [car, companyCar, boss, outsideWorker, supplier, buyer, audit];

  static String label(String type) {
    switch (type) {
      case car:
        return 'Car';
      case companyCar:
        return 'Company Car';
      case boss:
        return 'Boss';
      case outsideWorker:
        return 'Outside Worker';
      case supplier:
        return 'Supplier';
      case buyer:
        return 'Buyer';
      case audit:
        return 'Audit';
      default:
        return type;
    }
  }
}

/// Boss categories - used for special highlight colors.
class BossCategory {
  static const chairman = 'chairman';
  static const md = 'md';
  static const director = 'director';
  static const guest = 'guest';
  static const regular = 'regular';

  static const all = [chairman, md, director, guest, regular];

  static String label(String c) {
    switch (c) {
      case chairman:
        return 'Chairman';
      case md:
        return 'Managing Director';
      case director:
        return 'Director';
      case guest:
        return 'Guest Boss';
      case regular:
        return 'Regular';
      default:
        return c;
    }
  }
}

/// Source of a boss visit: arrived by a (company) car, or from the house.
class BossSource {
  static const car = 'car';
  static const house = 'house';
}

/// Guard designations.
class GuardDesignation {
  static const incharge = 'incharge';
  static const supervisor = 'supervisor';
  static const ladyGuard = 'lady_guard';
  static const guard = 'guard';

  static const all = [incharge, supervisor, ladyGuard, guard];

  static String label(String d) {
    switch (d) {
      case incharge:
        return 'Incharge';
      case supervisor:
        return 'Supervisor';
      case ladyGuard:
        return 'Lady Guard';
      case guard:
        return 'Guard';
      default:
        return d;
    }
  }
}

/// Roster day codes shown on the monthly grid & daily view.
class ShiftCode {
  static const a = 'A'; // Day / Morning
  static const b = 'B'; // Night / Evening
  static const c = 'C'; // Night (only used when 3-shift mode is selected)
  static const off = 'O'; // Weekly off day
  static const holiday = 'H'; // Company holiday
  static const leave = 'L'; // Approved leave
  static const general = 'G'; // Fixed "general" shift (no rotation)
}

class PrefsKeys {
  static const firstLaunchDone = 'first_launch_done';
  static const themeMode = 'theme_mode'; // 'light' | 'dark' | 'system'
}
