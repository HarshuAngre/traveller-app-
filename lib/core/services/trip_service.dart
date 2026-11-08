import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trip.dart';

class TripService {
  TripService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be signed in to manage trips.');
    }
    return userId;
  }

  Future<List<Trip>> fetchTrips() async {
    final rows = await _client
        .from('trips')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows
        .map((row) => Trip.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Trip> createTrip({
    required String destination,
    required String country,
    required DateTime startDate,
    required DateTime endDate,
    required double budgetAmount,
    required String notes,
  }) async {
    final cleanDestination = destination.trim();
    if (cleanDestination.isEmpty) {
      throw ArgumentError('Destination cannot be empty.');
    }
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date cannot be before start date.');
    }
    if (budgetAmount <= 0) {
      throw ArgumentError('Budget must be greater than zero.');
    }

    final row = await _client
        .from('trips')
        .insert({
          'user_id': _userId,
          'title': 'Trip to $cleanDestination',
          'destination': cleanDestination,
          'country': country.trim().isEmpty ? null : country.trim(),
          'description': notes.trim().isEmpty ? null : notes.trim(),
          'start_date': Trip.dateOnly(startDate),
          'end_date': Trip.dateOnly(endDate),
          'budget_amount': budgetAmount,
          'currency': 'INR',
          'status': 'planned',
        })
        .select()
        .single();

    return Trip.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Trip> updateTrip({
    required String id,
    required String destination,
    required String country,
    required DateTime startDate,
    required DateTime endDate,
    required double budgetAmount,
    required String notes,
  }) async {
    final cleanDestination = destination.trim();
    if (cleanDestination.isEmpty) {
      throw ArgumentError('Destination cannot be empty.');
    }
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date cannot be before start date.');
    }
    if (budgetAmount <= 0) {
      throw ArgumentError('Budget must be greater than zero.');
    }

    final row = await _client
        .from('trips')
        .update({
          'title': 'Trip to $cleanDestination',
          'destination': cleanDestination,
          'country': country.trim().isEmpty ? null : country.trim(),
          'description': notes.trim().isEmpty ? null : notes.trim(),
          'start_date': Trip.dateOnly(startDate),
          'end_date': Trip.dateOnly(endDate),
          'budget_amount': budgetAmount,
        })
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();

    return Trip.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteTrip(String id) async {
    await _client.from('trips').delete().eq('id', id).eq('user_id', _userId);
  }
}
