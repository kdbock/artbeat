import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show pi, sin, asin, cos, sqrt;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

// Model for a public art location
class ArtLocation {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? artistId;
  final String? artistName;
  final List<String> tags;
  final DateTime createdAt;
  final bool isPubliclyVisible;

  ArtLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.artistId,
    this.artistName,
    required this.tags,
    required this.createdAt,
    required this.isPubliclyVisible,
  });

  factory ArtLocation.fromJson(Map<String, dynamic> json) {
    return ArtLocation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      imageUrl: json['imageUrl'],
      artistId: json['artistId'],
      artistName: json['artistName'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      isPubliclyVisible: json['isPubliclyVisible'] ?? true,
    );
  }
}

// Model for a walking art tour
class WalkingTour {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String creatorId;
  final String? creatorName;
  final List<ArtLocation> artLocations;
  final double totalDistanceKm;
  final int estimatedMinutes;
  final DateTime createdAt;
  final bool isPublic;

  WalkingTour({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.creatorId,
    this.creatorName,
    required this.artLocations,
    required this.totalDistanceKm,
    required this.estimatedMinutes,
    required this.createdAt,
    required this.isPublic,
  });

  factory WalkingTour.fromJson(Map<String, dynamic> json) {
    return WalkingTour(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      creatorId: json['creatorId'],
      creatorName: json['creatorName'],
      artLocations:
          (json['artLocations'] as List)
              .map((location) => ArtLocation.fromJson(location))
              .toList(),
      totalDistanceKm: json['totalDistanceKm'].toDouble(),
      estimatedMinutes: json['estimatedMinutes'],
      createdAt: DateTime.parse(json['createdAt']),
      isPublic: json['isPublic'] ?? true,
    );
  }
}

class LocationService extends ChangeNotifier {
  final Location _locationService = Location();
  final _uuid = const Uuid();
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _apiBaseUrl =
      'https://api.artbeat.example.com'; // Replace with actual API URL
  final String _googleMapsApiKey =
      'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual API key

  // Get the user's current location
  Future<LocationData> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
    }

    // Check for location permissions
    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Location permissions are denied');
      }
    }

    // Get current location
    return await _locationService.getLocation();
  }

  // Get all public art locations
  Future<List<ArtLocation>> getPublicArtLocations({
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<String>? tags,
  }) async {
    try {
      String url = '$_apiBaseUrl/art-locations?public=true';

      if (latitude != null && longitude != null && radiusKm != null) {
        url += '&lat=$latitude&lng=$longitude&radius=$radiusKm';
      }

      if (tags != null && tags.isNotEmpty) {
        final tagsString = tags.join(',');
        url += '&tags=$tagsString';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => ArtLocation.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load art locations: ${response.statusCode}');
      }
    } catch (e) {
      // In a real app, you would log this error
      throw Exception('Error fetching art locations: $e');
    }
  }

  // Get a single art location by ID
  Future<ArtLocation?> getArtLocationById(String locationId) async {
    try {
      final response =
          await _supabase
              .from('art_locations')
              .select()
              .eq('id', locationId)
              .single()
              .execute();

      if (response.data != null) {
        return ArtLocation.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Add a new art location
  Future<ArtLocation> addArtLocation({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    String? imageUrl,
    String? artistId,
    List<String>? tags,
    bool isPubliclyVisible = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/art-locations'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'title': title,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'imageUrl': imageUrl,
          'artistId': artistId,
          'tags': tags ?? [],
          'isPubliclyVisible': isPubliclyVisible,
        }),
      );

      if (response.statusCode == 201) {
        return ArtLocation.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create art location: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error adding art location: $e');
    }
  }

  // Get walking tours
  Future<List<WalkingTour>> getWalkingTours({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      String url = '$_apiBaseUrl/walking-tours';

      if (latitude != null && longitude != null && radiusKm != null) {
        url += '?lat=$latitude&lng=$longitude&radius=$radiusKm';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => WalkingTour.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load walking tours: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching walking tours: $e');
    }
  }

  // Get a single walking tour by ID
  Future<WalkingTour> getWalkingTour(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/walking-tours/$id'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return WalkingTour.fromJson(jsonData);
      } else {
        throw Exception('Failed to load walking tour: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching walking tour: $e');
    }
  }

  // Create a new walking tour
  Future<bool> createWalkingTour({
    required String title,
    required String description,
    required List<ArtLocation> artLocations,
    required String creatorId,
    String? creatorName,
    File? imageFile,
    double totalDistanceKm = 0.0,
    int estimatedMinutes = 0,
    bool isPublic = true,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        final ext = path.extension(imageFile.path);
        final filename = 'tour_${_uuid.v4()}$ext';

        await _supabase.storage
            .from('tour_images')
            .upload(
              filename,
              imageFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        imageUrl = _supabase.storage.from('tour_images').getPublicUrl(filename);
      }

      // Convert art location IDs for database
      final List<String> locationIds =
          artLocations.map((loc) => loc.id).toList();

      final tourId = _uuid.v4();

      // Create tour record
      await _supabase.from('walking_tours').insert({
        'id': tourId,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'creator_id': creatorId,
        'creator_name': creatorName,
        'art_location_ids': locationIds,
        'total_distance_km': totalDistanceKm,
        'estimated_minutes': estimatedMinutes,
        'is_public': isPublic,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Logger.logError('Error creating walking tour', e);
      return false;
    }
  }

  // Calculate the distance between two coordinates using the Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert latitude and longitude from degrees to radians
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    // Haversine formula
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Calculate the total distance of a walking tour
  double _calculateTotalDistance(List<ArtLocation> locations) {
    double totalDistance = 0.0;

    for (int i = 0; i < locations.length - 1; i++) {
      final currentLocation = locations[i];
      final nextLocation = locations[i + 1];

      totalDistance += calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        nextLocation.latitude,
        nextLocation.longitude,
      );
    }

    return totalDistance;
  }

  // Estimate the time to complete a walking tour (in minutes)
  int _calculateEstimatedTime(double distanceKm) {
    // Assume average walking speed of 5 km/h (plus extra time for viewing art)
    const double walkingSpeedKmH = 5.0;
    const int minutesPerArtwork = 5; // Average viewing time per artwork

    // Walking time in hours
    final double walkingTimeHours = distanceKm / walkingSpeedKmH;
    // Convert to minutes
    final int walkingTimeMinutes = (walkingTimeHours * 60).round();

    // Add viewing time
    return walkingTimeMinutes;
  }

  // Get directions between locations
  Future<Map<String, dynamic>> getDirections(
    LatLng origin,
    LatLng destination, {
    List<LatLng>? waypoints,
  }) async {
    try {
      String url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=walking'
          '&key=$_googleMapsApiKey';

      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointsString = waypoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join('|');
        url += '&waypoints=$waypointsString';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting directions: $e');
    }
  }

  // Get a map marker image for an art location
  Future<BitmapDescriptor> getArtLocationMarker() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
  }

  // Search for art locations by keyword
  Future<List<ArtLocation>> searchArtLocations(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/art-locations/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => ArtLocation.fromJson(data)).toList();
      } else {
        throw Exception(
          'Failed to search art locations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error searching art locations: $e');
    }
  }
}
