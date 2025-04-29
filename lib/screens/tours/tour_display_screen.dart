import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../core/themes/app_theme.dart';

class TourDisplayScreen extends StatefulWidget {
  final String tourId;

  const TourDisplayScreen({Key? key, required this.tourId}) : super(key: key);

  @override
  _TourDisplayScreenState createState() => _TourDisplayScreenState();
}

class _TourDisplayScreenState extends State<TourDisplayScreen> {
  GoogleMapController? _mapController;
  WalkingTour? _tour;
  final Map<String, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadTourDetails();
  }

  Future<void> _loadTourDetails() async {
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final tour = await locationService.getWalkingTour(widget.tourId);

      if (mounted) {
        setState(() {
          _tour = tour;
          _addMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tour: $e')),
        );
      }
    }
  }

  void _addMarkers() {
    if (_tour == null) return;

    for (final location in _tour!.artLocations) {
      _markers[location.id] = Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.title,
          snippet: location.description,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tour?.title ?? 'Tour Details'),
      ),
      body: _tour == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _tour!.artLocations.first.latitude,
                        _tour!.artLocations.first.longitude,
                      ),
                      zoom: 13.0,
                    ),
                    markers: _markers.values.toSet(),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tour!.description,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Total Distance: ${_tour!.totalDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      Text(
                        'Estimated Time: ${_tour!.estimatedMinutes} minutes',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}