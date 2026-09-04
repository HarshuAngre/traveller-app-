import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? mapController;

  static const LatLng defaultLocation = LatLng(
    15.4909,
    73.8278,
  );

  final Set<Marker> markers = {
    const Marker(
      markerId: MarkerId('goa'),
      position: defaultLocation,
      infoWindow: InfoWindow(
        title: 'Goa',
        snippet: 'Popular travel destination',
      ),
    ),
  };

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> moveToGoa() async {
    await mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: defaultLocation,
          zoom: 12,
        ),
      ),
    );
  }

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added soon.'),
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
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Explore Map',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showComingSoon('Place search');
            },
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: defaultLocation,
              zoom: 11,
            ),
            onMapCreated: onMapCreated,
            markers: markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // Search bar
          Positioned(
            top: 15,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                showComingSoon('Place search');
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Color(0xFF1565C0),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Search places...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom information card
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFF1565C0),
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Popular destination',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: moveToGoa,
                    icon: const Icon(
                      Icons.navigation,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current location button
          Positioned(
            right: 20,
            bottom: 120,
            child: FloatingActionButton(
              heroTag: 'locationButton',
              onPressed: () {
                showComingSoon('Current location');
              },
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1565C0),
              child: const Icon(
                Icons.my_location,
              ),
            ),
          ),
        ],
      ),
    );
  }
}