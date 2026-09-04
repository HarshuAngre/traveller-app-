import 'package:flutter/material.dart';

class TripDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripDetailsScreen({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final String destination =
        trip['destination']?.toString() ?? 'Unknown Destination';

    final String country =
        trip['country']?.toString() ?? 'Unknown';

    final String startDate =
        trip['startDate']?.toString() ?? 'Not selected';

    final String endDate =
        trip['endDate']?.toString() ?? 'Not selected';

    final String budget =
        trip['budget']?.toString() ?? '₹0';

    final String notes =
        trip['notes']?.toString() ?? 'No notes added.';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Trip Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Edit Trip feature coming soon!',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.edit,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination Header
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
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    color: Colors.white,
                    size: 55,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    country,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Trip Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // Dates
            _buildInfoCard(
              icon: Icons.calendar_month,
              iconColor: Colors.blue,
              title: 'Travel Dates',
              value: '$startDate - $endDate',
            ),

            const SizedBox(height: 12),

            // Budget
            _buildInfoCard(
              icon: Icons.account_balance_wallet,
              iconColor: Colors.green,
              title: 'Trip Budget',
              value: budget,
            ),

            const SizedBox(height: 25),

            // Notes
            const Text(
              'Trip Notes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes,
                    color: Color(0xFF1565C0),
                    size: 25,
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Map
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map,
                    color: Color(0xFF1565C0),
                    size: 55,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    destination,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Google Maps integration coming soon',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Edit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Edit Trip feature coming soon!',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Edit Trip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Delete button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showDeleteDialog(context);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                label: const Text(
                  'Delete Trip',
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Trip?',
          ),
          content: const Text(
            'Are you sure you want to delete this trip? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pop(
                  context,
                  true,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Trip deleted successfully.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}