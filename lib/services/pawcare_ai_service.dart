import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/pet.dart';

class PawcareAiService {
  final SupabaseClient _supabase;

  PawcareAiService({
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  Future<String> ask({
    required String message,
    required Pet pet,
    required List<Map<String, String>> conversation,
  }) async {
    final response = await _supabase.functions.invoke(
      AppConstants.pawcareAiFunction,
      body: {
        'message': message,
        'pet': {
          'name': pet.name,
          'species': pet.species,
          'breed': pet.breed,
          'age': pet.ageLabel,
          'gender': pet.gender,
          'birthdate': pet.birthdate.toIso8601String(),
        },
        'conversation': conversation,
      },
    );

    final data = response.data;

    if (data is Map && data['reply'] is String) {
      return data['reply'] as String;
    }

    if (data is Map && data['error'] is String) {
      throw Exception(data['error']);
    }

    throw Exception(
      'Pawcare AI returned an unexpected response.',
    );
  }
}
