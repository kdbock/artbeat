import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../core/themes/app_theme.dart';

class CreateWalkingTourScreen extends StatefulWidget {
  final List<String> artLocationIds;

  const CreateWalkingTourScreen({super.key, required this.artLocationIds});

  @override
  State<CreateWalkingTourScreen> createState() =>
      _CreateWalkingTourScreenState();
}

class _CreateWalkingTourScreenState extends State<CreateWalkingTourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<ArtLocation> _selectedLocations = [];
  File? _imageFile;
  bool _isPublic = true;
  bool _isLoading = true;
  bool _isSaving = false;
  double _totalDistanceKm = 0.0;
  int _estimatedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadArtLocations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadArtLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );

      // Get details for each selected art location
      final List<ArtLocation> locations = [];

      for (final locationId in widget.artLocationIds) {
        final location = await locationService.getArtLocationById(locationId);
        if (location != null) {
          locations.add(location);
        }
      }

      // Calculate tour metrics
      if (locations.length > 1) {
        double totalDistance = 0.0;
        for (int i = 0; i < locations.length - 1; i++) {
          double distance = locationService.calculateDistance(
            locations[i].latitude,
            locations[i].longitude,
            locations[i + 1].latitude,
            locations[i + 1].longitude,
          );
          totalDistance += distance;
        }

        _totalDistanceKm = totalDistance;
        // Rough estimate: Walking speed of 5 km/h + 10 min viewing time per location
        _estimatedMinutes =
            ((totalDistance / 5.0) * 60).round() + (locations.length * 10);
      }

      if (mounted) {
        setState(() {
          _selectedLocations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading art locations: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _reorderLocations(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedLocations.removeAt(oldIndex);
      _selectedLocations.insert(newIndex, item);

      // Recalculate distance and time after reordering
      if (_selectedLocations.length > 1) {
        final locationService = Provider.of<LocationService>(
          context,
          listen: false,
        );
        double totalDistance = 0.0;
        for (int i = 0; i < _selectedLocations.length - 1; i++) {
          double distance = locationService.calculateDistance(
            _selectedLocations[i].latitude,
            _selectedLocations[i].longitude,
            _selectedLocations[i + 1].latitude,
            _selectedLocations[i + 1].longitude,
          );
          totalDistance += distance;
        }

        _totalDistanceKm = totalDistance;
        _estimatedMinutes =
            ((totalDistance / 5.0) * 60).round() +
            (_selectedLocations.length * 10);
      }
    });
  }

  Future<void> _createTour() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No art locations selected')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );

      final userProfile = await authService.getUserProfile();

      final success = await locationService.createWalkingTour(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        artLocations: _selectedLocations,
        creatorId: userProfile.id,
        creatorName: userProfile.displayName,
        imageFile: _imageFile,
        totalDistanceKm: _totalDistanceKm,
        estimatedMinutes: _estimatedMinutes,
        isPublic: _isPublic,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Walking tour created successfully!')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create walking tour')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Walking Tour'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isSaving
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Creating your tour...'),
                  ],
                ),
              )
              : _selectedLocations.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.route_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No art locations selected',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tour info card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Tour Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildInfoItem(
                                    Icons.place,
                                    '${_selectedLocations.length} Locations',
                                    Colors.blue,
                                  ),
                                  _buildInfoItem(
                                    Icons.straighten,
                                    '${_totalDistanceKm.toStringAsFixed(1)} km',
                                    Colors.green,
                                  ),
                                  _buildInfoItem(
                                    Icons.timer,
                                    '${_estimatedMinutes} min',
                                    Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tour image
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                              image:
                                  _imageFile != null
                                      ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                _imageFile == null
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add Tour Cover Image',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '(Optional)',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tour Name
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tour Name',
                          hintText: 'Enter a name for your walking tour',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name for your tour';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe your walking tour',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description for your tour';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Visibility toggle
                      SwitchListTile(
                        title: const Text('Public Tour'),
                        subtitle: const Text(
                          'Public tours are visible to all users',
                        ),
                        value: _isPublic,
                        activeColor: AppColors.accentColor,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Location order section
                      const Row(
                        children: [
                          Icon(Icons.sort),
                          SizedBox(width: 8),
                          Text(
                            'Tour Stops',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Drag to reorder the stops on your tour:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Reorderable list of locations
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedLocations.length,
                        onReorder: _reorderLocations,
                        itemBuilder: (context, index) {
                          final location = _selectedLocations[index];
                          return Card(
                            key: ValueKey(location.id),
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                location.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                location.artistName ?? 'Unknown Artist',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              trailing: const Icon(Icons.drag_handle),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Create Tour Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createTour,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Create Tour',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
