import '../core/constants.dart';
import '../models/guard_model.dart';


class RosterGenerator {
  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static List<String> shiftSequence(int shiftCount) {
    return shiftCount >= 3 ? [ShiftCode.a, ShiftCode.b, ShiftCode.c] : [ShiftCode.a, ShiftCode.b];
  }

  static int weekdayNumberFromName(String name) {
    final idx = _weekdayNames.indexOf(name);
    return idx == -1 ? DateTime.saturday : idx + 1; // DateTime.weekday is 1=Mon..7=Sun
  }

  /// [existingManual] maps 'yyyy-MM-dd' -> shift code for cells the user
  /// has hand-edited; these are preserved as-is.
  /// [holidays] and [leaves] are sets of 'yyyy-MM-dd' strings.
  static List<RosterCell> generateMonth({
    required GuardModel guard,
    required int year,
    required int month,
    required int shiftCount,
    Map<String, String> existingManual = const {},
    Set<String> holidays = const {},
    Set<String> leaves = const {},
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final sequence = shiftSequence(shiftCount);
    int shiftIndex = sequence.indexOf(guard.currentShift);
    if (shiftIndex == -1) shiftIndex = 0;

    final offWeekday = guard.shiftChangeAllowed
        ? weekdayNumberFromName(guard.offDay)
        : DateTime.friday;

    final cells = <RosterCell>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dateStr = _fmt(date);

      if (existingManual.containsKey(dateStr)) {
        cells.add(RosterCell(
          guardId: guard.id ?? 0,
          date: date,
          shiftCode: existingManual[dateStr]!,
          isManualOverride: true,
        ));
        continue;
      }

      String code;
      if (holidays.contains(dateStr)) {
        code = ShiftCode.holiday;
      } else if (leaves.contains(dateStr)) {
        code = ShiftCode.leave;
      } else if (!guard.shiftChangeAllowed) {
        code = date.weekday == offWeekday ? ShiftCode.off : ShiftCode.general;
      } else if (date.weekday == offWeekday) {
        code = ShiftCode.off;
      } else {
        code = sequence[shiftIndex];
      }

      cells.add(RosterCell(guardId: guard.id ?? 0, date: date, shiftCode: code));

      // Rotate to next shift right after an off day (rotating guards only).
      if (guard.shiftChangeAllowed && date.weekday == offWeekday) {
        shiftIndex = (shiftIndex + 1) % sequence.length;
      }
    }

    return cells;
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
