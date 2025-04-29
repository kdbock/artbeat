import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../routing/route_names.dart';
import '../core/themes/app_theme.dart';

class ArtMapScreen extends StatefulWidget {
  const ArtMapScreen({super.key});

  @override
  State<ArtMapScreen> createState() => _ArtMapScreenState();
}

class _ArtMapScreenState extends State<ArtMapScreen> {
  GoogleMapController? _mapController;
  bool _isLoading = true;
  final Map<String, Marker> _markers = {};
  final LatLng _defaultLocation = const LatLng(
    37.7749,
    -122.4194,
  ); // San Francisco by default
  int? _zipCode;
  List<ArtLocation> _artLocations = [];
  bool _isCreatingTour = false;
  final Set<String> _selectedArtLocations = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    
    try {
      final position = await locationService.getCurrentLocation();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14.0,
          ),
        );

        await _loadNearbyArtLocations(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _loadNearbyArtLocations(
    double latitude,
    double longitude,
  ) async {
    try {
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      final locations = await locationService.getNearbyArtLocations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 10.0,
      );

      if (mounted) {
        setState(() {
          _artLocations = locations;
          _updateMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading art locations: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _loadArtLocationsByZipCode() async {
    if (_zipCode == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      final locations = await locationService.getArtLocationsByZipCode(
        _zipCode!,
      );

      if (mounted) {
        setState(() {
          _artLocations = locations;
          _isLoading = false;
          _updateMarkers();
        });

        if (locations.isNotEmpty) {
          // Center map on the first location
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(locations.first.latitude, locations.first.longitude),
              14.0,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading art locations: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      for (final location in _artLocations) {
        _markers[location.id] = Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: location.title,
            snippet: location.description ?? 'Tap to view details',
            onTap: () {
              _showArtLocationDetails(location);
            },
          ),
          onTap: () {
            if (_isCreatingTour) {
              setState(() {
                if (_selectedArtLocations.contains(location.id)) {
                  _selectedArtLocations.remove(location.id);
                } else {
                  _selectedArtLocations.add(location.id);
                }
                _updateMarkers(); // Refresh markers to update icon
              });
            } else {
              _mapController?.showMarkerInfoWindow(MarkerId(location.id));
            }
          },
          icon:
              _isCreatingTour && _selectedArtLocations.contains(location.id)
                  ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  )
                  : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueViolet,
                  ),
        );
      }
    });
  }

  void _showArtLocationDetails(ArtLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, controller) => SingleChildScrollView(
                  controller: controller,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (location.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              location.imageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                    ),
                                  ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          location.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (location.description != null)
                          Text(
                            location.description!,
                            style: TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);

                                // Navigate to directions (in a real app, you'd use a maps API)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Navigation feature coming soon!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.directions),
                              label: const Text('Directions'),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  if (_isCreatingTour) {
                                    if (_selectedArtLocations.contains(
                                      location.id,
                                    )) {
                                      _selectedArtLocations.remove(location.id);
                                    } else {
                                      _selectedArtLocations.add(location.id);
                                    }
                                    _updateMarkers();
                                  } else {
                                    _isCreatingTour = true;
                                    _selectedArtLocations.clear();
                                    _selectedArtLocations.add(location.id);
                                    _updateMarkers();
                                  }
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Add to Tour'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _createWalkingTour() {
    if (_selectedArtLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one art location.'),
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be signed in to create a tour.'),
        ),
      );
      return;
    }

    Navigator.of(context)
        .pushNamed(
          RouteNames.createWalkingTour,
          arguments: {'artLocationIds': _selectedArtLocations.toList()},
        )
        .then((_) {
          // Reset tour creation mode after returning
          setState(() {
            _isCreatingTour = false;
            _selectedArtLocations.clear();
            _updateMarkers();
          });
        });
  }

  void _cancelTourCreation() {
    setState(() {
      _isCreatingTour = false;
      _selectedArtLocations.clear();
      _updateMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Map'),
        elevation: 0,
        actions: [
          if (_isCreatingTour)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelTourCreation,
              tooltip: 'Cancel Tour Creation',
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultLocation,
              zoom: 13.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers.values.toSet(),
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isLoading) {
                _getCurrentLocation();
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          // ZIP code search box
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter ZIP Code',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 5) {
                    try {
                      _zipCode = int.parse(value);
                      _loadArtLocationsByZipCode();
                    } catch (e) {
                      // Invalid ZIP code, ignore
                    }
                  }
                },
              ),
            ),
          ),

          // Tour creation info/controls
          if (_isCreatingTour)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Creating Walking Tour',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected locations: ${_selectedArtLocations.length}',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: _cancelTourCreation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white),
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: _createWalkingTour,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentColor,
                          ),
                          child: const Text('Create Tour'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          !_isCreatingTour && _artLocations.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _isCreatingTour = true;
                    _selectedArtLocations.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Select art locations to include in your tour',
                      ),
                    ),
                  );
                },
                label: const Text('Create Tour'),
                icon: const Icon(Icons.route),
                backgroundColor: AppColors.accentColor,
              )
              : null,
    );
  }
}
