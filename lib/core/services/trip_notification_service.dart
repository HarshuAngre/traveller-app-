
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local reminders one day before each upcoming planned/ongoing trip.
///
/// Reminder IDs are kept in a reserved numeric range so this service never
/// cancels notifications created by another VoyageMate feature or SDK.
class TripNotificationService {
  TripNotificationService._();

  static final TripNotificationService instance =
      TripNotificationService._();

  static const int _reminderIdStart = 1000000000;
  static const int _reminderIdEnd = 2000000000;
  static const int _enabledConfirmationId = 2000000000;

  static const String _channelId = 'voyagemate_trip_reminders';
  static const String _channelName = 'Trip reminders';
  static const String _channelDescription =
      'Reminders sent one day before your planned trips.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to manage trip reminders.');
    }

    return user.id;
  }

  /// Initializes timezone and local notification services.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
    );

    _initialized = true;
  }

  /// Requests Android notification permission after the user enables reminders.
  Future<bool> requestPermission() async {
    await initialize();

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted =
        await androidPlugin?.requestNotificationsPermission();

    // Android versions before API 33 do not require runtime notification
    // permission. A null result means no prompt is available.
    return granted ?? true;
  }

  /// Checks the saved preference and refreshes reminders when enabled.
  ///
  /// If reminders are disabled, clears this service's pending trip reminders.
  Future<int> syncIfEnabled() async {
    await initialize();

    final preference = await _client
        .from('profiles')
        .select('notifications_enabled')
        .eq('id', _userId)
        .maybeSingle();

    if (preference?['notifications_enabled'] != true) {
      await cancelTripReminders();
      return 0;
    }

    return syncUpcomingTripReminders();
  }

  /// Rebuilds scheduled reminders using the signed-in user's trips.
  Future<int> syncUpcomingTripReminders() async {
    await initialize();

    final userId = _userId;

    final today = DateTime.now();

    final todayString =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final response = await _client
        .from('trips')
        .select('id, title, destination, start_date, status')
        .eq('user_id', userId)
        .inFilter('status', ['planned', 'ongoing'])
        .gte('start_date', todayString)
        .order('start_date', ascending: true);

    // Remove only reminders belonging to this service.
    await cancelTripReminders();

    final now = tz.TZDateTime.now(tz.local);

    var scheduledCount = 0;

    for (final row in response) {
      final tripId = row['id']?.toString();
      final startDateValue = row['start_date']?.toString();

      final destination =
          row['destination']?.toString().trim() ?? 'your trip';

      if (tripId == null ||
          startDateValue == null ||
          startDateValue.isEmpty) {
        continue;
      }

      final startDate = DateTime.tryParse(startDateValue);

      if (startDate == null) continue;

      // Reminder is scheduled one day before the trip at 9:00 AM.
      final reminderDate =
          DateTime(startDate.year, startDate.month, startDate.day)
              .subtract(const Duration(days: 1));

      final scheduledDate = tz.TZDateTime(
        tz.local,
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9,
      );

      // Do not schedule reminders for trigger times that have passed.
      if (!scheduledDate.isAfter(now)) continue;

      final tripTitle = row['title']?.toString().trim();

      const notificationTitle = 'Your trip is tomorrow!';

      final notificationBody =
          tripTitle == null || tripTitle.isEmpty
              ? 'Get ready for $destination. Your trip starts tomorrow.'
              : 'Get ready for $tripTitle in $destination. '
                  'Your trip starts tomorrow.';

      final notificationId = _notificationIdForTrip(tripId);

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      );

      await _plugin.zonedSchedule(
        id: notificationId,
        title: notificationTitle,
        body: notificationBody,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.inexactAllowWhileIdle,
      );

      scheduledCount++;
    }

    debugPrint(
      'VoyageMate: scheduled $scheduledCount trip reminder(s).',
    );

    return scheduledCount;
  }

  /// Displays a confirmation when the user enables reminders.
  Future<void> showEnabledConfirmation() async {
    await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
    );

    await _plugin.show(
      id: _enabledConfirmationId,
      title: 'VoyageMate reminders are on',
      body:
          'We will remind you at 9:00 AM the day before each upcoming trip.',
      notificationDetails: notificationDetails,
    );
  }

  /// Cancels only notifications scheduled by this trip-reminder service.
  Future<void> cancelTripReminders() async {
    await initialize();

    final pending = await _plugin.pendingNotificationRequests();

    for (final request in pending) {
      final id = request.id;

      if (id >= _reminderIdStart && id < _reminderIdEnd) {
        await _plugin.cancel(id: id);
      }
    }
  }

  /// Generates a stable notification ID for each trip.
  int _notificationIdForTrip(String tripId) {
    // Stable FNV-1a hash.
    var hash = 0x811c9dc5;

    for (final byte in utf8.encode(tripId)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }

    return _reminderIdStart + (hash % 999999999);
  }
}
