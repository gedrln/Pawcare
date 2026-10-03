class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String breed;
  final DateTime birthdate;
  final int ageInMonths;
  final String gender;
  final String? photoUrl;
  final DateTime? createdAt;

  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.birthdate,
    required this.ageInMonths,
    required this.gender,
    this.photoUrl,
    this.createdAt,
  });

  /// Number of complete years.
  int get ageYears => ageInMonths ~/ 12;

  /// Remaining months after complete years.
  int get remainingMonths => ageInMonths % 12;

  /// Human-readable age.
  String get ageLabel {
    if (ageInMonths < 1) {
      return 'Less than 1 month old';
    }

    if (ageYears == 0) {
      return ageInMonths == 1 ? '1 month old' : '$ageInMonths months old';
    }

    if (remainingMonths == 0) {
      return ageYears == 1 ? '1 year old' : '$ageYears years old';
    }

    final yearText = ageYears == 1 ? '1 year' : '$ageYears years';

    final monthText =
        remainingMonths == 1 ? '1 month' : '$remainingMonths months';

    return '$yearText, $monthText old';
  }

  /// Compatibility getter.
  ///
  /// Some existing Pawcare files use `pet.age`.
  /// Keeping this getter prevents those files from breaking.
  String get age => ageLabel;

  /// Birthdate formatted for display.
  String get formattedBirthdate {
    return '${birthdate.month.toString().padLeft(2, '0')}/'
        '${birthdate.day.toString().padLeft(2, '0')}/'
        '${birthdate.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'species': species,
      'breed': breed,
      'birthdate': '${birthdate.year.toString().padLeft(4, '0')}-'
          '${birthdate.month.toString().padLeft(2, '0')}-'
          '${birthdate.day.toString().padLeft(2, '0')}',
      'age_in_months': ageInMonths,
      'gender': gender,
      'photo_url': photoUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    final rawBirthdate = map['birthdate'];
    final rawCreatedAt = map['created_at'];

    DateTime parsedBirthdate;

    if (rawBirthdate is DateTime) {
      parsedBirthdate = rawBirthdate;
    } else {
      parsedBirthdate = DateTime.parse(
        rawBirthdate.toString(),
      );
    }

    DateTime? parsedCreatedAt;

    if (rawCreatedAt != null && rawCreatedAt.toString().isNotEmpty) {
      parsedCreatedAt = rawCreatedAt is DateTime
          ? rawCreatedAt
          : DateTime.tryParse(
              rawCreatedAt.toString(),
            );
    }

    return Pet(
      id: map['id'].toString(),
      ownerId: map['owner_id'].toString(),
      name: map['name']?.toString() ?? '',
      species: map['species']?.toString() ?? '',
      breed: map['breed']?.toString() ?? '',
      birthdate: parsedBirthdate,
      ageInMonths: _toInt(map['age_in_months']),
      gender: map['gender']?.toString() ?? '',
      photoUrl: map['photo_url']?.toString(),
      createdAt: parsedCreatedAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  Pet copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? species,
    String? breed,
    DateTime? birthdate,
    int? ageInMonths,
    String? gender,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return Pet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      birthdate: birthdate ?? this.birthdate,
      ageInMonths: ageInMonths ?? this.ageInMonths,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
