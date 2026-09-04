import 'create_trip_screen.dart';
import 'package:flutter/material.dart';
import 'trip_details_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final List<Map<String, dynamic>> trips = [
    {
      'destination': 'Goa',
      'country': 'India',
      'startDate': '12 Dec 2026',
      'endDate': '18 Dec 2026',
      'budget': '₹20,000',
      'icon': Icons.beach_access,
    },
    {
      'destination': 'Manali',
      'country': 'India',
      'startDate': '05 Jan 2027',
      'endDate': '10 Jan 2027',
      'budget': '₹25,000',
      'icon': Icons.landscape,
    },
  ];

  void deleteTrip(int index) {
    final deletedTrip = trips[index];

    setState(() {
      trips.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${deletedTrip['destination']} trip deleted',
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              trips.insert(index, deletedTrip);
            });
          },
        ),
      ),
    );
  }

  void showTripOptions(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Trip Options',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(
                    Icons.visibility,
                    color: Colors.blue,
                  ),
                  title: const Text('View Trip'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.edit,
                    color: Colors.orange,
                  ),
                  title: const Text('Edit Trip'),
                  onTap: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Edit Trip feature coming next!',
                        ),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  title: const Text('Delete Trip'),
                  onTap: () {
                    Navigator.pop(context);
                    deleteTrip(index);
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTripCard(
    Map<String, dynamic> trip,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF42A5F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 20,
                  top: 20,
                  child: Icon(
                    trip['icon'],
                    color: Colors.white.withOpacity(0.9),
                    size: 70,
                  ),
                ),

                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['destination'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        trip['country'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${trip['startDate']} - ${trip['endDate']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Budget: ${trip['budget']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: () {
                        showTripOptions(index);
                      },
                      icon: const Icon(
                        Icons.more_vert,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => TripDetailsScreen(
                                trip: trip,
                            ),
                            ),
                        );

                        if (result == true && mounted) {
                            setState(() {
                            trips.removeAt(index);
                            });
                        }
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'View Trip Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Trips',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Search feature coming soon!',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: trips.isEmpty
          ? buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${trips.length} Trips',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                for (int i = 0; i < trips.length; i++)
                  buildTripCard(
                    trips[i],
                    i,
                  ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CreateTripScreen(),
    ),
  );

  if (result != null) {
    setState(() {
      trips.add({
        'destination': result['destination'],
        'country': 'Custom Trip',
        'startDate': result['startDate'],
        'endDate': result['endDate'],
        'budget': '₹${result['budget']}',
        'icon': Icons.flight_takeoff,
      });
    });
  }
},
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Trip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.flight_takeoff,
              size: 90,
              color: Color(0xFF1565C0),
            ),

            const SizedBox(height: 25),

            const Text(
              'No Trips Yet',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Start planning your next adventure!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CreateTripScreen(),
    ),
  );

  if (result != null) {
    setState(() {
      trips.add({
        'destination': result['destination'],
        'country': 'Custom Trip',
        'startDate': result['startDate'],
        'endDate': result['endDate'],
        'budget': '₹${result['budget']}',
        'icon': Icons.flight_takeoff,
      });
    });
  }
},
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Trip'),
            ),
          ],
         )
      ),
    );
  }
}