import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/artist_service.dart';
import '../services/event_service.dart' as event_service;
import '../services/auth_service.dart';
import '../routing/route_names.dart';
import '../core/themes/app_theme.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String artistId;

  const ArtistProfileScreen({super.key, required this.artistId});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isFavorite = false;
  ArtistProfile? _artistProfile;
  List<Event> _upcomingEvents = [];
  List<Artwork> _artwork = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadArtistProfile();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final artistService = Provider.of<ArtistService>(context, listen: false);
      final eventService = Provider.of<event_service.EventService>(
        context,
        listen: false,
      );

      final artistProfile = await artistService.getArtistProfileById(
        widget.artistId,
      );
      final events = await eventService.getArtistEvents(widget.artistId);
      final artwork = await artistService.getArtistArtwork(widget.artistId);

      // Filter upcoming events
      final now = DateTime.now();
      final upcomingEvents =
          events.where((event) => event.startDate.isAfter(now)).toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

      if (mounted) {
        setState(() {
          _artistProfile = artistProfile as ArtistProfile?;
          _upcomingEvents = upcomingEvents.cast<Event>();
          _artwork = artwork.cast<Artwork>();
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
            content: Text('Error loading artist profile: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isAuthenticated) {
        final isFavorite = await Provider.of<ArtistService>(
          context,
          listen: false,
        ).isArtistFavorite(widget.artistId);
        if (mounted) {
          setState(() {
            _isFavorite = isFavorite;
          });
        }
      }
    } catch (e) {
      // Ignore favorites check errors
    }
  }

  Future<void> _toggleFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to save favorites'),
          action: SnackBarAction(label: 'Login', onPressed: _navigateToLogin),
        ),
      );
      return;
    }

    try {
      final artistService = Provider.of<ArtistService>(context, listen: false);
      if (_isFavorite) {
        await artistService.removeFromFavorites(widget.artistId);
      } else {
        await artistService.addToFavorites(widget.artistId);
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _openWebsite(String url) async {
    try {
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening website: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _artistProfile == null
              ? const Center(child: Text('Artist not found'))
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(_artistProfile!.displayName),
                        background:
                            _artistProfile!.bannerImageUrl != null
                                ? Image.network(
                                  _artistProfile!.bannerImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.primaryColor.withAlpha(
                                                (0.7 * 255).toInt(),
                                              ),
                                              AppColors.primaryColor,
                                            ],
                                          ),
                                        ),
                                      ),
                                )
                                : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primaryColor.withAlpha(
                                          (0.7 * 255).toInt(),
                                        ),
                                        AppColors.primaryColor,
                                      ],
                                    ),
                                  ),
                                ),
                      ),
                      actions: [
                        IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.white,
                          ),
                          onPressed: _toggleFavorite,
                          tooltip:
                              _isFavorite
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            // Share functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sharing coming soon!'),
                              ),
                            );
                          },
                          tooltip: 'Share artist profile',
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundImage:
                                  _artistProfile!.profileImageUrl != null
                                      ? NetworkImage(
                                        _artistProfile!.profileImageUrl!,
                                      )
                                      : null,
                              backgroundColor: AppColors.accentColor.withAlpha(
                                (0.2 * 255).toInt(),
                              ),
                              child:
                                  _artistProfile!.profileImageUrl == null
                                      ? const Icon(Icons.person, size: 45)
                                      : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _artistProfile!.displayName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_artistProfile!.location != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _artistProfile!.location!,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  if (_artistProfile!.specializations != null &&
                                      _artistProfile!
                                          .specializations!
                                          .isNotEmpty)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          _artistProfile!.specializations!
                                              .map(
                                                (spec) => Chip(
                                                  backgroundColor: AppColors
                                                      .primaryColor
                                                      .withAlpha(
                                                        (0.1 * 255).toInt(),
                                                      ),
                                                  label: Text(spec),
                                                  padding: EdgeInsets.zero,
                                                  labelStyle: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_artistProfile!.bio.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            _artistProfile!.bio,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.accentColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppColors.accentColor,
                          tabs: const [
                            Tab(text: 'Gallery'),
                            Tab(text: 'Events'),
                            Tab(text: 'Contact'),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Gallery tab
                    _buildGalleryTab(),

                    // Events tab
                    _buildEventsTab(),

                    // Contact tab
                    _buildContactTab(),
                  ],
                ),
              ),
    );
  }

  Widget _buildGalleryTab() {
    if (_artwork.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No artwork available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _artwork.length,
      itemBuilder: (context, index) {
        final artwork = _artwork[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: InkWell(
            onTap: () {
              // Navigate to artwork details
              Navigator.of(context).pushNamed(
                RouteNames.artDetails,
                arguments: {'artId': artwork.id},
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    artwork.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.withOpacity(0.2),
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (artwork.medium != null)
                        Text(
                          artwork.medium!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (artwork.price != null)
                        Text(
                          '\$${artwork.price!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
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
  }

  Widget _buildEventsTab() {
    if (_upcomingEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No upcoming events',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingEvents.length,
      itemBuilder: (context, index) {
        final event = _upcomingEvents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                RouteNames.eventDetails,
                arguments: {'eventId': event.id},
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event banner
                if (event.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      event.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            height: 80,
                            width: double.infinity,
                            color: AppColors.primaryColor.withAlpha(
                              (0.2 * 255).toInt(),
                            ),
                            child: const Center(
                              child: Icon(Icons.image, size: 40),
                            ),
                          ),
                    ),
                  ),

                // Event details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date box
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('MMM').format(event.startDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              DateFormat('dd').format(event.startDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Event info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('h:mm a').format(event.startDate)} - ${DateFormat('h:mm a').format(event.endDate)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            if (event.location != null) ...[
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
                                      event.location!,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (event.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                event.description!,
                                style: TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Share event
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sharing coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            RouteNames.eventDetails,
                            arguments: {'eventId': event.id},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                        ),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Details'),
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
  }

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (_artistProfile!.website != null)
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Website'),
                    subtitle: Text(_artistProfile!.website!),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _openWebsite(_artistProfile!.website!),
                  ),

                if (_artistProfile!.email != null)
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(_artistProfile!.email!),
                    contentPadding: EdgeInsets.zero,
                    onTap:
                        () => _openWebsite('mailto:${_artistProfile!.email}'),
                  ),

                if (_artistProfile!.phone != null)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone'),
                    subtitle: Text(_artistProfile!.phone!),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _openWebsite('tel:${_artistProfile!.phone}'),
                  ),
              ],
            ),
          ),
        ),

        if (_artistProfile!.socialLinks != null &&
            _artistProfile!.socialLinks!.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Social Media',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._artistProfile!.socialLinks!.entries.map((entry) {
                    IconData icon;
                    switch (entry.key.toLowerCase()) {
                      case 'instagram':
                        icon = Icons.camera_alt;
                        break;
                      case 'facebook':
                        icon = Icons.facebook;
                        break;
                      case 'twitter':
                      case 'x':
                        icon = Icons.whatshot;
                        break;
                      case 'youtube':
                        icon = Icons.play_circle_filled;
                        break;
                      case 'tiktok':
                        icon = Icons.music_note;
                        break;
                      default:
                        icon = Icons.link;
                    }

                    return ListTile(
                      leading: Icon(icon),
                      title: Text(entry.key),
                      subtitle: Text(entry.value),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _openWebsite(entry.value),
                    );
                  }),
                ],
              ),
            ),
          ),

        ElevatedButton.icon(
          onPressed: () {
            // Message the artist
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Messaging coming soon!')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentColor,
            minimumSize: const Size(double.infinity, 50),
          ),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Message Artist'),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class ArtistProfile {
  final String id;
  final String userId;
  final String displayName;
  final String bio;
  final String? location;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final List<String>? specializations;
  final String? website;
  final String? email;
  final String? phone;
  final Map<String, String>? socialLinks;

  ArtistProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.bio,
    this.location,
    this.profileImageUrl,
    this.bannerImageUrl,
    this.specializations,
    this.website,
    this.email,
    this.phone,
    this.socialLinks,
  });
}

class Event {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? location;
  final String? imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.description,
    this.location,
    this.imageUrl,
  });
}

class Artwork {
  final String id;
  final String title;
  final String imageUrl;
  final String? description;
  final double? price;
  final String? medium;
  final List<String>? tags;

  Artwork({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
    this.price,
    this.medium,
    this.tags,
  });
}
