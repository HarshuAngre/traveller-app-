import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  String userName = 'Harshu';
  String userEmail = 'harshu@example.com';

  void editProfile() {
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: userEmail);

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                final newEmail = emailController.text.trim();

                if (newName.isEmpty || newEmail.isEmpty) {
                  return;
                }

                setState(() {
                  userName = newName;
                  userEmail = newEmail;
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
      ),
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Logout functionality will be connected with Firebase later.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
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
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 55,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            showComingSoon('Profile photo');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
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
                    '2',
                    'Trips',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStat(
                    Icons.location_on,
                    '4',
                    'Places',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStat(
                    Icons.public,
                    '2',
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
              trailing: Switch(
                value: notificationsEnabled,
                activeThumbColor: const Color(0xFF1565C0),
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
                },
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