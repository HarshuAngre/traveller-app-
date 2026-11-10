import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase data access for VoyageMate's Packing Checklist.
///
/// All operations are restricted to the signed-in user. Database RLS remains
/// the authoritative access-control layer.
class PackingService {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to manage your packing list.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> fetchTrips() async {
    final response = await _client
        .from('trips')
        .select('id, title, destination, start_date, end_date, created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Loads items for one trip. A null tripId means the general checklist.
  Future<List<Map<String, dynamic>>> fetchItems({String? tripId}) async {
    final baseQuery = _client
        .from('packing_items')
        .select(
          'id, user_id, trip_id, name, category, quantity, is_packed, '
          'notes, created_at',
        )
        .eq('user_id', _userId);

    final response = tripId == null
        ? await baseQuery
            .isFilter('trip_id', null)
            .order('created_at', ascending: false)
        : await baseQuery
            .eq('trip_id', tripId)
            .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addItem({
    required String name,
    required String category,
    required String? tripId,
  }) async {
    await _client.from('packing_items').insert({
      'user_id': _userId,
      'trip_id': tripId,
      'name': name.trim(),
      'category': category,
      'quantity': 1,
      'is_packed': false,
    });
  }

  Future<void> updateItem({
    required String itemId,
    required String name,
    required String category,
  }) async {
    await _client
        .from('packing_items')
        .update({
          'name': name.trim(),
          'category': category,
        })
        .eq('id', itemId)
        .eq('user_id', _userId);
  }

  Future<void> updatePackedStatus({
    required String itemId,
    required bool isPacked,
  }) async {
    await _client
        .from('packing_items')
        .update({'is_packed': isPacked})
        .eq('id', itemId)
        .eq('user_id', _userId);
  }

  Future<void> deleteItem(String itemId) async {
    await _client
        .from('packing_items')
        .delete()
        .eq('id', itemId)
        .eq('user_id', _userId);
  }

  Future<void> deleteItems(List<String> itemIds) async {
    if (itemIds.isEmpty) return;

    await _client
        .from('packing_items')
        .delete()
        .inFilter('id', itemIds)
        .eq('user_id', _userId);
  }

  /// Restores deleted rows for the checklist's Undo actions.
  /// Original IDs are retained so the restored records remain identifiable.
  Future<void> restoreItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;

    final rows = items.map((item) {
      return <String, dynamic>{
        'id': item['id'],
        'user_id': _userId,
        'trip_id': item['trip_id'],
        'name': item['name'],
        'category': item['category'],
        'quantity': item['quantity'] ?? 1,
        'is_packed': item['is_packed'] == true,
        'notes': item['notes'],
      };
    }).toList();

    await _client.from('packing_items').upsert(rows, onConflict: 'id');
  }
}
