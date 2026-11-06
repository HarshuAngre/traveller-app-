
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  bool _isSearching = false;
  bool _isLoadingWeather = false;
  bool _hasSearched = false;

  String? _searchError;
  String? _weatherError;

  List<WeatherLocation> _locations = [];

  WeatherLocation? _selectedLocation;
  WeatherData? _weatherData;

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // SEARCH CITY USING OPEN-METEO GEOCODING API
  // --------------------------------------------------

  Future<void> _searchLocations() async {
    final query = _searchController.text.trim();

    if (query.length < 2) {
      setState(() {
        _searchError = 'Enter at least 2 characters.';
        _locations = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _locations = [];
      _hasSearched = false;
    });

    try {
      final uri = Uri.https(
        'geocoding-api.open-meteo.com',
        '/v1/search',
        {
          'name': query,
          'count': '8',
          'language': 'en',
          'format': 'json',
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Unable to search locations.');
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final results = data['results'];

      final List<WeatherLocation> foundLocations = [];

      if (results is List) {
        for (final result in results) {
          if (result is Map) {
            foundLocations.add(
              WeatherLocation.fromJson(
                Map<String, dynamic>.from(result),
              ),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _locations = foundLocations;
        _hasSearched = true;

        if (foundLocations.isEmpty) {
          _searchError = 'No matching city found. Try another name.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searchError =
            'Unable to search right now. Check your internet connection.';
      });

      debugPrint('Location search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // FETCH WEATHER INFORMATION
  // --------------------------------------------------

  Future<void> _loadWeather(WeatherLocation location) async {
    setState(() {
      _selectedLocation = location;
      _isLoadingWeather = true;
      _weatherError = null;
      _weatherData = null;
      _locations = [];
    });

    try {
      final uri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': location.latitude.toString(),
          'longitude': location.longitude.toString(),
          'current': [
            'temperature_2m',
            'relative_humidity_2m',
            'apparent_temperature',
            'is_day',
            'weather_code',
            'wind_speed_10m',
          ].join(','),
          'daily': [
            'weather_code',
            'temperature_2m_max',
            'temperature_2m_min',
            'precipitation_probability_max',
          ].join(','),
          'forecast_days': '5',
          'timezone': 'auto',
          'temperature_unit': 'celsius',
          'wind_speed_unit': 'kmh',
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Weather service returned an error.');
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (json['error'] == true) {
        throw Exception(
          json['reason'] ?? 'Weather information unavailable.',
        );
      }

      final result = WeatherData.fromJson(json);

      if (!mounted) return;

      setState(() {
        _weatherData = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _weatherError =
            'Could not load weather. Please check your connection and try again.';
      });

      debugPrint('Weather loading error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // MAIN SCREEN
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text(
          'Weather',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              tooltip: 'Refresh weather',
              onPressed: _isLoadingWeather
                  ? null
                  : () => _loadWeather(_selectedLocation!),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Weather Forecast',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Check the weather before you start your journey.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 25),

              // CITY SEARCH
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    const Icon(
                      Icons.search,
                      color: primaryBlue,
                      size: 25,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchLocations(),
                        decoration: const InputDecoration(
                          hintText: 'Search city (e.g. Mumbai)',
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed:
                          _isSearching ? null : _searchLocations,
                      icon: _isSearching
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryBlue,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              color: primaryBlue,
                            ),
                    ),
                  ],
                ),
              ),

              // SEARCH ERROR
              if (_searchError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _searchError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],

              // CITY SEARCH RESULTS
              if (_locations.isNotEmpty) ...[
                const SizedBox(height: 20),

                const Text(
                  'Select a Location',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: _locations.map((location) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE3F2FD),
                          child: Icon(
                            Icons.location_on,
                            color: primaryBlue,
                          ),
                        ),
                        title: Text(
                          location.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (location.admin1 != null)
                              location.admin1!,
                            if (location.country != null)
                              location.country!,
                          ].join(', '),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 15,
                        ),
                        onTap: () => _loadWeather(location),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // LOADING WEATHER
              if (_isLoadingWeather) ...[
                const SizedBox(height: 50),
                const Center(
                  child: CircularProgressIndicator(
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 15),
                const Center(
                  child: Text(
                    'Loading weather information...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],

              // WEATHER ERROR
              if (_weatherError != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _weatherError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _selectedLocation == null
                            ? null
                            : () => _loadWeather(_selectedLocation!),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ],

              // WEATHER CONTENT
              if (_weatherData != null &&
                  _selectedLocation != null) ...[
                const SizedBox(height: 25),

                _buildCurrentWeather(
                  _selectedLocation!,
                  _weatherData!,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Weather Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        Icons.thermostat,
                        'Feels Like',
                        '${_weatherData!.feelsLike.round()}°C',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        Icons.water_drop_outlined,
                        'Humidity',
                        '${_weatherData!.humidity}%',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        Icons.air,
                        'Wind',
                        '${_weatherData!.windSpeed.round()} km/h',
                        Colors.teal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  '5-Day Forecast',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ..._weatherData!.forecast.map(
                  (day) => _buildForecastCard(day),
                ),

                const SizedBox(height: 15),

                const Center(
                  child: Text(
                    'Weather data provided by Open-Meteo',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],

              // INITIAL EMPTY STATE
              if (_weatherData == null &&
                  !_isLoadingWeather &&
                  _weatherError == null &&
                  _locations.isEmpty &&
                  !_hasSearched) ...[
                const SizedBox(height: 75),
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_outlined,
                        size: 95,
                        color: Color(0xFF90CAF9),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Explore Weather Anywhere',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Search for a city to see its current weather and 5-day forecast.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CURRENT WEATHER CARD
  // --------------------------------------------------

  Widget _buildCurrentWeather(
    WeatherLocation location,
    WeatherData weather,
  ) {
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [

          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              [
                if (location.admin1 != null) location.admin1!,
                if (location.country != null) location.country!,
              ].join(', '),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 55,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      weatherDescription(weather.weatherCode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                weatherIcon(
                  weather.weatherCode,
                  weather.isDay,
                ),
                color: Colors.white,
                size: 85,
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(color: Colors.white30),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Weather',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // WEATHER METRIC CARD
  // --------------------------------------------------

  Widget _buildMetricCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 27,
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // FIVE-DAY FORECAST CARD
  // --------------------------------------------------

  Widget _buildForecastCard(DailyForecast day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [

          Expanded(
            flex: 2,
            child: Text(
              formatForecastDate(day.date),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Icon(
            weatherIcon(day.weatherCode, true),
            color: primaryBlue,
            size: 27,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              weatherDescription(day.weatherCode),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),

          Text(
            '${day.maxTemperature.round()}°',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '${day.minTemperature.round()}°',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// LOCATION MODEL
// --------------------------------------------------

class WeatherLocation {
  final String name;
  final String? admin1;
  final String? country;
  final double latitude;
  final double longitude;

  const WeatherLocation({
    required this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      name: json['name']?.toString() ?? 'Unknown',
      admin1: json['admin1']?.toString(),
      country: json['country']?.toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

// --------------------------------------------------
// WEATHER DATA MODEL
// --------------------------------------------------

class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;
  final List<DailyForecast> forecast;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    required this.forecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current =
        json['current'] as Map<String, dynamic>? ?? {};

    final daily =
        json['daily'] as Map<String, dynamic>? ?? {};

    final times = daily['time'] as List? ?? [];
    final maxTemps = daily['temperature_2m_max'] as List? ?? [];
    final minTemps = daily['temperature_2m_min'] as List? ?? [];
    final codes = daily['weather_code'] as List? ?? [];
    final rainProbabilities =
        daily['precipitation_probability_max'] as List? ?? [];

    final List<DailyForecast> forecast = [];

    for (int i = 0; i < times.length; i++) {
      forecast.add(
        DailyForecast(
          date: times[i].toString(),
          maxTemperature: _toDouble(
            i < maxTemps.length ? maxTemps[i] : null,
          ),
          minTemperature: _toDouble(
            i < minTemps.length ? minTemps[i] : null,
          ),
          weatherCode: _toInt(
            i < codes.length ? codes[i] : null,
          ),
          rainProbability: _toInt(
            i < rainProbabilities.length
                ? rainProbabilities[i]
                : null,
          ),
        ),
      );
    }

    return WeatherData(
      temperature: _toDouble(current['temperature_2m']),
      feelsLike: _toDouble(current['apparent_temperature']),
      humidity: _toInt(current['relative_humidity_2m']),
      windSpeed: _toDouble(current['wind_speed_10m']),
      weatherCode: _toInt(current['weather_code']),
      isDay: current['is_day'] == 1,
      forecast: forecast,
    );
  }
}

// --------------------------------------------------
// DAILY FORECAST MODEL
// --------------------------------------------------

class DailyForecast {
  final String date;
  final double maxTemperature;
  final double minTemperature;
  final int weatherCode;
  final int rainProbability;

  const DailyForecast({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.weatherCode,
    required this.rainProbability,
  });
}

// --------------------------------------------------
// SAFE NUMBER CONVERSION
// --------------------------------------------------

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _toInt(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

// --------------------------------------------------
// WEATHER DESCRIPTION
// --------------------------------------------------

String weatherDescription(int code) {
  switch (code) {
    case 0:
      return 'Clear Sky';
    case 1:
      return 'Mainly Clear';
    case 2:
      return 'Partly Cloudy';
    case 3:
      return 'Overcast';
    case 45:
    case 48:
      return 'Foggy';
    case 51:
    case 53:
    case 55:
      return 'Drizzle';
    case 56:
    case 57:
      return 'Freezing Drizzle';
    case 61:
    case 63:
    case 65:
      return 'Rain';
    case 66:
    case 67:
      return 'Freezing Rain';
    case 71:
    case 73:
    case 75:
      return 'Snowfall';
    case 77:
      return 'Snow Grains';
    case 80:
    case 81:
    case 82:
      return 'Rain Showers';
    case 85:
    case 86:
      return 'Snow Showers';
    case 95:
      return 'Thunderstorm';
    case 96:
    case 99:
      return 'Thunderstorm with Hail';
    default:
      return 'Unknown Conditions';
  }
}

// --------------------------------------------------
// WEATHER ICON
// --------------------------------------------------

IconData weatherIcon(int code, bool isDay) {
  if (code == 0) {
    return isDay
        ? Icons.wb_sunny_rounded
        : Icons.nightlight_round;
  }

  if (code == 1 || code == 2) {
    return Icons.wb_cloudy_rounded;
  }

  if (code == 3 || code == 45 || code == 48) {
    return Icons.cloud;
  }

  if (code >= 51 && code <= 67) {
    return Icons.grain;
  }

  if (code >= 71 && code <= 77) {
    return Icons.ac_unit;
  }

  if (code >= 80 && code <= 82) {
    return Icons.water_drop;
  }

  if (code == 85 || code == 86) {
    return Icons.ac_unit;
  }

  if (code >= 95) {
    return Icons.thunderstorm;
  }

  return Icons.cloud_outlined;
}

// --------------------------------------------------
// FORMAT FORECAST DATE
// --------------------------------------------------

String formatForecastDate(String date) {
  final parsed = DateTime.tryParse(date);

  if (parsed == null) return date;

  const weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${weekdays[parsed.weekday - 1]}, '
      '${parsed.day} ${months[parsed.month - 1]}';
}
