import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists user-saved destinations using Supabase's saved_destinations table.
/// All operations are scoped to the signed-in user; RLS remains authoritative.
class DestinationService {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to save destinations.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> fetchSavedDestinations() async {
    final response = await _client
        .from('saved_destinations')
        .select(
          'id, user_id, name, address, google_place_id, latitude, '
          'longitude, category, notes, created_at',
        )
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Saves a destination. Reuses an existing same-name/address row if present.
  Future<Map<String, dynamic>> saveDestination({
    required String name,
    required String address,
    required String category,
    String? notes,
    String? googlePlaceId,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'address': address.trim(),
      'category': category.trim(),
      'notes': notes,
      'google_place_id': googlePlaceId,
      'latitude': latitude,
      'longitude': longitude,
    };

    final existing = await _client
        .from('saved_destinations')
        .select('id')
        .eq('user_id', _userId)
        .eq('name', name.trim())
        .eq('address', address.trim())
        .maybeSingle();

    if (existing != null) {
      final updated = await _client
          .from('saved_destinations')
          .update(payload)
          .eq('id', existing['id'].toString())
          .eq('user_id', _userId)
          .select('id, name, address, category')
          .single();
      return Map<String, dynamic>.from(updated);
    }

    final inserted = await _client
        .from('saved_destinations')
        .insert({
          ...payload,
          'user_id': _userId,
        })
        .select('id, name, address, category')
        .single();

    return Map<String, dynamic>.from(inserted);
  }

  Future<void> removeSavedDestination(String destinationId) async {
    await _client
        .from('saved_destinations')
        .delete()
        .eq('id', destinationId)
        .eq('user_id', _userId);
  }
}
