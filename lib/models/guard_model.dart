class GuardModel {
  final int? id;
  final String name;
  final String? idNumber;
  final String? phone;
  final DateTime? joinDate;
  final String designation; // GuardDesignation
  final bool shiftChangeAllowed; // false => fixed "General" shift, no rotation
  final String currentShift; // 'A' | 'B' | 'C' | 'General'
  final String offDay; // weekday name e.g. 'Saturday', or 'Friday' for general
  final bool onDuty; // whether currently inside (checked in for today's shift)
  final bool active;
  final DateTime createdAt;

  GuardModel({
    this.id,
    required this.name,
    this.idNumber,
    this.phone,
    this.joinDate,
    required this.designation,
    this.shiftChangeAllowed = true,
    this.currentShift = 'A',
    this.offDay = 'Saturday',
    this.onDuty = false,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GuardModel copyWith({
    int? id,
    String? name,
    String? idNumber,
    String? phone,
    DateTime? joinDate,
    String? designation,
    bool? shiftChangeAllowed,
    String? currentShift,
    String? offDay,
    bool? onDuty,
    bool? active,
  }) {
    return GuardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      idNumber: idNumber ?? this.idNumber,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      designation: designation ?? this.designation,
      shiftChangeAllowed: shiftChangeAllowed ?? this.shiftChangeAllowed,
      currentShift: currentShift ?? this.currentShift,
      offDay: offDay ?? this.offDay,
      onDuty: onDuty ?? this.onDuty,
      active: active ?? this.active,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'id_number': idNumber,
      'phone': phone,
      'join_date': joinDate?.toIso8601String(),
      'designation': designation,
      'shift_change_allowed': shiftChangeAllowed ? 1 : 0,
      'current_shift': currentShift,
      'off_day': offDay,
      'on_duty': onDuty ? 1 : 0,
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GuardModel.fromMap(Map<String, dynamic> map) {
    return GuardModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      idNumber: map['id_number'] as String?,
      phone: map['phone'] as String?,
      joinDate: map['join_date'] != null ? DateTime.parse(map['join_date'] as String) : null,
      designation: map['designation'] as String,
      shiftChangeAllowed: (map['shift_change_allowed'] as int? ?? 1) == 1,
      currentShift: map['current_shift'] as String? ?? 'A',
      offDay: map['off_day'] as String? ?? 'Saturday',
      onDuty: (map['on_duty'] as int? ?? 0) == 1,
      active: (map['active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class RosterCell {
  final int? id;
  final int guardId;
  final DateTime date;
  final String shiftCode; // A/B/C/O/H/L/G
  final bool isManualOverride;

  RosterCell({
    this.id,
    required this.guardId,
    required this.date,
    required this.shiftCode,
    this.isManualOverride = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guard_id': guardId,
      'date': _dateOnly(date),
      'shift_code': shiftCode,
      'is_manual_override': isManualOverride ? 1 : 0,
    };
  }

  factory RosterCell.fromMap(Map<String, dynamic> map) {
    return RosterCell(
      id: map['id'] as int?,
      guardId: map['guard_id'] as int,
      date: DateTime.parse(map['date'] as String),
      shiftCode: map['shift_code'] as String,
      isManualOverride: (map['is_manual_override'] as int? ?? 0) == 1,
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
