import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and updates the signed-in user's VoyageMate profile and travel stats.
/// All database and Storage operations are scoped to the current user; RLS is
/// the server-side authorization boundary.
class ProfileService {
  static const String _profilePhotoBucket = 'profile-photos';
  static const int _signedUrlLifetimeSeconds = 604800; // 7 days

  SupabaseClient get _client => Supabase.instance.client;

  User get _user {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to access your profile.');
    }
    return user;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final user = _user;
    final row = await _client
        .from('profiles')
        .select('full_name, phone, home_city, avatar_url, notifications_enabled')
        .eq('id', user.id)
        .maybeSingle();

    final metadataName = user.userMetadata?['full_name']?.toString() ??
        user.userMetadata?['name']?.toString();

    final avatarPath = row?['avatar_url']?.toString();
    String? signedAvatarUrl;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        signedAvatarUrl = await _client.storage
            .from(_profilePhotoBucket)
            .createSignedUrl(avatarPath, _signedUrlLifetimeSeconds);
      } catch (error) {
        // Keep the rest of the profile usable if a photo is missing or Storage
        // has not been configured yet.
        debugPrint('Profile photo URL error: $error');
      }
    }

    return {
      'full_name': row?['full_name'] ?? metadataName ?? '',
      'phone': row?['phone'] ?? '',
      'home_city': row?['home_city'] ?? '',
      'avatar_url': signedAvatarUrl,
      'notifications_enabled': row?['notifications_enabled'] as bool? ?? false,
      'email': user.email ?? '',
    };
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String homeCity,
  }) async {
    final user = _user;

    await _client.from('profiles').upsert(
      {
        'id': user.id,
        'full_name': fullName.trim(),
        'phone': phone.trim().isEmpty ? null : phone.trim(),
        'home_city': homeCity.trim().isEmpty ? null : homeCity.trim(),
      },
      onConflict: 'id',
    );
  }

  /// Uploads a private profile photo and stores its Storage object path in
  /// profiles.avatar_url. A short-lived signed URL is returned for display.
  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final user = _user;
    final extension = fileExtension.toLowerCase();
    const allowedContentTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };

    if (!allowedContentTypes.containsKey(extension) ||
        allowedContentTypes[extension] != contentType) {
      throw ArgumentError('Unsupported profile photo format.');
    }
    if (bytes.isEmpty || bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw ArgumentError('Profile photos must be between 1 byte and 5 MB.');
    }

    final existingRow = await _client
        .from('profiles')
        .select('avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    final previousPath = existingRow?['avatar_url']?.toString();

    final objectPath = '${user.id}/avatar.$extension';
    await _client.storage.from(_profilePhotoBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: contentType,
          ),
        );

    await _client.from('profiles').upsert(
      {
        'id': user.id,
        'avatar_url': objectPath,
      },
      onConflict: 'id',
    );

    // Remove an older image if its format changed. A cleanup failure should
    // not undo the successful new upload/profile update.
    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != objectPath) {
      try {
        await _client.storage.from(_profilePhotoBucket).remove([previousPath]);
      } catch (error) {
        debugPrint('Old profile photo cleanup error: $error');
      }
    }

    return _client.storage
        .from(_profilePhotoBucket)
        .createSignedUrl(objectPath, _signedUrlLifetimeSeconds);
  }

  /// Reads the authenticated user's notification preference from Supabase.
  Future<bool> fetchNotificationsEnabled() async {
    final row = await _client
        .from('profiles')
        .select('notifications_enabled')
        .eq('id', _user.id)
        .maybeSingle();

    return row?['notifications_enabled'] as bool? ?? false;
  }

  /// Persists the notification preference for the authenticated user.
  Future<void> updateNotificationsEnabled(bool enabled) async {
    await _client
        .from('profiles')
        .update({'notifications_enabled': enabled})
        .eq('id', _user.id);
  }

  /// Supabase sends a confirmation email when the project's email-confirmation
  /// setting requires it. The current account email changes after confirmation.
  Future<void> requestEmailChange(String newEmail) async {
    await _client.auth.updateUser(
      UserAttributes(email: newEmail.trim()),
    );
  }

  Future<Map<String, int>> fetchTravelStats() async {
    final userId = _user.id;

    final tripRows = await _client
        .from('trips')
        .select('destination, country')
        .eq('user_id', userId);

    final stopRows = await _client
        .from('trip_destinations')
        .select('name')
        .eq('user_id', userId);

    final places = <String>{};
    for (final row in tripRows) {
      final destination = row['destination']?.toString().trim() ?? '';
      if (destination.isNotEmpty) {
        places.add(destination.toLowerCase());
      }
    }
    for (final row in stopRows) {
      final name = row['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        places.add(name.toLowerCase());
      }
    }

    final countries = <String>{};
    for (final row in tripRows) {
      final country = row['country']?.toString().trim() ?? '';
      if (country.isNotEmpty) {
        countries.add(country.toLowerCase());
      }
    }

    return {
      'trips': tripRows.length,
      'places': places.length,
      'countries': countries.length,
    };
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final profile = await fetchProfile();
    final stats = await fetchTravelStats();

    final fullName = profile['full_name']?.toString().trim() ?? '';
    return {
      'full_name': fullName.isEmpty ? 'Traveler' : fullName,
      ...stats,
    };
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
