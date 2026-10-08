import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet.dart';

class PetService {
  final SupabaseClient _supabase;

  PetService({
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  User get _currentUser {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw AuthException(
        'You must be logged in to manage pets.',
      );
    }

    return user;
  }

  // =========================================================
  // GET CURRENT USER'S PETS
  // =========================================================

  Future<List<Pet>> getMyPets() async {
    final user = _currentUser;

    final response =
        await _supabase.from('pets').select().eq('owner_id', user.id).order(
              'created_at',
              ascending: true,
            );

    final rows = response as List;

    return rows
        .map(
          (row) => Pet.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  // =========================================================
  // GET ONE PET
  // =========================================================

  Future<Pet?> getPet(
    String petId,
  ) async {
    final user = _currentUser;

    final response = await _supabase
        .from('pets')
        .select()
        .eq('id', petId)
        .eq('owner_id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Pet.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // =========================================================
  // ADD PET
  // =========================================================

  Future<Pet> addPet({
    required String name,
    required String species,
    String breed = '',
    DateTime? birthdate,
    required String gender,
    String petStatus = 'Alive',
    String careNotes = '',
    String funFact = '',
    String healthNote = '',
    Uint8List? photoBytes,
    String? photoExtension,
    String? photoContentType,
  }) async {
    final user = _currentUser;

    final cleanName = name.trim();
    final cleanSpecies = species.trim();
    final cleanBreed = breed.trim();
    final cleanGender = gender.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'Pet name cannot be empty.',
      );
    }

    if (cleanSpecies.isEmpty) {
      throw Exception(
        'Species cannot be empty.',
      );
    }

    if (birthdate != null && birthdate.isAfter(DateTime.now())) {
      throw Exception(
        'Birthdate cannot be in the future.',
      );
    }

    final ageInMonths = birthdate == null ? 0 : _calculateAgeInMonths(birthdate);

    final inserted = await _supabase
        .from('pets')
        .insert({
          'owner_id': user.id,
          'name': cleanName,
          'species': cleanSpecies,
          'breed': cleanBreed,
          'birthdate': birthdate == null ? null : _dateOnly(birthdate),
          'age_in_months': ageInMonths,
          'gender': cleanGender,
          'pet_status': petStatus,
          'fun_fact': funFact.trim(),
          'health_note': healthNote.trim().isNotEmpty
              ? healthNote.trim()
              : careNotes.trim(),
          'care_notes': healthNote.trim().isNotEmpty
              ? healthNote.trim()
              : careNotes.trim(),
        })
        .select()
        .single();

    var pet = Pet.fromMap(
      Map<String, dynamic>.from(inserted),
    );

    // ---------------------------------------------------------
    // UPLOAD PHOTO
    // ---------------------------------------------------------

    if (photoBytes != null && photoBytes.isNotEmpty) {
      try {
        final extension = _cleanExtension(
          photoExtension,
        );

        final contentType = photoContentType ?? _contentTypeFor(extension);

        final path = '${user.id}/${pet.id}.$extension';

        await _supabase.storage.from('pet-photos').uploadBinary(
              path,
              photoBytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: true,
              ),
            );

        final photoUrl =
            _supabase.storage.from('pet-photos').getPublicUrl(path);

        final updated = await _supabase
            .from('pets')
            .update({
              'photo_url': photoUrl,
            })
            .eq('id', pet.id)
            .eq('owner_id', user.id)
            .select()
            .single();

        pet = Pet.fromMap(
          Map<String, dynamic>.from(updated),
        );
      } catch (error) {
        // Remove pet if photo upload fails.
        try {
          await _supabase
              .from('pets')
              .delete()
              .eq('id', pet.id)
              .eq('owner_id', user.id);
        } catch (_) {}

        rethrow;
      }
    }

    return pet;
  }

  // =========================================================
  // COMPATIBILITY METHOD
  //
  // Allows older AddPetPage code using createPet().
  // =========================================================

  Future<Pet> createPet({
    required String name,
    required String species,
    String breed = '',
    DateTime? birthdate,
    required String gender,
    String petStatus = 'Alive',
    String careNotes = '',
    String funFact = '',
    String healthNote = '',
    Uint8List? photoBytes,
    String? photoExtension,
    String? photoContentType,
  }) {
    return addPet(
      name: name,
      species: species,
      breed: breed,
      birthdate: birthdate,
      gender: gender,
      petStatus: petStatus,
      careNotes: careNotes,
      funFact: funFact,
      healthNote: healthNote,
      photoBytes: photoBytes,
      photoExtension: photoExtension,
      photoContentType: photoContentType,
    );
  }

  // =========================================================
  // UPDATE PET
  // =========================================================

  Future<Pet> updateCareNotes({
    required String petId,
    required String careNotes,
  }) async {
    final user = _currentUser;
    final response = await _supabase
        .from('pets')
        .update({
          'care_notes': careNotes.trim(),
          'health_note': careNotes.trim(),
        })
        .eq('id', petId)
        .eq('owner_id', user.id)
        .select()
        .single();

    return Pet.fromMap(Map<String, dynamic>.from(response));
  }

  Future<Pet> updatePetNotes({
    required String petId,
    required String funFact,
    required String healthNote,
  }) async {
    final user = _currentUser;
    final normalizedHealthNote = healthNote.trim();
    final response = await _supabase
        .from('pets')
        .update({
          'fun_fact': funFact.trim(),
          'health_note': normalizedHealthNote,
          'care_notes': normalizedHealthNote,
        })
        .eq('id', petId)
        .eq('owner_id', user.id)
        .select()
        .single();

    return Pet.fromMap(Map<String, dynamic>.from(response));
  }

  Future<Pet> updatePet({
    required String petId,
    required String name,
    required String species,
    String breed = '',
    DateTime? birthdate,
    required String gender,
    String petStatus = 'Alive',
    String? careNotes,
    String? funFact,
    String? healthNote,
    Uint8List? photoBytes,
    String? photoExtension,
    String? photoContentType,
    bool removePhoto = false,
  }) async {
    final user = _currentUser;

    if (name.trim().isEmpty) {
      throw Exception(
        'Pet name cannot be empty.',
      );
    }

    if (species.trim().isEmpty) {
      throw Exception(
        'Species cannot be empty.',
      );
    }

    if (birthdate != null && birthdate.isAfter(DateTime.now())) {
      throw Exception(
        'Birthdate cannot be in the future.',
      );
    }

    final existingPet = await getPet(petId);

    if (existingPet == null) {
      throw Exception(
        'Pet could not be found.',
      );
    }

    String? newPhotoUrl;
    String? newPhotoPath;

    // ---------------------------------------------------------
    // UPLOAD NEW PHOTO
    // ---------------------------------------------------------

    if (photoBytes != null && photoBytes.isNotEmpty) {
      final extension = _cleanExtension(
        photoExtension,
      );

      final contentType = photoContentType ?? _contentTypeFor(extension);

      // Use a fresh object key for each replacement. This prevents the image
      // cache from reusing the previous photo URL after an upload.
      final path =
          '${user.id}/${petId}_${DateTime.now().microsecondsSinceEpoch}.$extension';
      newPhotoPath = path;

      await _supabase.storage.from('pet-photos').uploadBinary(
            path,
            photoBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      newPhotoUrl = _supabase.storage.from('pet-photos').getPublicUrl(path);
    }

    final ageInMonths = birthdate == null ? 0 : _calculateAgeInMonths(birthdate);

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'species': species.trim(),
      'breed': breed.trim(),
      'birthdate': birthdate == null ? null : _dateOnly(birthdate),
      'age_in_months': ageInMonths,
      'gender': gender.trim(),
      'pet_status': petStatus,
    };

    if (careNotes != null) {
      updateData['care_notes'] = careNotes.trim();
      updateData['health_note'] = careNotes.trim();
    }
    if (funFact != null) {
      updateData['fun_fact'] = funFact.trim();
    }
    if (healthNote != null) {
      updateData['health_note'] = healthNote.trim();
      updateData['care_notes'] = healthNote.trim();
    }

    if (newPhotoUrl != null) {
      updateData['photo_url'] = newPhotoUrl;
    } else if (removePhoto) {
      updateData['photo_url'] = null;
    }

    final response = await _supabase
        .from('pets')
        .update(updateData)
        .eq('id', petId)
        .eq('owner_id', user.id)
        .select()
        .single();

    // ---------------------------------------------------------
    // DELETE OLD PHOTO AFTER SUCCESSFUL UPDATE
    // ---------------------------------------------------------

    if ((newPhotoUrl != null || removePhoto) &&
        existingPet.photoUrl != null &&
        existingPet.photoUrl!.isNotEmpty) {
      try {
        final oldPath = _storagePathFromPublicUrl(
          existingPet.photoUrl!,
        );

        // Never remove the new object if a storage path is reused.
        if (oldPath != null && oldPath != newPhotoPath) {
          await _supabase.storage.from('pet-photos').remove([
            oldPath,
          ]);
        }
      } catch (_) {
        // Do not fail the update just because
        // the old photo could not be removed.
      }
    }

    return Pet.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // =========================================================
  // DELETE PET
  // =========================================================

  Future<void> deletePet(
    Pet pet,
  ) async {
    final user = _currentUser;

    if (pet.photoUrl != null && pet.photoUrl!.isNotEmpty) {
      try {
        final path = _storagePathFromPublicUrl(
          pet.photoUrl!,
        );

        if (path != null) {
          await _supabase.storage.from('pet-photos').remove([
            path,
          ]);
        }
      } catch (_) {}
    }

    await _supabase
        .from('pets')
        .delete()
        .eq('id', pet.id)
        .eq('owner_id', user.id);
  }

  // Compatibility method for code that
  // still calls deletePetById().
  Future<void> deletePetById(
    String petId,
  ) async {
    final pet = await getPet(petId);

    if (pet == null) {
      return;
    }

    await deletePet(pet);
  }

  // =========================================================
  // AGE
  // =========================================================

  int _calculateAgeInMonths(
    DateTime birthdate,
  ) {
    final now = DateTime.now();

    var months =
        (now.year - birthdate.year) * 12 + (now.month - birthdate.month);

    if (now.day < birthdate.day) {
      months--;
    }

    if (months < 0) {
      return 0;
    }

    return months;
  }

  // =========================================================
  // DATE
  // =========================================================

  String _dateOnly(
    DateTime date,
  ) {
    final year = date.year.toString().padLeft(
          4,
          '0',
        );

    final month = date.month.toString().padLeft(
          2,
          '0',
        );

    final day = date.day.toString().padLeft(
          2,
          '0',
        );

    return '$year-$month-$day';
  }

  // =========================================================
  // FILE EXTENSION
  // =========================================================

  String _cleanExtension(
    String? extension,
  ) {
    if (extension == null || extension.trim().isEmpty) {
      return 'jpg';
    }

    var value = extension.trim().toLowerCase();

    if (value.startsWith('.')) {
      value = value.substring(1);
    }

    if (value == 'jpeg') {
      return 'jpg';
    }

    if (value.contains('/')) {
      switch (value) {
        case 'image/png':
          return 'png';

        case 'image/webp':
          return 'webp';

        case 'image/heic':
          return 'heic';

        case 'image/gif':
          return 'gif';

        default:
          return 'jpg';
      }
    }

    if (value.isEmpty) {
      return 'jpg';
    }

    return value;
  }

  // =========================================================
  // CONTENT TYPE
  // =========================================================

  String _contentTypeFor(
    String extension,
  ) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'heic':
        return 'image/heic';

      case 'gif':
        return 'image/gif';

      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  // =========================================================
  // STORAGE PATH
  // =========================================================

  String? _storagePathFromPublicUrl(
    String url,
  ) {
    const marker = '/storage/v1/object/public/pet-photos/';

    final index = url.indexOf(marker);

    if (index == -1) {
      return null;
    }

    return Uri.decodeComponent(
      url.substring(
        index + marker.length,
      ),
    );
  }
}
