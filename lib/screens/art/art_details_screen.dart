import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/artist_service.dart';
import '../../services/auth_service.dart';
import '../../core/themes/app_theme.dart';
import '../../routing/route_names.dart';

class ArtDetailsScreen extends StatefulWidget {
  final String artId;

  const ArtDetailsScreen({super.key, required this.artId});

  @override
  State<ArtDetailsScreen> createState() => _ArtDetailsScreenState();
}

class _ArtDetailsScreenState extends State<ArtDetailsScreen> {
  bool _isLoading = true;
  bool _isFavorite = false;
  Artwork? _artwork;
  ArtistProfile? _artist;

  @override
  void initState() {
    super.initState();
    _loadArtworkDetails();
  }

  Future<void> _loadArtworkDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final artistService = Provider.of<ArtistService>(context, listen: false);
      final artwork = await artistService.getArtworkById(widget.artId);

      if (artwork != null && mounted) {
        final artist = await artistService.getArtistProfileById(
          artwork.artistId,
        );

        if (mounted) {
          setState(() {
            _artwork = artwork;
            _artist = artist;
            _isLoading = false;
          });

          // Check if artwork is in favorites
          _checkFavoriteStatus();
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Artwork not found')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artwork: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) return;

    final userProfile = await authService.getUserProfile();
    final artistService = Provider.of<ArtistService>(context, listen: false);

    final isFavorite = await artistService.isArtworkInFavorites(
      userProfile.id,
      widget.artId,
    );

    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save artwork to favorites'),
        ),
      );
      return;
    }

    final artistService = Provider.of<ArtistService>(context, listen: false);
    final userProfile = await authService.getUserProfile();
    bool success;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      success = await artistService.addArtworkToFavorites(
        userProfile.id,
        _artwork!.id,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
      }
    } else {
      success = await artistService.removeArtworkFromFavorites(
        userProfile.id,
        _artwork!.id,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
      }
    }

    if (!success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed, please try again')),
      );
    }
  }

  void _shareArtwork() {
    if (_artwork == null) return;

    final String artText =
        'Check out this artwork: ${_artwork!.title} by ${_artist?.displayName ?? 'Artist'}\n${_artwork!.imageUrl}';
    Share.share(artText);
  }

  void _viewArtistProfile() {
    if (_artwork?.artistId == null) return;

    Navigator.of(context).pushNamed(
      RouteNames.artistProfile,
      arguments: {'artistId': _artwork!.artistId},
    );
  }

  void _contactArtist() async {
    if (_artist == null) return;

    String contactMethod = '';

    if (_artist!.email != null) {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: _artist!.email,
        query: 'subject=Inquiry about ${_artwork!.title}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return;
      } else {
        contactMethod = 'email';
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            contactMethod.isNotEmpty
                ? 'Could not open $contactMethod app'
                : 'No contact information available',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _artwork == null
              ? const Center(child: Text('Artwork not found'))
              : _buildArtworkDetails(),
    );
  }

  Widget _buildArtworkDetails() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350.0,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'artwork-${_artwork!.id}',
              child: Image.network(
                _artwork!.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              color: _isFavorite ? AppColors.accentColor : Colors.white,
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              color: Colors.white,
              onPressed: _shareArtwork,
            ),
          ],
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and basic info
                  Text(
                    _artwork!.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Artist info with link
                  GestureDetector(
                    onTap: _viewArtistProfile,
                    child: Text(
                      _artist?.displayName ?? 'Unknown Artist',
                      style: TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Artwork details card
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
                          if (_artwork!.price != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Price',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '\$${_artwork!.price!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                          ],

                          if (_artwork!.medium != null) ...[
                            const Text(
                              'Medium',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _artwork!.medium!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (_artwork!.dimensions != null) ...[
                            const Text(
                              'Dimensions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _artwork!.dimensions!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (_artwork!.isForSale)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Available for Purchase',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (_artwork!.description != null) ...[
                    const Text(
                      'About this Artwork',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _artwork!.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Artist info card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _viewArtistProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About the Artist',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      _artist?.profileImageUrl != null
                                          ? NetworkImage(
                                            _artist!.profileImageUrl!,
                                          )
                                          : null,
                                  child:
                                      _artist?.profileImageUrl == null
                                          ? const Icon(Icons.person, size: 30)
                                          : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _artist?.displayName ?? 'Artist',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (_artist?.location != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _artist!.location!,
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_artist?.bio != null &&
                                _artist!.bio.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _artist!.bio,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _viewArtistProfile,
                                icon: const Icon(Icons.person),
                                label: const Text('View Profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  if (_artwork!.isForSale) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _contactArtist,
                        icon: const Icon(Icons.email),
                        label: const Text('Inquire About This Piece'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _shareArtwork,
                      icon: const Icon(Icons.share),
                      label: const Text('Share Artwork'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
