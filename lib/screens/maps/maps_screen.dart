
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart'
    as places;

import '../../core/config/google_maps_config.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? mapController;
  places.FlutterGooglePlacesSdk? _placesClient;

  bool _isLocating = false;
  bool _hasLocationPermission = false;
  bool _isLoadingPlace = false;

  Position? _currentPosition;

  String _selectedPlaceName = 'Goa';
  String _selectedPlaceAddress = 'Popular destination';

  LatLng _selectedPlacePosition = const LatLng(
    15.4909,
    73.8278,
  );

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  static const LatLng defaultLocation = LatLng(
    15.4909,
    73.8278,
  );

  Set<Marker> markers = {
    const Marker(
      markerId: MarkerId('goa'),
      position: defaultLocation,
      infoWindow: InfoWindow(
        title: 'Goa',
        snippet: 'Popular travel destination',
      ),
    ),
  };

  @override
  void initState() {
    super.initState();
    _initializePlaces();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --------------------------------------------------
  // INITIALIZE GOOGLE PLACES SDK
  // --------------------------------------------------

  void _initializePlaces() {
    final apiKey = GoogleMapsConfig.placesApiKey.trim();

    if (apiKey.isEmpty) {
      debugPrint(
        'Places API key is missing. Check dart_defines.json '
        'and --dart-define-from-file.',
      );
      return;
    }

    try {
      _placesClient = places.FlutterGooglePlacesSdk(
        apiKey,
        locale: const Locale('en', 'IN'),
      );

      debugPrint('Google Places client created.');
    } catch (error) {
      debugPrint('Google Places initialization error: $error');
    }
  }

  // --------------------------------------------------
  // MAP INITIALIZATION
  // --------------------------------------------------

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (_selectedPlacePosition != defaultLocation) {
      _moveCameraTo(_selectedPlacePosition);
    }
  }

  Future<void> _moveCameraTo(LatLng location) async {
    try {
      await mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: 16,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Camera movement error: $error');
    }
  }

  // --------------------------------------------------
  // MOVE CAMERA TO SELECTED PLACE
  // --------------------------------------------------

  Future<void> moveToSelectedPlace() async {
    await _moveCameraTo(_selectedPlacePosition);
  }

  // --------------------------------------------------
  // SHOW MESSAGE
  // --------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // --------------------------------------------------
  // LOCATION SERVICES DIALOG
  // --------------------------------------------------

  Future<void> _showLocationServiceDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable GPS or Location Services on your '
            'phone to find your current location.',
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
                Navigator.pop(dialogContext);
                Geolocator.openLocationSettings();
              },
              child: const Text('Enable Location'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // LOCATION PERMISSION DIALOG
  // --------------------------------------------------

  Future<void> _showPermissionSettingsDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission has been permanently denied. '
            'Please enable location permission from your '
            'phone settings.',
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
                Navigator.pop(dialogContext);
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // GET CURRENT LOCATION
  // --------------------------------------------------

  Future<void> _goToCurrentLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await _showLocationServiceDialog();
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        await _showPermissionSettingsDialog();
        return;
      }

      final bool granted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (!granted) {
        _showMessage('Unable to access your location.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _hasLocationPermission = true;
      });

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      _currentPosition = position;

      final LatLng currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      await mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            zoom: 16,
          ),
        ),
      );

      _showMessage('Your current location is displayed.');
    } on TimeoutException {
      _showMessage(
        'Location request timed out. Please try again.',
      );
    } catch (error) {
      debugPrint('Current location error: $error');

      _showMessage(
        'Unable to find your location. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // OPEN PLACE SEARCH
  // --------------------------------------------------

  Future<void> _openPlaceSearch() async {
    final client = _placesClient;

    if (client == null) {
      _showMessage(
        'Places is not configured. Check your API key '
        'and Flutter run configuration.',
      );
      return;
    }

    final places.AutocompletePrediction? prediction =
        await showModalBottomSheet<places.AutocompletePrediction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: _PlaceSearchSheet(
            client: client,
            currentPosition: _currentPosition,
          ),
        );
      },
    );

    if (!mounted || prediction == null) return;

    await _selectPlace(prediction);
  }

  // --------------------------------------------------
  // FETCH SELECTED PLACE DETAILS
  // --------------------------------------------------

  Future<void> _selectPlace(
    places.AutocompletePrediction prediction,
  ) async {
    final client = _placesClient;
    final placeId = prediction.placeId;

    if (client == null || placeId == null || placeId.isEmpty) {
      _showMessage('Unable to identify the selected place.');
      return;
    }

    setState(() {
      _isLoadingPlace = true;
    });

    try {
      // Request only the fields required by this screen.
      final response = await client.fetchPlace(
        placeId,
        fields: const [
          places.PlaceField.Location,
          places.PlaceField.FormattedAddress,
        ],
        newSessionToken: false,
      );

      final place = response.place;
      final placeLocation = place?.latLng;

      if (place == null || placeLocation == null) {
        throw Exception(
          'The selected place has no location coordinates.',
        );
      }

      final LatLng selectedLocation = LatLng(
        placeLocation.lat,
        placeLocation.lng,
      );

      final String selectedName =
          prediction.primaryText ??
          prediction.fullText ??
          'Selected place';

      final String selectedAddress =
          place.address ??
          prediction.secondaryText ??
          'Address unavailable';

      if (!mounted) return;

      setState(() {
        _selectedPlaceName = selectedName;
        _selectedPlaceAddress = selectedAddress;
        _selectedPlacePosition = selectedLocation;

        markers = {
          Marker(
            markerId: const MarkerId('selected_place'),
            position: selectedLocation,
            infoWindow: InfoWindow(
              title: selectedName,
              snippet: selectedAddress,
            ),
          ),
        };
      });

      await _moveCameraTo(selectedLocation);

      _showMessage('$selectedName selected on the map.');
    } catch (error) {
      debugPrint('Place details error: $error');

      _showMessage(
        'Unable to load this place. Please try another result.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlace = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // BUILD SCREEN
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

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
            tooltip: 'Search places',
            onPressed: _openPlaceSearch,
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: Stack(
        children: [

          // --------------------------------------------------
          // GOOGLE MAP
          // --------------------------------------------------

          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: defaultLocation,
              zoom: 11,
            ),

            onMapCreated: onMapCreated,

            markers: markers,

            myLocationEnabled: _hasLocationPermission,

            myLocationButtonEnabled: false,

            zoomControlsEnabled: false,

            mapToolbarEnabled: false,

            compassEnabled: true,

            mapType: MapType.normal,
          ),

          // --------------------------------------------------
          // SEARCH BAR
          // --------------------------------------------------

          Positioned(
            top: 15,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: _openPlaceSearch,
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: primaryBlue,
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        'Search places, landmarks, restaurants...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    if (_isLoadingPlace)
                      const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryBlue,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // --------------------------------------------------
          // SELECTED PLACE INFORMATION CARD
          // --------------------------------------------------

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
                      color: primaryBlue,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPlaceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _selectedPlaceAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Show selected place',
                    onPressed: moveToSelectedPlace,
                    icon: const Icon(
                      Icons.near_me,
                      color: primaryBlue,
                      size: 27,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --------------------------------------------------
          // CURRENT LOCATION BUTTON
          // --------------------------------------------------

          Positioned(
            right: 20,
            bottom: 125,
            child: FloatingActionButton(
              heroTag: 'locationButton',

              onPressed: _isLocating
                  ? null
                  : _goToCurrentLocation,

              backgroundColor: Colors.white,
              foregroundColor: primaryBlue,

              child: _isLocating
                  ? const SizedBox(
                      height: 23,
                      width: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primaryBlue,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// GOOGLE PLACES SEARCH BOTTOM SHEET
// ==================================================

class _PlaceSearchSheet extends StatefulWidget {
  final places.FlutterGooglePlacesSdk client;
  final Position? currentPosition;

  const _PlaceSearchSheet({
    required this.client,
    required this.currentPosition,
  });

  @override
  State<_PlaceSearchSheet> createState() =>
      _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  Timer? _debounce;

  List<places.AutocompletePrediction> _predictions = [];

  bool _isSearching = false;
  bool _hasSearched = false;
  bool _startNewSession = true;

  String? _errorMessage;

  int _requestNumber = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // SEARCH INPUT AND DEBOUNCING
  // --------------------------------------------------

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _predictions = [];
        _isSearching = false;
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchPlaces(query),
    );
  }

  // --------------------------------------------------
  // GOOGLE PLACES AUTOCOMPLETE
  // --------------------------------------------------

  Future<void> _searchPlaces(String query) async {
    if (!mounted) return;

    final requestId = ++_requestNumber;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final position = widget.currentPosition;

      final places.LatLng? origin = position == null
          ? null
          : places.LatLng(
              lat: position.latitude,
              lng: position.longitude,
            );

      final response =
          await widget.client.findAutocompletePredictions(
        query,
        origin: origin,
        newSessionToken: _startNewSession,
      );

      _startNewSession = false;

      if (!mounted || requestId != _requestNumber) return;

      setState(() {
        _predictions = response.predictions;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (error) {
      debugPrint('Places autocomplete error: $error');

      if (!mounted || requestId != _requestNumber) return;

      setState(() {
        _predictions = [];
        _isSearching = false;
        _hasSearched = true;
        _errorMessage =
            'Unable to search places. Check your internet connection '
            'or Google Cloud API configuration.';
      });
    }
  }

  // --------------------------------------------------
  // SELECT A SEARCH RESULT
  // --------------------------------------------------

  void _selectPrediction(
    places.AutocompletePrediction prediction,
  ) {
    _debounce?.cancel();
    Navigator.of(context).pop(prediction);
  }

  // --------------------------------------------------
  // SEARCH PANEL UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        children: [

          const SizedBox(height: 12),

          // Drag handle
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search Places',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _debounce?.cancel();

                if (value.trim().length >= 2) {
                  _searchPlaces(value.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'Search any city or place...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF1565C0),
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (_isSearching)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF1565C0),
            ),

          // Search results
          Expanded(
            child: _buildSearchResults(),
          ),

          // Google attribution
          Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
              top: 8,
            ),
            child: Image(
              image: places.FlutterGooglePlacesSdk
                  .assetPoweredByGoogleOnWhite,
              height: 18,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SEARCH RESULTS
  // --------------------------------------------------

  Widget _buildSearchResults() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    if (_predictions.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        itemCount: _predictions.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          indent: 65,
        ),
        itemBuilder: (context, index) {
          final prediction = _predictions[index];

          final title =
              prediction.primaryText ??
              prediction.fullText ??
              'Unknown place';

          final subtitle = prediction.secondaryText ?? '';

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(
                Icons.location_on_outlined,
                color: Color(0xFF1565C0),
              ),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: subtitle.isEmpty
                ? null
                : Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => _selectPrediction(prediction),
          );
        },
      );
    }

    if (_isSearching) {
      return const Center(
        child: Text(
          'Searching places...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_hasSearched) {
      return const Center(
        child: Text(
          'No places found. Try another search.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.travel_explore,
              size: 65,
              color: Color(0xFF90CAF9),
            ),
            SizedBox(height: 15),
            Text(
              'Find Places Around the World',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Search for cities, landmarks, restaurants, '
              'hotels, airports and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
