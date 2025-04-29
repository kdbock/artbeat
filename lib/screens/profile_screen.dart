import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/artist_service.dart';
import '../routing/route_names.dart';
import '../core/themes/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  UserProfile? _userProfile;
  ArtistProfile? _artistProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final artistService = Provider.of<ArtistService>(context, listen: false);

      final userProfile = await authService.getUserProfile();

      ArtistProfile? artistProfile;
      if (authService.isArtist) {
        artistProfile = await artistService.getArtistProfile();
      }

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _artistProfile = artistProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(RouteNames.login);
    }
  }

  void _upgradeToArtist() {
    Navigator.of(
      context,
    ).pushNamed(RouteNames.editProfile, arguments: {'upgradeToArtist': true});
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(RouteNames.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(RouteNames.settings);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userProfile == null
              ? const Center(child: Text('Unable to load profile'))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final isArtist = Provider.of<AuthService>(context).isArtist;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage:
                        _userProfile!.profileImageUrl != null
                            ? NetworkImage(_userProfile!.profileImageUrl!)
                            : null,
                    backgroundColor: AppColors.accentColor.withOpacity(0.2),
                    child:
                        _userProfile!.profileImageUrl == null
                            ? const Icon(Icons.person, size: 45)
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userProfile!.displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userProfile!.email,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _userProfile!.location ?? 'No location set',
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (isArtist && _artistProfile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Chip(
                              backgroundColor: AppColors.accentColor,
                              label: const Text(
                                'Artist Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              avatar: const Icon(
                                Icons.palette,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          RouteNames.editProfile,
                          arguments: {'userId': _userProfile!.id},
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        isArtist
                            ? ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  RouteNames.artistCalendar,
                                  arguments: {'artistId': _artistProfile!.id},
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                              ),
                              icon: const Icon(Icons.event, size: 18),
                              label: const Text('My Calendar'),
                            )
                            : ElevatedButton.icon(
                              onPressed: _upgradeToArtist,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                              ),
                              icon: const Icon(Icons.upgrade, size: 18),
                              label: const Text('Become Artist'),
                            ),
                  ),
                ],
              ),
            ),

            // Artist-specific content
            if (isArtist && _artistProfile != null)
              _buildArtistContent()
            else
              _buildUserContent(),

            // Logout button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistContent() {
    final artistProfile = _artistProfile!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Artist tabs
        TabBar(
          controller: _tabController,
          labelColor: AppColors.accentColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.accentColor,
          tabs: const [
            Tab(text: 'Gallery'),
            Tab(text: 'Events'),
            Tab(text: 'About'),
          ],
        ),

        // Tab content
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Gallery tab
              _buildGalleryTab(artistProfile),

              // Events tab
              _buildEventsTab(artistProfile),

              // About tab
              _buildAboutTab(artistProfile),
            ],
          ),
        ),

        // Subscription info
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Artist Subscription',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Subscription active until ${artistProfile.subscriptionEndDate ?? 'N/A'}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to subscription management
                },
                icon: const Icon(Icons.payment),
                label: const Text('Manage Subscription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  minimumSize: const Size(double.infinity, 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Favorites section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'My Favorites',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(RouteNames.favorites);
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),

        // Favorites content or placeholder
        InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(RouteNames.favorites);
          },
          child: Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteNames.events);
                    },
                    child: const Text('Find Events'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Recent activity section
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Recent activity content or placeholder
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No recent activity',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTab(ArtistProfile artistProfile) {
    // Placeholder for gallery
    return artistProfile.gallery == null || artistProfile.gallery!.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No artwork added yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to add artwork screen
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Artwork'),
              ),
            ],
          ),
        )
        : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: artistProfile.gallery!.length,
          itemBuilder: (context, index) {
            final artwork = artistProfile.gallery![index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () {
                  // Show artwork details
                },
                child: Image.network(
                  artwork.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.withOpacity(0.2),
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                ),
              ),
            );
          },
        );
  }

  Widget _buildEventsTab(ArtistProfile artistProfile) {
    // Placeholder for events
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No upcoming events',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(RouteNames.createEvent);
            },
            icon: const Icon(Icons.add_circle),
            label: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(ArtistProfile artistProfile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(artistProfile.bio, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),

          if (artistProfile.specializations != null &&
              artistProfile.specializations!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Specializations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      artistProfile.specializations!
                          .map(
                            (spec) => Chip(
                              backgroundColor: AppColors.primaryColor
                                  .withOpacity(0.1),
                              label: Text(spec),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),

          if (artistProfile.website != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Links',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text('Website'),
                  subtitle: Text(artistProfile.website!),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    // Open website
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final String? location;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    this.location,
  });
}

class ArtistProfile {
  final String id;
  final String userId;
  final String bio;
  final List<String>? specializations;
  final String? website;
  final String? bannerImageUrl;
  final String? subscriptionEndDate;
  final List<Artwork>? gallery;

  ArtistProfile({
    required this.id,
    required this.userId,
    required this.bio,
    this.specializations,
    this.website,
    this.bannerImageUrl,
    this.subscriptionEndDate,
    this.gallery,
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
