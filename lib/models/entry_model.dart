import 'dart:convert';

/// Represents one row in the `entries` table. `extra` holds a JSON map of
/// whatever fields are specific to that entry's `type` (see below).
///
/// Expected `extra` keys per type:
///   car            -> {carNo, driverLicense, driverPhone, companyName, isCompanyCar:false}
///   company_car    -> {carNo, driverLicense, driverPhone, assignedBossName}
///   boss           -> {designation, source: 'car'|'house'}
///   outside_worker -> {purpose, seeingWhom}
///   supplier       -> {companyName}
///   buyer          -> {companyName}
///   audit          -> {companyName}
class EntryModel {
  final int? id;
  final String type;
  final String name;
  final String? subtitle;
  final String? category;
  final String? phone;
  final String? cardNumber;
  final Map<String, dynamic> extra;
  final int? linkedEntryId;
  final DateTime? inTime;
  final DateTime? outTime;
  final DateTime createdAt;

  EntryModel({
    this.id,
    required this.type,
    required this.name,
    this.subtitle,
    this.category,
    this.phone,
    this.cardNumber,
    Map<String, dynamic>? extra,
    this.linkedEntryId,
    this.inTime,
    this.outTime,
    DateTime? createdAt,
  })  : extra = extra ?? {},
        createdAt = createdAt ?? DateTime.now();

  bool get isInside => inTime != null && outTime == null;

  EntryModel copyWith({
    int? id,
    String? type,
    String? name,
    String? subtitle,
    String? category,
    String? phone,
    String? cardNumber,
    Map<String, dynamic>? extra,
    int? linkedEntryId,
    DateTime? inTime,
    bool clearInTime = false,
    DateTime? outTime,
    bool clearOutTime = false,
  }) {
    return EntryModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      cardNumber: cardNumber ?? this.cardNumber,
      extra: extra ?? this.extra,
      linkedEntryId: linkedEntryId ?? this.linkedEntryId,
      inTime: clearInTime ? null : (inTime ?? this.inTime),
      outTime: clearOutTime ? null : (outTime ?? this.outTime),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'subtitle': subtitle,
      'category': category,
      'phone': phone,
      'card_number': cardNumber,
      'extra': jsonEncode(extra),
      'linked_entry_id': linkedEntryId,
      'in_time': inTime?.toIso8601String(),
      'out_time': outTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EntryModel.fromMap(Map<String, dynamic> map) {
    return EntryModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      name: map['name'] as String,
      subtitle: map['subtitle'] as String?,
      category: map['category'] as String?,
      phone: map['phone'] as String?,
      cardNumber: map['card_number'] as String?,
      extra: map['extra'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['extra'] as String))
          : {},
      linkedEntryId: map['linked_entry_id'] as int?,
      inTime: map['in_time'] != null ? DateTime.parse(map['in_time'] as String) : null,
      outTime: map['out_time'] != null ? DateTime.parse(map['out_time'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// A saved "regular" (frequent) entry template, used to populate the
/// name-suggestion field and to do a true one-click in/out entry.
class FrequentTemplate {
  final int? id;
  final String type;
  final String name;
  final String? subtitle;
  final String? category;
  final String? phone;
  final String? cardNumber;
  final Map<String, dynamic> extra;
  final int useCount;
  final DateTime createdAt;

  FrequentTemplate({
    this.id,
    required this.type,
    required this.name,
    this.subtitle,
    this.category,
    this.phone,
    this.cardNumber,
    Map<String, dynamic>? extra,
    this.useCount = 0,
    DateTime? createdAt,
  })  : extra = extra ?? {},
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'subtitle': subtitle,
      'category': category,
      'phone': phone,
      'card_number': cardNumber,
      'extra': jsonEncode(extra),
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FrequentTemplate.fromMap(Map<String, dynamic> map) {
    return FrequentTemplate(
      id: map['id'] as int?,
      type: map['type'] as String,
      name: map['name'] as String,
      subtitle: map['subtitle'] as String?,
      category: map['category'] as String?,
      phone: map['phone'] as String?,
      cardNumber: map['card_number'] as String?,
      extra: map['extra'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['extra'] as String))
          : {},
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Build a fresh EntryModel (checked-in now) from this template.
  EntryModel toNewEntry() {
    return EntryModel(
      type: type,
      name: name,
      subtitle: subtitle,
      category: category,
      phone: phone,
      cardNumber: cardNumber,
      extra: Map<String, dynamic>.from(extra),
      inTime: DateTime.now(),
    );
  }
}
