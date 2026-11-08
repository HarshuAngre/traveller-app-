import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase reads and writes used by the Budget Tracker.
///
/// Every query is scoped to the currently authenticated user. Supabase RLS
/// remains the final access-control layer on the server.
class BudgetService {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to manage your trip budget.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> fetchTrips() async {
    final response = await _client
        .from('trips')
        .select(
          'id, title, destination, budget_amount, currency, '
          'start_date, end_date, created_at',
        )
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchExpenses(String tripId) async {
    final response = await _client
        .from('trip_expenses')
        .select(
          'id, trip_id, user_id, title, category, amount, currency, '
          'expense_date, payment_method, notes, created_at',
        )
        .eq('trip_id', tripId)
        .eq('user_id', _userId)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateTripBudget({
    required String tripId,
    required double amount,
  }) async {
    await _client
        .from('trips')
        .update({'budget_amount': amount})
        .eq('id', tripId)
        .eq('user_id', _userId);
  }

  Future<void> addExpense({
    required String tripId,
    required String title,
    required String category,
    required double amount,
    required DateTime expenseDate,
  }) async {
    await _client.from('trip_expenses').insert({
      'trip_id': tripId,
      'user_id': _userId,
      'title': title,
      'category': category,
      'amount': amount,
      'currency': 'INR',
      'expense_date': _dateOnly(expenseDate),
    });
  }

  Future<void> updateExpense({
    required String expenseId,
    required String tripId,
    required String title,
    required String category,
    required double amount,
    required DateTime expenseDate,
  }) async {
    await _client
        .from('trip_expenses')
        .update({
          'title': title,
          'category': category,
          'amount': amount,
          'expense_date': _dateOnly(expenseDate),
        })
        .eq('id', expenseId)
        .eq('trip_id', tripId)
        .eq('user_id', _userId);
  }

  Future<void> deleteExpense({
    required String expenseId,
    required String tripId,
  }) async {
    await _client
        .from('trip_expenses')
        .delete()
        .eq('id', expenseId)
        .eq('trip_id', tripId)
        .eq('user_id', _userId);
  }

  /// Restores a recently deleted expense when the user taps UNDO.
  Future<void> restoreExpense(Map<String, dynamic> expense) async {
    await _client.from('trip_expenses').insert({
      'id': expense['id'],
      'trip_id': expense['trip_id'],
      'user_id': _userId,
      'title': expense['title'],
      'category': expense['category'],
      'amount': expense['amount'],
      'currency': expense['currency'] ?? 'INR',
      'expense_date': expense['expense_date'],
      'payment_method': expense['payment_method'],
      'notes': expense['notes'],
    });
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
