import 'package:flutter/material.dart';

import '../../core/models/trip.dart';
import '../../core/services/trip_service.dart';
import 'create_trip_screen.dart';
import 'trip_details_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final TripService _tripService = TripService();
  final TextEditingController _searchController = TextEditingController();

  List<Trip> _trips = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Trip> get _visibleTrips {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _trips;
    return _trips.where((trip) {
      return trip.destination.toLowerCase().contains(query) ||
          (trip.country ?? '').toLowerCase().contains(query) ||
          trip.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final trips = await _tripService.fetchTrips();
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _errorMessage = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Load trips error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('JWT') || message.contains('not signed in')) {
      return 'Your session may have expired. Please sign in again.';
    }
    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Map<String, dynamic>?> _openTripForm({Trip? trip}) {
    return Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => CreateTripScreen(trip: trip)),
    );
  }

  DateTime _dateFromPayload(dynamic value) {
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) throw const FormatException('Invalid trip date.');
    return parsed;
  }

  Future<void> _createTrip() async {
    if (_isSaving) return;
    final data = await _openTripForm();
    if (data == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await _tripService.createTrip(
        destination: data['destination'] as String,
        country: (data['country'] as String?) ?? '',
        startDate: _dateFromPayload(data['startDate']),
        endDate: _dateFromPayload(data['endDate']),
        budgetAmount: (data['budget'] as num).toDouble(),
        notes: (data['notes'] as String?) ?? '',
      );
      _showMessage('Trip saved successfully!');
      await _loadTrips(showLoading: false);
    } catch (error, stackTrace) {
      debugPrint('Create trip error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Unable to save trip: ${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editTrip(Trip trip) async {
    if (_isSaving) return;
    final data = await _openTripForm(trip: trip);
    if (data == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await _tripService.updateTrip(
        id: trip.id,
        destination: data['destination'] as String,
        country: (data['country'] as String?) ?? '',
        startDate: _dateFromPayload(data['startDate']),
        endDate: _dateFromPayload(data['endDate']),
        budgetAmount: (data['budget'] as num).toDouble(),
        notes: (data['notes'] as String?) ?? '',
      );
      _showMessage('Trip updated successfully.');
      await _loadTrips(showLoading: false);
    } catch (error, stackTrace) {
      debugPrint('Update trip error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Unable to update trip: ${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmAndDeleteTrip(Trip trip) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: Text(
          'Delete your trip to ${trip.destination}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _tripService.deleteTrip(trip.id);
      if (!mounted) return;
      setState(() => _trips.removeWhere((item) => item.id == trip.id));
      _showMessage('${trip.destination} trip deleted.');
    } catch (error, stackTrace) {
      debugPrint('Delete trip error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Unable to delete trip: ${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openTripDetails(Trip trip) async {
    final action = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => TripDetailsScreen(trip: trip)),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _editTrip(trip);
    } else if (action == 'delete') {
      await _deleteWithoutSecondConfirmation(trip);
    }
  }

  Future<void> _deleteWithoutSecondConfirmation(Trip trip) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _tripService.deleteTrip(trip.id);
      if (!mounted) return;
      setState(() => _trips.removeWhere((item) => item.id == trip.id));
      _showMessage('${trip.destination} trip deleted.');
    } catch (error, stackTrace) {
      debugPrint('Delete trip error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Unable to delete trip: ${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showTripOptions(Trip trip) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Trip Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View Trip'),
                onTap: () => Navigator.pop(sheetContext, 'view'),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Edit Trip'),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Trip'),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'view') {
      await _openTripDetails(trip);
    } else if (action == 'edit') {
      await _editTrip(trip);
    } else if (action == 'delete') {
      await _confirmAndDeleteTrip(trip);
    }
  }

  Future<void> _searchTrips() async {
    _searchController.text = _searchQuery;
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search Trips'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search destination or country',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _searchController.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (query != null && mounted) {
      setState(() => _searchQuery = query.trim());
    }
  }

  IconData _tripIcon(Trip trip) {
    final value = '${trip.destination} ${trip.country ?? ''}'.toLowerCase();
    if (value.contains('beach') || value.contains('goa')) {
      return Icons.beach_access;
    }
    if (value.contains('mountain') ||
        value.contains('manali') ||
        value.contains('hill')) {
      return Icons.landscape;
    }
    return Icons.flight_takeoff;
  }

  Widget _buildTripCard(Trip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
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
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 20,
                  top: 20,
                  child: Icon(
                    _tripIcon(trip),
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 70,
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 20,
                  right: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        trip.countryLabel,
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
                    const Icon(Icons.calendar_month, color: Color(0xFF1565C0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trip.dateRange,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                    Expanded(
                      child: Text(
                        'Budget: ${trip.formattedBudget}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Trip options',
                      onPressed: _isSaving
                          ? null
                          : () => _showTripOptions(trip),
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _openTripDetails(trip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'View Trip Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30),
      children: [
        const SizedBox(height: 70),
        const Icon(Icons.flight_takeoff, size: 90, color: Color(0xFF1565C0)),
        const SizedBox(height: 25),
        const Text(
          'No Trips Yet',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Start planning your next adventure! Your saved trips will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 30),
        Center(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _createTrip,
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Trip'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off, size: 70, color: Colors.redAccent),
        const SizedBox(height: 20),
        const Text(
          'Could not load trips',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage ?? 'Please try again.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _loadTrips(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTrips = _visibleTrips;

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
            onPressed: _searchTrips,
            icon: const Icon(Icons.search, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : visibleTrips.isEmpty
          ? (_trips.isEmpty
                ? _buildEmptyState()
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'No trips match your search.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ))
          : RefreshIndicator(
              onRefresh: _loadTrips,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${visibleTrips.length} Trips',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  for (final trip in visibleTrips) _buildTripCard(trip),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _createTrip,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
        label: Text(
          _isSaving ? 'Saving...' : 'Create Trip',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
