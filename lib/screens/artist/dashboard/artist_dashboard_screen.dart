import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/artist_service.dart' as artist_service;
import '../../../routing/route_names.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  bool _isLoading = true;
  ArtistProfile? _artistProfile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
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
          _errorMessage = 'You need an artist account to access this dashboard';
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

      if (mounted) {
        setState(() {
          _artistProfile = artistProfile as ArtistProfile?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Artist Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Artist Dashboard')),
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
        title: const Text('Artist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(
                RouteNames.artistProfile,
                arguments: {'artistId': _artistProfile!.id},
              );
            },
            tooltip: 'View Public Profile',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(RouteNames.settings);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadArtistProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist info card
              _buildArtistInfoCard(),
              const SizedBox(height: 24),

              // Quick metrics
              _buildQuickMetricsSection(),
              const SizedBox(height: 24),

              // Feature cards
              const Text(
                'Manage Your Art',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFeatureCardsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _artistProfile?.profileImageUrl != null
                          ? NetworkImage(_artistProfile!.profileImageUrl!)
                          : null,
                  child:
                      _artistProfile?.profileImageUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Consumer<AuthService>(
                        builder:
                            (context, authService, _) => Text(
                              authService.currentUser?.email ?? 'Artist',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSubscriptionColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _artistProfile!.subscriptionStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_artistProfile!.bio?.isNotEmpty == true) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _artistProfile!.bio!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetricsSection() {
    return Consumer<artist_service.ArtistService>(
      builder: (context, artistService, _) {
        return FutureBuilder<ArtistAnalytics>(
          future: artistService.getArtistAnalytics(_artistProfile!.id),
          builder: (context, snapshot) {
            final data = snapshot.data;

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  'Profile Views',
                  data?.profileViews.toInt() ?? 0,
                  Icons.visibility,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Artwork Views',
                  data?.artworkViews.toInt() ?? 0,
                  Icons.image,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Artworks',
                  data?.totalArtworks.toInt() ?? 0,
                  Icons.palette,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Events',
                  data?.totalEvents.toInt() ?? 0,
                  Icons.event,
                  Colors.green,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCardsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildFeatureCard(
          'Gallery Management',
          'Manage your artwork portfolio',
          Icons.collections,
          Colors.deepPurple,
          () {
            Navigator.of(context).pushNamed(RouteNames.galleryManagement);
          },
        ),
        _buildFeatureCard(
          'Create Event',
          'Host exhibitions, workshops or meet-ups',
          Icons.event_available,
          Colors.green,
          () {
            Navigator.of(context).pushNamed(RouteNames.createEvent);
          },
        ),
        _buildFeatureCard(
          'Analytics',
          'Track your engagement and performance',
          Icons.assessment,
          Colors.amber,
          () {
            Navigator.of(
              context,
            ).pushNamed(RouteNames.artistSubscriptionDashboard);
          },
        ),
        _buildFeatureCard(
          'Subscription',
          'Manage your subscription and benefits',
          Icons.workspace_premium,
          Colors.teal,
          () {
            Navigator.of(
              context,
            ).pushNamed(RouteNames.artistSubscriptionDashboard);
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: Color.fromRGBO(
                  color.r.toInt(),
                  color.g.toInt(),
                  color.b.toInt(),
                  0.2,
                ),
                radius: 28,
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubscriptionColor() {
    switch (_artistProfile!.subscriptionStatus.toLowerCase()) {
      case 'pro':
        return Colors.blue;
      case 'business':
        return Colors.purple;
      case 'basic':
      default:
        return Colors.grey;
    }
  }
}

class ArtistProfile {
  final String? profileImageUrl;
  final String subscriptionStatus;
  final String? bio;
  final String id;

  ArtistProfile({
    required this.id,
    this.profileImageUrl,
    required this.subscriptionStatus,
    this.bio,
  });
}

class ArtistAnalytics {
  final int profileViews;
  final int artworkViews;
  final int totalArtworks;
  final int totalEvents;

  ArtistAnalytics({
    required this.profileViews,
    required this.artworkViews,
    required this.totalArtworks,
    required this.totalEvents,
  });
}
