import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet.dart';
import '../models/pet_schedule.dart';

class PetScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  final Random _random = Random.secure();

  String get _currentUserId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in to manage schedules.',
      );
    }

    return user.id;
  }

  // ==========================================
  // GET ALL USER SCHEDULES
  // ==========================================

  Future<List<PetSchedule>> getMySchedules() async {
    final userId = _currentUserId;

    // Get the user's pets first so we can display
    // the current pet name with each schedule.
    final petRows =
        await _supabase.from('pets').select('id, name').eq('owner_id', userId);

    final Map<String, String> petNames = {};

    for (final row in petRows) {
      petNames[row['id'].toString()] = row['name']?.toString() ?? 'Pet';
    }

    final rows = await _supabase
        .from('pet_schedules')
        .select()
        .eq('owner_id', userId)
        .order('date', ascending: true)
        .order('time', ascending: true);

    return rows.map<PetSchedule>((row) {
      final map = Map<String, dynamic>.from(row);

      final petId = map['pet_id'].toString();

      return PetSchedule.fromMap(
        map,
        petName: petNames[petId] ?? 'Pet',
      );
    }).toList();
  }

  // ==========================================
  // GET TODAY'S SCHEDULES
  // ==========================================

  Future<List<PetSchedule>> getTodaySchedules() async {
    final schedules = await getMySchedules();

    final now = DateTime.now();

    return schedules.where((schedule) {
      return schedule.date.year == now.year &&
          schedule.date.month == now.month &&
          schedule.date.day == now.day;
    }).toList();
  }

  // ==========================================
  // CREATE
  // ==========================================

  Future<PetSchedule> createSchedule({
    required Pet pet,
    required String title,
    required String type,
    required DateTime date,
    required int hour,
    required int minute,
    String notes = '',
    String repeat = 'Does not repeat',
  }) async {
    final userId = _currentUserId;

    final id = _newId();

    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final dateString = '${dateOnly.year.toString().padLeft(4, '0')}-'
        '${dateOnly.month.toString().padLeft(2, '0')}-'
        '${dateOnly.day.toString().padLeft(2, '0')}';

    final timeString = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';

    final row = await _supabase
        .from('pet_schedules')
        .insert({
          'id': id,
          'owner_id': userId,
          'pet_id': pet.id,
          'title': title.trim(),
          'type': type,
          'date': dateString,
          'time': timeString,
          'notes': notes.trim(),
          'repeat': repeat,
        })
        .select()
        .single();

    return PetSchedule.fromMap(
      Map<String, dynamic>.from(row),
      petName: pet.name,
    );
  }

  // ==========================================
  // UPDATE
  // ==========================================

  Future<PetSchedule> updateSchedule({
    required String scheduleId,
    required Pet pet,
    required String title,
    required String type,
    required DateTime date,
    required int hour,
    required int minute,
    required String notes,
    required String repeat,
  }) async {
    final userId = _currentUserId;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateString = '${dateOnly.year.toString().padLeft(4, '0')}-'
        '${dateOnly.month.toString().padLeft(2, '0')}-'
        '${dateOnly.day.toString().padLeft(2, '0')}';
    final timeString = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';

    final row = await _supabase
        .from('pet_schedules')
        .update({
          'pet_id': pet.id,
          'title': title.trim(),
          'type': type,
          'date': dateString,
          'time': timeString,
          'notes': notes.trim(),
          'repeat': repeat,
        })
        .eq('id', scheduleId)
        .eq('owner_id', userId)
        .select()
        .single();

    return PetSchedule.fromMap(
      Map<String, dynamic>.from(row),
      petName: pet.name,
    );
  }

  // ==========================================
  // UPDATE COMPLETION STATUS
  // ==========================================

  Future<void> updateScheduleStatus({
    required String scheduleId,
    required bool isDone,
  }) async {
    await _supabase
        .from('pet_schedules')
        .update({'is_done': isDone})
        .eq('id', scheduleId)
        .eq('owner_id', _currentUserId)
        .select('id')
        .single();
  }

  // ==========================================
  // DELETE
  // ==========================================

  Future<void> deleteSchedule(
    String scheduleId,
  ) async {
    await _supabase
        .from('pet_schedules')
        .delete()
        .eq('id', scheduleId)
        .eq('owner_id', _currentUserId);
  }

  // ==========================================
  // GET USER PETS
  // ==========================================

  Future<List<Pet>> getMyPets() async {
    final userId = _currentUserId;

    final rows = await _supabase
        .from('pets')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: true);

    return rows.map<Pet>((row) {
      return Pet.fromMap(
        Map<String, dynamic>.from(row),
      );
    }).toList();
  }

  String _newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    // Set the UUID version (4) and variant bits.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
