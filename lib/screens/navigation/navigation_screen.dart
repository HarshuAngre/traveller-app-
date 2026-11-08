import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({
    super.key,
    required this.destinationName,
    required this.destinationAddress,
    required this.destinationPosition,
  });

  final String destinationName;
  final String destinationAddress;
  final LatLng destinationPosition;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const Color _primaryBlue = Color(0xFF1565C0);

  final Completer<LatLng> _firstRoadSnappedLocation = Completer<LatLng>();

  GoogleNavigationViewController? _navigationController;
  StreamSubscription<RoadSnappedLocationUpdatedEvent>? _locationSubscription;
  StreamSubscription<OnArrivalEvent>? _arrivalSubscription;
  StreamSubscription<void>? _reroutingSubscription;
  StreamSubscription<void>? _routeChangedSubscription;
  StreamSubscription<RemainingTimeOrDistanceChangedEvent>?
  _remainingSubscription;

  bool _sessionInitialized = false;
  bool _isInitializing = true;
  bool _isCalculatingRoute = false;
  bool _routeReady = false;
  bool _navigationRunning = false;
  bool _isRerouting = false;
  bool _hasArrived = false;
  bool _isFinishing = false;
  bool _cleanupInProgress = false;
  double? _remainingDistanceMeters;
  double? _remainingTimeSeconds;
  String _statusMessage = 'Preparing navigation…';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNavigation();
    });
  }

  Future<bool> _ensureLocationPermission() async {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      throw Exception('Turn on Location Services (GPS) and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is required to calculate a route.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('VoyageMate cannot access your current location.');
    }

    // Confirm that the device can obtain a fresh fix before starting the SDK.
    await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return true;
  }

  Future<void> _initializeNavigation() async {
    if (!mounted || _sessionInitialized) return;

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _statusMessage = 'Checking location permission…';
    });

    try {
      await _ensureLocationPermission();
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Checking Navigation SDK terms…';
      });

      final termsAccepted = await GoogleMapsNavigator.areTermsAccepted();
      if (!termsAccepted) {
        final acceptedNow =
            await GoogleMapsNavigator.showTermsAndConditionsDialog(
              'VoyageMate Navigation',
              'VoyageMate',
            );
        if (!acceptedNow) {
          throw Exception(
            'Navigation terms must be accepted before using guidance.',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Starting Google Navigation…';
      });

      await GoogleMapsNavigator.initializeNavigationSession(
        taskRemovedBehavior: TaskRemovedBehavior.quitService,
        notificationOptions: const NavigationNotificationOptions(
          notificationId: 4201,
          defaultMessage: 'VoyageMate navigation is ready',
          resumeAppOnTap: true,
        ),
      );
      _sessionInitialized = true;

      // Subscribe before creating the navigation view so the first GPS snap
      // cannot be missed when the native view enables location updates.
      _locationSubscription =
          await GoogleMapsNavigator.setRoadSnappedLocationUpdatedListener((
            event,
          ) {
            if (!_firstRoadSnappedLocation.isCompleted) {
              _firstRoadSnappedLocation.complete(event.location);
            }
          });

      // Register navigation lifecycle listeners before the native navigation
      // view starts guidance, so arrival/rerouting events are not missed.
      _arrivalSubscription = GoogleMapsNavigator.setOnArrivalListener(
        _onArrival,
      );
      _routeChangedSubscription = GoogleMapsNavigator.setOnRouteChangedListener(
        _onRouteChanged,
      );
      _remainingSubscription =
          GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
            _onRemainingTimeOrDistanceChanged,
            remainingTimeThresholdSeconds: 60,
            remainingDistanceThresholdMeters: 100,
          );

      // Rerouting callback is Android-only in the Flutter plugin.
      if (defaultTargetPlatform == TargetPlatform.android) {
        _reroutingSubscription = GoogleMapsNavigator.setOnReroutingListener(
          _onRerouting,
        );
      }

      if (!mounted) {
        await _cleanupNavigationSession();
        return;
      }

      setState(() {
        _isInitializing = false;
        _statusMessage = 'Waiting for an accurate GPS position…';
      });
    } catch (error) {
      debugPrint('Navigation initialization error: $error');
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = _friendlyError(error);
        _statusMessage = 'Navigation could not be initialized.';
      });
      await _cleanupNavigationSession();
    }
  }

  void _onNavigationViewCreated(GoogleNavigationViewController controller) {
    _navigationController = controller;
    unawaited(_prepareMapAndCalculateRoute(controller));
  }

  Future<void> _prepareMapAndCalculateRoute(
    GoogleNavigationViewController controller,
  ) async {
    try {
      await controller.setMyLocationEnabled(true);
      if (!mounted) return;
      await _calculateRoute();
    } catch (error) {
      debugPrint('Navigation map initialization error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(error);
        _statusMessage = 'Unable to prepare the route map.';
      });
    }
  }

  Future<void> _calculateRoute() async {
    final controller = _navigationController;
    if (!mounted ||
        !_sessionInitialized ||
        controller == null ||
        _isCalculatingRoute ||
        _routeReady) {
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _errorMessage = null;
      _statusMessage = 'Waiting for Google to lock onto your location…';
    });

    try {
      // The Navigation SDK requires its own road-snapped location event
      // before setDestinations can calculate a route.
      await _firstRoadSnappedLocation.future.timeout(
        const Duration(seconds: 45),
      );

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Calculating the best driving route…';
      });

      final destinations = Destinations(
        waypoints: <NavigationWaypoint>[
          NavigationWaypoint.withLatLngTarget(
            title: widget.destinationName,
            target: widget.destinationPosition,
          ),
        ],
        displayOptions: NavigationDisplayOptions(showDestinationMarkers: true),
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
        ),
      );

      final routeStatus = await GoogleMapsNavigator.setDestinations(
        destinations,
      );

      if (!mounted) return;

      if (routeStatus != NavigationRouteStatus.statusOk) {
        throw Exception(
          'Google route calculation returned: ${routeStatus.name}',
        );
      }

      await controller.showRouteOverview();

      if (!mounted) return;
      setState(() {
        _isCalculatingRoute = false;
        _routeReady = true;
        _statusMessage = 'Route ready';
        _errorMessage = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isCalculatingRoute = false;
        _errorMessage =
            'GPS is taking too long to lock onto a road. Move to an open area and retry.';
        _statusMessage = 'Waiting for GPS';
      });
    } catch (error) {
      debugPrint('Route calculation error: $error');
      if (!mounted) return;
      setState(() {
        _isCalculatingRoute = false;
        _errorMessage = _friendlyError(error);
        _statusMessage = 'Route calculation failed';
      });
    }
  }

  void _onRerouting() {
    if (!mounted || !_navigationRunning || _hasArrived) return;

    setState(() {
      _isRerouting = true;
      _statusMessage = 'You left the route. Recalculating…';
    });
  }

  void _onRouteChanged() {
    // Route-changed events also occur during initial route generation and when
    // guidance starts. Only show the reroute-complete state after a reroute
    // request has actually been received.
    if (!mounted || !_navigationRunning || !_isRerouting || _hasArrived) {
      return;
    }

    setState(() {
      _isRerouting = false;
      _statusMessage = 'Route updated. Follow the new directions.';
    });
  }

  void _onRemainingTimeOrDistanceChanged(
    RemainingTimeOrDistanceChangedEvent event,
  ) {
    if (!mounted || !_navigationRunning || _hasArrived) return;

    setState(() {
      _remainingDistanceMeters = event.remainingDistance;
      _remainingTimeSeconds = event.remainingTime;
    });
  }

  void _onArrival(OnArrivalEvent event) {
    debugPrint('VoyageMate arrival event received: ${event.waypoint}');
    unawaited(_completeArrival());
  }

  Future<void> _completeArrival() async {
    if (!mounted || _hasArrived) return;

    setState(() {
      _hasArrived = true;
      _navigationRunning = false;
      _isRerouting = false;
      _isFinishing = true;
      _statusMessage = 'You have arrived at ${widget.destinationName}.';
      _remainingDistanceMeters = 0;
      _remainingTimeSeconds = 0;
      _errorMessage = null;
    });

    try {
      // Google requires guidance to be stopped explicitly on arrival. Clear
      // destinations as well to stop background location updates/notification.
      if (await GoogleMapsNavigator.isGuidanceRunning()) {
        await GoogleMapsNavigator.stopGuidance();
      }
      await GoogleMapsNavigator.clearDestinations();
      await _navigationController?.setNavigationUIEnabled(false);
    } catch (error) {
      debugPrint('Arrival cleanup warning: $error');
      if (mounted) {
        setState(() {
          _errorMessage =
              'You have arrived, but navigation cleanup reported an issue. '
              'Tap Finish to close navigation.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFinishing = false;
          _statusMessage = 'Arrived at ${widget.destinationName}';
        });
      }
    }
  }

  String _formatDistance(double meters) {
    if (!meters.isFinite || meters < 0) return '—';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatRemainingTime(double seconds) {
    if (!seconds.isFinite || seconds < 0) return '—';
    final totalMinutes = (seconds / 60).ceil();
    if (totalMinutes < 1) return 'Less than 1 min';
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '$hours hr' : '$hours hr $minutes min';
  }

  Future<void> _startNavigation() async {
    final controller = _navigationController;
    if (!mounted || !_routeReady || controller == null || _navigationRunning) {
      return;
    }

    setState(() {
      _isFinishing = true;
      _errorMessage = null;
      _statusMessage = 'Starting turn-by-turn guidance…';
    });

    try {
      await controller.setNavigationUIEnabled(true);
      await GoogleMapsNavigator.startGuidance();
      await controller.followMyLocation(CameraPerspective.tilted);

      if (!mounted) return;
      setState(() {
        _navigationRunning = true;
        _isFinishing = false;
        _statusMessage = 'Navigation in progress';
      });
    } catch (error) {
      debugPrint('Start guidance error: $error');
      if (!mounted) return;
      setState(() {
        _isFinishing = false;
        _errorMessage = _friendlyError(error);
        _statusMessage = 'Could not start guidance';
      });
    }
  }

  Future<void> _endNavigation() async {
    if (_isFinishing) return;

    setState(() {
      _isFinishing = true;
      _statusMessage = 'Ending navigation…';
    });

    await _cleanupNavigationSession();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _cleanupNavigationSession() async {
    if (_cleanupInProgress) return;
    _cleanupInProgress = true;

    try {
      final subscriptions = <StreamSubscription<dynamic>?>[
        _locationSubscription,
        _arrivalSubscription,
        _reroutingSubscription,
        _routeChangedSubscription,
        _remainingSubscription,
      ];
      _locationSubscription = null;
      _arrivalSubscription = null;
      _reroutingSubscription = null;
      _routeChangedSubscription = null;
      _remainingSubscription = null;

      for (final subscription in subscriptions) {
        await subscription?.cancel();
      }

      if (!_sessionInitialized) return;

      try {
        if (await GoogleMapsNavigator.isGuidanceRunning()) {
          await GoogleMapsNavigator.stopGuidance();
        }
        await GoogleMapsNavigator.clearDestinations();
        await GoogleMapsNavigator.cleanup();
      } catch (error) {
        debugPrint('Navigation cleanup warning: $error');
      } finally {
        _sessionInitialized = false;
      }
    } finally {
      _cleanupInProgress = false;
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty
        ? 'An unexpected navigation error occurred.'
        : message;
  }

  @override
  void dispose() {
    if (_sessionInitialized ||
        _locationSubscription != null ||
        _arrivalSubscription != null ||
        _reroutingSubscription != null ||
        _routeChangedSubscription != null ||
        _remainingSubscription != null) {
      unawaited(_cleanupNavigationSession());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showNavigationView = _sessionInitialized && !_isInitializing;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _hasArrived
              ? 'Arrived'
              : _navigationRunning
              ? 'Navigation'
              : 'Route preview',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (showNavigationView)
            Positioned.fill(
              child: GoogleMapsNavigationView(
                onViewCreated: _onNavigationViewCreated,
                initialNavigationUIEnabledPreference:
                    NavigationUIEnabledPreference.disabled,
                initialMapColorScheme: MapColorScheme.followSystem,
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xFFE8EEF5),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: _buildDestinationCard(),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildActionCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE3F2FD),
            child: Icon(Icons.flag_rounded, color: _primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.destinationAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasArrived
                    ? Icons.flag_circle_rounded
                    : _isRerouting
                    ? Icons.alt_route_rounded
                    : _routeReady
                    ? Icons.check_circle_rounded
                    : _errorMessage == null
                    ? Icons.route_rounded
                    : Icons.info_outline_rounded,
                color: (_hasArrived || _routeReady)
                    ? Colors.green
                    : _primaryBlue,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (_isInitializing ||
                  _isCalculatingRoute ||
                  _isFinishing ||
                  _isRerouting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, height: 1.4),
            ),
          ],
          if (_navigationRunning &&
              _remainingDistanceMeters != null &&
              _remainingTimeSeconds != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: _primaryBlue,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _formatRemainingTime(_remainingTimeSeconds!),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.route_rounded,
                    size: 18,
                    color: _primaryBlue,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${_formatDistance(_remainingDistanceMeters!)} left',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_hasArrived)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFinishing ? null : _endNavigation,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else if (_navigationRunning)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFinishing ? null : _endNavigation,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('End navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else if (_routeReady)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFinishing ? null : _startNavigation,
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Start navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else if (_errorMessage != null && !_isInitializing)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isCalculatingRoute ? null : _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                'VoyageMate is preparing a route from your live GPS location.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _retry() async {
    if (!_sessionInitialized) {
      await _initializeNavigation();
      return;
    }
    if (_navigationController == null) return;
    await _calculateRoute();
  }
}
