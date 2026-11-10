import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/destination_service.dart';
import '../maps/maps_screen.dart';

class DestinationsScreen extends StatefulWidget {
  const DestinationsScreen({super.key});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  final TextEditingController searchController = TextEditingController();
  final DestinationService _destinationService = DestinationService();
  final Set<int> _favoriteOperations = {};

  String searchQuery = '';
  String selectedCategory = 'All';

  final List<Map<String, dynamic>> destinations = [
    {
      'name': 'Goa',
      'country': 'India',
      'category': 'Beach',
      'rating': 4.8,
      'emoji': '🏖️',
      'description':
          'Relax on beautiful beaches and enjoy the vibrant nightlife.',
      'color': Color(0xFF42A5F5),
      'favorite': false,
    },
    {
      'name': 'Manali',
      'country': 'India',
      'category': 'Mountains',
      'rating': 4.7,
      'emoji': '🏔️',
      'description':
          'Explore snow-covered mountains, valleys, and adventure activities.',
      'color': Color(0xFF66BB6A),
      'favorite': false,
    },
    {
      'name': 'Kashmir',
      'country': 'India',
      'category': 'Mountains',
      'rating': 4.9,
      'emoji': '❄️',
      'description':
          'Discover breathtaking valleys, lakes, and scenic landscapes.',
      'color': Color(0xFF29B6F6),
      'favorite': false,
    },
    {
      'name': 'Bali',
      'country': 'Indonesia',
      'category': 'Beach',
      'rating': 4.8,
      'emoji': '🌴',
      'description':
          'Experience tropical beaches, temples, culture, and nature.',
      'color': Color(0xFFFFA726),
      'favorite': false,
    },
    {
      'name': 'Dubai',
      'country': 'UAE',
      'category': 'City',
      'rating': 4.6,
      'emoji': '🏙️',
      'description':
          'Enjoy luxury shopping, modern architecture, and desert adventures.',
      'color': Color(0xFFAB47BC),
      'favorite': false,
    },
    {
      'name': 'Paris',
      'country': 'France',
      'category': 'City',
      'rating': 4.9,
      'emoji': '🗼',
      'description':
          'Explore iconic landmarks, art, history, and French culture.',
      'color': Color(0xFFEF5350),
      'favorite': false,
    },
  ];

  final List<String> categories = [
    'All',
    'Beach',
    'Mountains',
    'City',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedDestinations());
  }

  Future<void> _loadSavedDestinations() async {
    try {
      final savedRows = await _destinationService.fetchSavedDestinations();
      if (!mounted) return;

      setState(() {
        for (final destination in destinations) {
          Map<String, dynamic>? matchingRow;
          for (final row in savedRows) {
            final sameName = (row['name'] ?? '')
                .toString()
                .trim()
                .toLowerCase() ==
                destination['name'].toString().trim().toLowerCase();
            final sameCountry = (row['address'] ?? '')
                .toString()
                .trim()
                .toLowerCase() ==
                destination['country'].toString().trim().toLowerCase();
            if (sameName && sameCountry) {
              matchingRow = row;
              break;
            }
          }

          destination['favorite'] = matchingRow != null;
          if (matchingRow != null) {
            destination['savedId'] = matchingRow['id'].toString();
          } else {
            destination.remove('savedId');
          }
        }
      });
    } catch (error) {
      debugPrint('Load saved destinations error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load saved destinations. Please try again.'),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredDestinations {
    return destinations.where((destination) {
      final name = destination['name'].toString().toLowerCase();
      final country = destination['country'].toString().toLowerCase();

      final matchesSearch = name.contains(searchQuery) ||
          country.contains(searchQuery);

      final matchesCategory = selectedCategory == 'All' ||
          destination['category'] == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> toggleFavorite(int index) async {
    if (_favoriteOperations.contains(index)) return;

    final destination = destinations[index];
    final wasFavorite = destination['favorite'] as bool? ?? false;

    setState(() {
      _favoriteOperations.add(index);
    });

    try {
      if (wasFavorite) {
        final savedId = destination['savedId']?.toString();
        if (savedId == null || savedId.isEmpty) {
          throw StateError('Saved destination record was not found.');
        }

        await _destinationService.removeSavedDestination(savedId);
        if (!mounted) return;

        setState(() {
          destination['favorite'] = false;
          destination.remove('savedId');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${destination['name']} removed from favourites.',
            ),
          ),
        );
      } else {
        final savedRow = await _destinationService.saveDestination(
          name: destination['name'].toString(),
          address: destination['country'].toString(),
          category: destination['category'].toString(),
          notes: destination['description'].toString(),
        );
        if (!mounted) return;

        setState(() {
          destination['favorite'] = true;
          destination['savedId'] = savedRow['id'].toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${destination['name']} added to favourites.',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Toggle destination favourite error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update favourites. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoriteOperations.remove(index);
        });
      }
    }
  }

  void openDestination(Map<String, dynamic> destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationDetailsScreen(
          destination: destination,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredDestinations;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Explore Destinations',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search destination or country...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF1565C0),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 42,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    selectedColor: const Color(0xFF1565C0),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final destination = filtered[index];

                      final originalIndex =
                          destinations.indexOf(destination);

                      return _buildDestinationCard(
                        destination,
                        originalIndex,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(
    Map<String, dynamic> destination,
    int originalIndex,
  ) {
    final bool isFavorite = destination['favorite'] as bool;

    return GestureDetector(
      onTap: () {
        openDestination(destination);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    destination['color'] as Color,
                    (destination['color'] as Color).withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      destination['emoji'],
                      style: const TextStyle(
                        fontSize: 70,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _favoriteOperations.contains(originalIndex)
                            ? null
                            : () => toggleFavorite(originalIndex),
                        icon: _favoriteOperations.contains(originalIndex)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 15,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        destination['category'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          destination['name'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        destination['rating'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        destination['country'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    destination['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        openDestination(destination);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Explore Destination',
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.travel_explore,
              size: 75,
              color: Colors.grey,
            ),

            const SizedBox(height: 20),

            const Text(
              'No Destinations Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Try searching for another destination.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DestinationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailsScreen({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final color = destination['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Text(
          destination['name'],
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(
                  destination['emoji'],
                  style: const TextStyle(
                    fontSize: 100,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: Text(
                    destination['name'],
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        destination['rating'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF1565C0),
                ),
                const SizedBox(width: 5),
                Text(
                  destination['country'],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'About this destination',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              destination['description'],
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Quick Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _buildInfoRow(
              Icons.category,
              'Category',
              destination['category'],
            ),

            _buildInfoRow(
              Icons.star,
              'Rating',
              '${destination['rating']} / 5',
            ),

            _buildInfoRow(
              Icons.location_city,
              'Country',
              destination['country'],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Trip planning integration coming soon!',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.card_travel),
                label: const Text(
                  'Plan a Trip Here',
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

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  final placeQuery =
                      '${destination['name']}, ${destination['country']}';
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MapsScreen(
                        initialPlaceQuery: placeQuery,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.map,
                  color: Color(0xFF1565C0),
                ),
                label: const Text(
                  'View on Map',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF1565C0),
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

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}