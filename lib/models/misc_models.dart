class PhoneContact {
  final int? id;
  final String name;
  final String? designation;
  final String? department;
  final String? mobile;
  final String? telephone;
  final DateTime createdAt;

  PhoneContact({
    this.id,
    required this.name,
    this.designation,
    this.department,
    this.mobile,
    this.telephone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'designation': designation,
        'department': department,
        'mobile': mobile,
        'telephone': telephone,
        'created_at': createdAt.toIso8601String(),
      };

  factory PhoneContact.fromMap(Map<String, dynamic> map) => PhoneContact(
        id: map['id'] as int?,
        name: map['name'] as String,
        designation: map['designation'] as String?,
        department: map['department'] as String?,
        mobile: map['mobile'] as String?,
        telephone: map['telephone'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class CalendarEventModel {
  final int? id;
  final String title;
  final DateTime date;
  final String? notes;
  final bool remindDayBefore;
  final DateTime createdAt;

  CalendarEventModel({
    this.id,
    required this.title,
    required this.date,
    this.notes,
    this.remindDayBefore = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'notes': notes,
        'remind_day_before': remindDayBefore ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory CalendarEventModel.fromMap(Map<String, dynamic> map) => CalendarEventModel(
        id: map['id'] as int?,
        title: map['title'] as String,
        date: DateTime.parse(map['date'] as String),
        notes: map['notes'] as String?,
        remindDayBefore: (map['remind_day_before'] as int? ?? 1) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class AppSettingsModel {
  final String companyName;
  final int shiftCount; // 2 or 3
  final List<String> shiftNames; // e.g. ['Day Shift','Night Shift']
  final Map<String, String> shiftTimes; // shiftName -> "07:00-19:00"
  final bool setupDone;

  AppSettingsModel({
    required this.companyName,
    required this.shiftCount,
    required this.shiftNames,
    this.shiftTimes = const {},
    this.setupDone = false,
  });

  AppSettingsModel copyWith({
    String? companyName,
    int? shiftCount,
    List<String>? shiftNames,
    Map<String, String>? shiftTimes,
    bool? setupDone,
  }) {
    return AppSettingsModel(
      companyName: companyName ?? this.companyName,
      shiftCount: shiftCount ?? this.shiftCount,
      shiftNames: shiftNames ?? this.shiftNames,
      shiftTimes: shiftTimes ?? this.shiftTimes,
      setupDone: setupDone ?? this.setupDone,
    );
  }

  static AppSettingsModel defaults() => AppSettingsModel(
        companyName: '',
        shiftCount: 2,
        shiftNames: const ['Day Shift', 'Night Shift'],
        shiftTimes: const {},
        setupDone: false,
      );
}
