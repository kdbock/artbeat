import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/artist_service.dart';
import '../routing/route_names.dart';
import '../core/themes/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<ArtistProfile> _artists = [];
  int? _zipCode;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArtists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final artistService = Provider.of<ArtistService>(context, listen: false);
      final artists = await artistService.searchArtists(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        zipCode: _zipCode,
      );

      setState(() {
        _artists = artists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Artists'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search artists, styles, or mediums...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadArtists();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onSubmitted: (_) => _loadArtists(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Filter by ZIP Code',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 5) {
                            try {
                              _zipCode = int.parse(value);
                              _loadArtists();
                            } catch (e) {
                              // Invalid zip code, ignore
                            }
                          } else if (value.isEmpty) {
                            setState(() {
                              _zipCode = null;
                            });
                            _loadArtists();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadArtists,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _artists.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No artists found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try different search terms or remove filters',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _artists.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final artist = _artists[index];
                        return ArtistCard(artist: artist);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class ArtistCard extends StatelessWidget {
  final ArtistProfile artist;

  const ArtistCard({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            RouteNames.artistProfile,
            arguments: {'artistId': artist.id},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist banner
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child:
                  artist.bannerImageUrl != null
                      ? Image.network(
                        artist.bannerImageUrl!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: double.infinity,
                              height: 100,
                              color: AppColors.primaryColor.withOpacity(0.2),
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                      )
                      : Container(
                        width: double.infinity,
                        height: 100,
                        color: AppColors.primaryColor.withOpacity(0.2),
                        child: const Center(child: Icon(Icons.image, size: 50)),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        artist.profileImageUrl != null
                            ? NetworkImage(artist.profileImageUrl!)
                            : null,
                    backgroundColor: AppColors.accentColor.withOpacity(0.2),
                    child:
                        artist.profileImageUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Artist Name',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (artist.website != null)
                          Text(
                            artist.website!,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          artist.bio,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        RouteNames.artistGallery,
                        arguments: {'artistId': artist.id},
                      );
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Gallery'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        RouteNames.artistCalendar,
                        arguments: {'artistId': artist.id},
                      );
                    },
                    icon: const Icon(Icons.event),
                    label: const Text('Events'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
