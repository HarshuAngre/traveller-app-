import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Calls Supabase and verifies that the database responds.
  static Future<Map<String, dynamic>> checkBackend() async {
    final response = await client.rpc('voyagemate_backend_health');

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw StateError('Unexpected response from VoyageMate backend.');
  }
}
