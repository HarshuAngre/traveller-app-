import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/profile_service.dart';
import '../auth/login_screen.dart';
import '../../core/services/trip_notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  bool notificationsEnabled = false;
  bool _isUpdatingNotifications = false;
  bool darkModeEnabled = false;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  String? _avatarUrl;
  String userName = 'Traveler';
  String userEmail = '';
  String userPhone = '';
  String homeCity = '';

  Map<String, int> travelStats = {
    'trips': 0,
    'places': 0,
    'countries': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.fetchProfile();
      final stats = await _profileService.fetchTravelStats();
      if (!mounted) return;

      setState(() {
        userName = (profile['full_name']?.toString().trim().isNotEmpty ?? false)
            ? profile['full_name'].toString().trim()
            : 'Traveler';
        userEmail = profile['email']?.toString() ?? '';
        userPhone = profile['phone']?.toString() ?? '';
        homeCity = profile['home_city']?.toString() ?? '';
        _avatarUrl = profile['avatar_url']?.toString();
        notificationsEnabled = profile['notifications_enabled'] as bool? ?? false;
        travelStats = stats;
      });

      if (notificationsEnabled) {
        try {
          await TripNotificationService.instance.syncUpcomingTripReminders();
        } catch (error) {
          debugPrint('Trip reminder sync error: $error');
        }
      }
    } catch (error) {
      debugPrint('Profile loading error: $error');
      if (mounted) {
        _showMessage('Unable to load your profile. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeProfilePhoto() async {
    if (_isUploadingPhoto) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (selectedImage == null || !mounted) return;

      final parts = selectedImage.name.toLowerCase().split('.');
      final extension = parts.length > 1 ? parts.last : '';
      const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

      if (!allowedExtensions.contains(extension)) {
        _showMessage('Please choose a JPG, PNG or WEBP image.');
        return;
      }

      final bytes = await selectedImage.readAsBytes();
      if (!mounted) return;

      const maxBytes = 5 * 1024 * 1024;
      if (bytes.isEmpty) {
        _showMessage('The selected image is empty. Please choose another image.');
        return;
      }
      if (bytes.lengthInBytes > maxBytes) {
        _showMessage('Please choose an image smaller than 5 MB.');
        return;
      }

      final contentType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };

      final signedUrl = await _profileService.uploadProfilePhoto(
        bytes: bytes,
        fileExtension: extension,
        contentType: contentType,
      );

      if (!mounted) return;
      setState(() => _avatarUrl = signedUrl);
      _showMessage('Profile photo updated successfully.');
    } catch (error, stackTrace) {
      debugPrint('Profile photo upload error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showMessage(
          'Could not upload the photo. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> editProfile() async {
    // Collect the form values and close the dialog before making network calls.
    // This keeps the dialog route separate from the parent screen's rebuild.
    final result = await showDialog<_ProfileEditData>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialName: userName,
        initialEmail: userEmail,
        initialPhone: userPhone,
        initialCity: homeCity,
      ),
    );

    if (result == null || !mounted) return;

    try {
      await _profileService.updateProfile(
        fullName: result.name,
        phone: result.phone,
        homeCity: result.city,
      );
    } catch (error) {
      debugPrint('Profile update error: $error');
      if (mounted) {
        _showMessage('Could not save your profile. Please try again.');
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      userName = result.name;
      userPhone = result.phone;
      homeCity = result.city;
    });

    final emailChanged =
        result.email.toLowerCase() != userEmail.toLowerCase();

    if (emailChanged) {
      try {
        await _profileService.requestEmailChange(result.email);
        if (!mounted) return;
        _showMessage(
          'Profile saved. Confirm the email sent to your new address to finish changing it.',
        );
      } catch (error) {
        debugPrint('Email change request error: $error');
        if (mounted) {
          _showMessage(
            'Profile saved, but the email change could not be requested. Please try again.',
          );
        }
      }
    } else {
      _showMessage('Profile updated successfully.');
    }
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    if (_isUpdatingNotifications) return;

    setState(() => _isUpdatingNotifications = true);
    var persistedValue = notificationsEnabled;

    try {
      if (enabled) {
        final permissionGranted =
            await TripNotificationService.instance.requestPermission();
        if (!permissionGranted) {
          _showMessage(
            'Notification permission was not granted. Enable it in Android settings to receive trip reminders.',
          );
          return;
        }

        await _profileService.updateNotificationsEnabled(true);
        persistedValue = true;

        final scheduledCount = await TripNotificationService.instance
            .syncUpcomingTripReminders();
        await TripNotificationService.instance.showEnabledConfirmation();

        if (!mounted) return;
        setState(() => notificationsEnabled = true);
        _showMessage(
          scheduledCount == 0
              ? 'Notifications enabled. No upcoming trips need a reminder yet.'
              : 'Notifications enabled. $scheduledCount trip reminder(s) scheduled.',
        );
      } else {
        await _profileService.updateNotificationsEnabled(false);
        persistedValue = false;
        await TripNotificationService.instance.cancelTripReminders();

        if (!mounted) return;
        setState(() => notificationsEnabled = false);
        _showMessage('Trip reminders turned off.');
      }
    } catch (error, stackTrace) {
      debugPrint('Notification preference update error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (enabled && persistedValue) {
        try {
          await _profileService.updateNotificationsEnabled(false);
          await TripNotificationService.instance.cancelTripReminders();
          persistedValue = false;
        } catch (rollbackError) {
          debugPrint('Notification rollback error: $rollbackError');
        }
      }

      if (mounted) {
        setState(() => notificationsEnabled = persistedValue);
        _showMessage(
          'Could not update notifications. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingNotifications = false);
      }
    }
  }

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
      ),
    );
  }

  Future<void> logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await _profileService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      debugPrint('Logout error: $error');
      if (mounted) {
        _showMessage('Unable to logout. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF42A5F5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        onBackgroundImageError: _avatarUrl == null
                            ? null
                            : (error, stackTrace) {
                                debugPrint('Profile photo display error: $error');
                              },
                        child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 55,
                                color: Color(0xFF1565C0),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : _changeProfilePhoto,
                          child: Container(
                            width: 34,
                            height: 34,
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingPhoto
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1565C0),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Color(0xFF1565C0),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: editProfile,
                      icon: const Icon(
                        Icons.edit,
                        size: 17,
                      ),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white70,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Travel statistics
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Travel Statistics',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    Icons.card_travel,
                    (travelStats['trips'] ?? 0).toString(),
                    'Trips',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStat(
                    Icons.location_on,
                    (travelStats['places'] ?? 0).toString(),
                    'Places',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStat(
                    Icons.public,
                    (travelStats['countries'] ?? 0).toString(),
                    'Countries',
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildSettingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Receive travel reminders',
              trailing: (_isLoading || _isUpdatingNotifications)
                  ? const SizedBox(
                      width: 48,
                      height: 28,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Switch(
                      value: notificationsEnabled,
                      activeThumbColor: const Color(0xFF1565C0),
                      onChanged: _setNotificationsEnabled,
                    ),
            ),

            _buildSettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Change app appearance',
              trailing: Switch(
                value: darkModeEnabled,
                activeThumbColor: const Color(0xFF1565C0),
                onChanged: (value) {
                  setState(() {
                    darkModeEnabled = value;
                  });

                  showComingSoon('Dark Mode');
                },
              ),
            ),

            _buildSettingTile(
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              subtitle: 'Manage your account security',
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
              onTap: () {
                showComingSoon('Privacy & Security');
              },
            ),

            _buildSettingTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with VoyageMate',
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
              onTap: () {
                showComingSoon('Help & Support');
              },
            ),

            const SizedBox(height: 20),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: logout,
                icon: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'VoyageMate',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Travel Smarter • Explore More',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 27,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F2FD),
          child: Icon(
            icon,
            color: const Color(0xFF1565C0),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}

class _ProfileEditData {
  const _ProfileEditData({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
  });

  final String name;
  final String email;
  final String phone;
  final String city;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialCity,
  });

  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialCity;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;

  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _cityController = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();

    if (name.isEmpty) {
      setState(() => _validationMessage = 'Name cannot be empty.');
      return;
    }

    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _validationMessage = 'Enter a valid email address.');
      return;
    }

    Navigator.of(context).pop(
      _ProfileEditData(
        name: name,
        email: email,
        phone: phone,
        city: city,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Edit Profile',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                helperText: 'Changing email requires confirmation.',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Home city',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            if (_validationMessage != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _validationMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
