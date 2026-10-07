class PetSchedule {
  final String id;
  final String ownerId;
  final String petId;
  final String petName;
  final String title;
  final String type;
  final DateTime date;
  final int hour;
  final int minute;
  final String notes;
  final String repeat;
  final bool isDone;
  final DateTime? createdAt;

  const PetSchedule({
    required this.id,
    required this.ownerId,
    required this.petId,
    required this.petName,
    required this.title,
    required this.type,
    required this.date,
    required this.hour,
    required this.minute,
    this.notes = '',
    this.repeat = 'Does not repeat',
    this.isDone = false,
    this.createdAt,
  });

  /// Displays the stored time in 12-hour format.
  ///
  /// Example:
  /// 08:30 -> 8:30 AM
  /// 14:00 -> 2:00 PM
  String get time {
    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Complete DateTime for the scheduled event.
  DateTime get scheduledDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  /// Converts the model to a Supabase row.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'pet_id': petId,
      'title': title,
      'type': type,
      'date': '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'time': '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}:00',
      'notes': notes,
      'repeat': repeat,
      'is_done': isDone,
    };
  }

  /// Creates a PetSchedule from a Supabase row.
  ///
  /// petName is supplied separately because the schedule table stores
  /// pet_id rather than duplicating the pet's name.
  factory PetSchedule.fromMap(
    Map<String, dynamic> map, {
    required String petName,
  }) {
    final rawDate = map['date'];

    final parsedDate =
        rawDate is DateTime ? rawDate : DateTime.parse(rawDate.toString());

    final rawTime = map['time']?.toString() ?? '00:00:00';

    final timeParts = rawTime.split(':');

    final parsedHour =
        timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;

    final parsedMinute =
        timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    final rawCreatedAt = map['created_at'];

    DateTime? parsedCreatedAt;

    if (rawCreatedAt != null) {
      if (rawCreatedAt is DateTime) {
        parsedCreatedAt = rawCreatedAt;
      } else {
        parsedCreatedAt = DateTime.tryParse(
          rawCreatedAt.toString(),
        );
      }
    }

    return PetSchedule(
      id: map['id'].toString(),
      ownerId: map['owner_id'].toString(),
      petId: map['pet_id'].toString(),
      petName: petName,
      title: map['title']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Other',
      date: DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      ),
      hour: parsedHour,
      minute: parsedMinute,
      notes: map['notes']?.toString() ?? '',
      repeat: map['repeat']?.toString() ?? 'Does not repeat',
      isDone: map['is_done'] == true ||
          map['is_done']?.toString().toLowerCase() == 'true',
      createdAt: parsedCreatedAt,
    );
  }

  PetSchedule copyWith({
    String? id,
    String? ownerId,
    String? petId,
    String? petName,
    String? title,
    String? type,
    DateTime? date,
    int? hour,
    int? minute,
    String? notes,
    String? repeat,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return PetSchedule(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      notes: notes ?? this.notes,
      repeat: repeat ?? this.repeat,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
