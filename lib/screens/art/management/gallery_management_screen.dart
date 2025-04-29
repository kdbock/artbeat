import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/artist_service.dart';
import '../../../core/themes/app_theme.dart';

class GalleryManagementScreen extends StatefulWidget {
  const GalleryManagementScreen({super.key});

  @override
  State<GalleryManagementScreen> createState() =>
      _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends State<GalleryManagementScreen> {
  bool _isLoading = false;
  String? _artistId;
  List<Artwork> _artworks = [];
  String _currentView = 'grid';
  String? _errorMessage;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mediumController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isForSale = true;
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mediumController.dispose();
    _dimensionsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (!authService.isArtist) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You need an artist account to manage gallery';
        });
        return;
      }

      final artistProfile = await authService.getArtistProfile();
      if (artistProfile == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load artist profile';
        });
        return;
      }

      _artistId = artistProfile.id;
      await _loadArtworks();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadArtworks() async {
    if (_artistId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final artistService = Provider.of<ArtistService>(context, listen: false);
      final artworks = await artistService.getArtistArtworks(_artistId!);

      if (mounted) {
        setState(() {
          _artworks = artworks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load artworks';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addArtwork() async {
    if (_artistId == null ||
        _imageFile == null ||
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final artistService = Provider.of<ArtistService>(context, listen: false);
      double? price;

      if (_isForSale && _priceController.text.isNotEmpty) {
        price = double.tryParse(_priceController.text);
      }

      final success = await artistService.addArtwork(
        artistId: _artistId!,
        title: _titleController.text,
        imageFile: _imageFile!,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        medium:
            _mediumController.text.isNotEmpty ? _mediumController.text : null,
        dimensions:
            _dimensionsController.text.isNotEmpty
                ? _dimensionsController.text
                : null,
        price: price,
        isForSale: _isForSale,
      );

      if (success && mounted) {
        _resetForm();
        await _loadArtworks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork added successfully')),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add artwork')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _mediumController.clear();
    _dimensionsController.clear();
    _priceController.clear();
    _isForSale = true;

    setState(() {
      _imageFile = null;
      _isLoading = false;
    });
  }

  Future<void> _showAddArtworkDialog() async {
    _resetForm();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add New Artwork',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Selection
                              Center(
                                child: GestureDetector(
                                  onTap: () async {
                                    await _pickImage();
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
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
                                            ? const Center(
                                              child: Icon(
                                                Icons.add_photo_alternate,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  _imageFile == null
                                      ? 'Tap to select image'
                                      : 'Tap to change image',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Title
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
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
                                  border: OutlineInputBorder(),
                                ),
                                minLines: 3,
                                maxLines: 5,
                              ),
                              const SizedBox(height: 16),

                              // Medium
                              TextFormField(
                                controller: _mediumController,
                                decoration: const InputDecoration(
                                  labelText: 'Medium',
                                  hintText: 'e.g., Oil on canvas',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dimensions
                              TextFormField(
                                controller: _dimensionsController,
                                decoration: const InputDecoration(
                                  labelText: 'Dimensions',
                                  hintText: 'e.g., 24 x 36 inches',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // For Sale Switch
                              Row(
                                children: [
                                  Text(
                                    'Available for Sale',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _isForSale,
                                    onChanged: (value) {
                                      setState(() {
                                        _isForSale = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Price
                              if (_isForSale)
                                TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                    hintText: 'e.g., 500.00',
                                    prefixText: '\$ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (_isForSale &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please enter a price';
                                    }
                                    if (_isForSale) {
                                      final price = double.tryParse(value!);
                                      if (price == null || price <= 0) {
                                        return 'Please enter a valid price';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _imageFile == null
                                      ? null
                                      : () async {
                                        if (_formKey.currentState!.validate()) {
                                          Navigator.pop(context);
                                          await _addArtwork();
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Add Artwork'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showArtworkOptionsDialog(Artwork artwork) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Artwork'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditArtworkDialog(artwork);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Artwork',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(artwork.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to artwork details screen
                  // TODO: Implement this navigation
                },
              ),
              const Divider(),
              ListTile(
                title: const Center(child: Text('Cancel')),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditArtworkDialog(Artwork artwork) async {
    // Initialize controllers with artwork values
    _titleController.text = artwork.title;
    _descriptionController.text = artwork.description ?? '';
    _mediumController.text = artwork.medium ?? '';
    _dimensionsController.text = artwork.dimensions ?? '';
    _priceController.text = artwork.price?.toString() ?? '';
    _isForSale = artwork.isForSale;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Artwork',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current Image
                              Center(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(artwork.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Title
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
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
                                  border: OutlineInputBorder(),
                                ),
                                minLines: 3,
                                maxLines: 5,
                              ),
                              const SizedBox(height: 16),

                              // Medium
                              TextFormField(
                                controller: _mediumController,
                                decoration: const InputDecoration(
                                  labelText: 'Medium',
                                  hintText: 'e.g., Oil on canvas',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dimensions
                              TextFormField(
                                controller: _dimensionsController,
                                decoration: const InputDecoration(
                                  labelText: 'Dimensions',
                                  hintText: 'e.g., 24 x 36 inches',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // For Sale Switch
                              Row(
                                children: [
                                  Text(
                                    'Available for Sale',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _isForSale,
                                    onChanged: (value) {
                                      setState(() {
                                        _isForSale = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Price
                              if (_isForSale)
                                TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                    hintText: 'e.g., 500.00',
                                    prefixText: '\$ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (_isForSale &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please enter a price';
                                    }
                                    if (_isForSale) {
                                      final price = double.tryParse(value!);
                                      if (price == null || price <= 0) {
                                        return 'Please enter a valid price';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pop(context);
                                  await _updateArtwork(artwork.id);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateArtwork(String artworkId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final artistService = Provider.of<ArtistService>(context, listen: false);
      double? price;

      if (_isForSale && _priceController.text.isNotEmpty) {
        price = double.tryParse(_priceController.text);
      }

      final success = await artistService.updateArtwork(
        artworkId: artworkId,
        title: _titleController.text,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        medium:
            _mediumController.text.isNotEmpty ? _mediumController.text : null,
        dimensions:
            _dimensionsController.text.isNotEmpty
                ? _dimensionsController.text
                : null,
        price: price,
        isForSale: _isForSale,
      );

      if (success && mounted) {
        await _loadArtworks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork updated successfully')),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update artwork')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _showDeleteConfirmation(String artworkId) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Artwork?'),
            content: const Text(
              'This action cannot be undone. Are you sure you want to delete this artwork?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteArtwork(artworkId);
                },
                child: const Text(
                  'DELETE',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteArtwork(String artworkId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final artistService = Provider.of<ArtistService>(context, listen: false);
      final success = await artistService.deleteArtwork(artworkId);

      if (success && mounted) {
        await _loadArtworks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork deleted successfully')),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete artwork')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _artworks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery Management')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadArtistProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery Management'),
        actions: [
          IconButton(
            icon: Icon(
              _currentView == 'grid' ? Icons.view_list : Icons.grid_view,
            ),
            onPressed: () {
              setState(() {
                _currentView = _currentView == 'grid' ? 'list' : 'grid';
              });
            },
            tooltip: _currentView == 'grid' ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArtworks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _artworks.isEmpty
              ? _buildEmptyGallery()
              : RefreshIndicator(
                onRefresh: _loadArtworks,
                child:
                    _currentView == 'grid'
                        ? _buildGridView()
                        : _buildListView(),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddArtworkDialog,
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyGallery() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your gallery is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first artwork to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddArtworkDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Artwork'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _artworks.length,
        itemBuilder: (context, index) {
          final artwork = _artworks[index];
          return _buildArtworkGridItem(artwork);
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _artworks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final artwork = _artworks[index];
        return _buildArtworkListItem(artwork);
      },
    );
  }

  Widget _buildArtworkGridItem(Artwork artwork) {
    return GestureDetector(
      onTap: () => _showArtworkOptionsDialog(artwork),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(artwork.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Artwork info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (artwork.medium != null && artwork.medium!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        artwork.medium!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  if (artwork.isForSale && artwork.price != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '\$${artwork.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.accentColor,
                          fontWeight: FontWeight.bold,
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

  Widget _buildArtworkListItem(Artwork artwork) {
    return GestureDetector(
      onTap: () => _showArtworkOptionsDialog(artwork),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Artwork thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(artwork.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Artwork info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (artwork.medium != null && artwork.medium!.isNotEmpty)
                      Text(
                        artwork.medium!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    const SizedBox(height: 4),
                    if (artwork.dimensions != null &&
                        artwork.dimensions!.isNotEmpty)
                      Text(
                        artwork.dimensions!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    if (artwork.isForSale)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child:
                            artwork.price != null
                                ? Text(
                                  'For sale: \$${artwork.price!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: AppColors.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : Text(
                                  'For sale',
                                  style: TextStyle(
                                    color: AppColors.accentColor,
                                  ),
                                ),
                      ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showArtworkOptionsDialog(artwork),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
