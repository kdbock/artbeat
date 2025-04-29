import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stripe_payment/stripe_payment.dart';
import '../../../services/auth_service.dart';
import '../../../services/artist_service.dart';
import '../../../core/themes/app_theme.dart';

class SubscriptionDashboardScreen extends StatefulWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  State<SubscriptionDashboardScreen> createState() =>
      _SubscriptionDashboardScreenState();
}

class _SubscriptionDashboardScreenState
    extends State<SubscriptionDashboardScreen> {
  bool _isLoading = true;
  ArtistProfile? _artistProfile;
  ArtistAnalytics? _analytics;
  String? _errorMessage;
  String _selectedTimePeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final artistService = Provider.of<ArtistService>(context, listen: false);

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

      final analytics = await artistService.getArtistAnalytics(
        artistProfile.id,
        timePeriod: _selectedTimePeriod,
      );

      if (mounted) {
        setState(() {
          _artistProfile = artistProfile;
          _analytics = analytics;
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

  Future<void> _processSubscriptionPayment(String plan) async {
    try {
      final paymentMethod = await StripePayment.paymentRequestWithCardForm(
        CardFormPaymentRequest(),
      );

      // Log the payment method ID (for backend use)
      print('Payment method created: ${paymentMethod.id}');

      // Here, you would typically send the paymentMethod.id to your backend
      // to create a PaymentIntent and confirm the payment.

      // Simulate successful payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Update subscription status locally
      final artistService = Provider.of<ArtistService>(context, listen: false);
      final success = await artistService.updateSubscriptionStatus(
        _artistProfile!.id,
        plan,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription updated successfully')),
        );
        _loadDashboardData();
      } else {
        throw Exception('Failed to update subscription status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _showUpgradeSubscriptionDialog() async {
    if (_artistProfile == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSubscriptionPlan(
              'Basic',
              'Free',
              [
                'Up to 20 artwork listings',
                'Basic analytics',
                'Community features',
              ],
              isSelected: _artistProfile!.subscriptionStatus == 'basic',
            ),
            const SizedBox(height: 16),
            _buildSubscriptionPlan(
              'Pro',
              '
$9.99/month',
              [
                'Unlimited artwork listings',
                'Featured in discover section',
                'Advanced analytics',
                'Priority support',
                'No commission fees',
              ],
              isSelected: _artistProfile!.subscriptionStatus == 'pro',
            ),
            const SizedBox(height: 16),
            _buildSubscriptionPlan(
              'Business',
              '
$24.99/month',
              [
                'Everything in Pro plan',
                'Gallery management tools',
                'Email marketing integration',
                'Custom branding',
                'Dedicated support',
              ],
              isSelected: _artistProfile!.subscriptionStatus == 'business',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop('pro'); // Example: Select Pro plan
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await _processSubscriptionPayment(result);
    }
  }

  Widget _buildSubscriptionPlan(
    String title,
    String price,
    List<String> features, {
    bool isSelected = false,
  }) {
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isSelected
                ? BorderSide(color: AppColors.accentColor, width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap:
            isSelected
                ? null
                : () => Navigator.of(context).pop(title.toLowerCase()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.accentColor : Colors.black,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Current Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                price,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const Divider(height: 24),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(feature),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                onPressed: _loadDashboardData,
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription info card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Plan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _artistProfile!.subscriptionStatus.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getSubscriptionPriceText(),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _showUpgradeSubscriptionDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Upgrade'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text('Account Status: ${_getAccountStatusText()}'),
                    const SizedBox(height: 8),
                    if (_artistProfile?.subscriptionEndDate != null) ...[
                      Text(
                        'Renewal Date: ${DateFormat('MMM dd, yyyy').format(_artistProfile!.subscriptionEndDate!)}',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Time period selection
            const Text(
              'Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'week',
                  label: Text('Week'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment(
                  value: 'month',
                  label: Text('Month'),
                  icon: Icon(Icons.calendar_view_month),
                ),
                ButtonSegment(
                  value: 'year',
                  label: Text('Year'),
                  icon: Icon(Icons.calendar_today),
                ),
              ],
              selected: {_selectedTimePeriod},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedTimePeriod = selection.first;
                });
                _loadDashboardData();
              },
            ),
            const SizedBox(height: 16),

            // Analytics cards
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    title: 'Profile Views',
                    value: _analytics?.profileViews ?? 0,
                    icon: Icons.visibility,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsCard(
                    title: 'Artwork Views',
                    value: _analytics?.artworkViews ?? 0,
                    icon: Icons.image,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    title: 'Favorites',
                    value: _analytics?.totalFavorites ?? 0,
                    icon: Icons.favorite,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsCard(
                    title: 'Inquiries',
                    value: _analytics?.inquiries ?? 0,
                    icon: Icons.mail,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            // Engagement chart
            if (_analytics != null && _analytics!.dailyViewData.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Engagement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(height: 200, child: LineChart(_getChartData())),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChartLegendItem('Profile Views', Colors.blue),
                          const SizedBox(width: 24),
                          _buildChartLegendItem('Artwork Views', Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            // Top artworks
            if (_analytics != null && _analytics!.topArtworks.isNotEmpty) ...[
              const Text(
                'Top Performing Artworks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _analytics!.topArtworks.length,
                itemBuilder: (context, index) {
                  final artwork = _analytics!.topArtworks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          artwork.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        artwork.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${artwork.views} views • ${artwork.favorites} favorites',
                      ),
                      trailing: CircleAvatar(
                        backgroundColor: AppColors.accentColor,
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 32),
            // Recommendations section
            const Text(
              'Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      _getRecommendations().map((recommendation) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                recommendation.icon,
                                color: recommendation.iconColor,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recommendation.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(recommendation.description),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    final previousValue = value * 0.8; // Simulating previous period data
    final percentChange =
        ((value - previousValue) / previousValue * 100).round();
    final isPositive = percentChange >= 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  radius: 20,
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}$percentChange%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'vs. previous period',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  LineChartData _getChartData() {
    if (_analytics == null) {
      // Return empty chart
      return LineChartData();
    }

    final viewData = _analytics!.dailyViewData;

    // Create spots for profile views line
    final profileViewSpots = List.generate(
      viewData.length,
      (index) =>
          FlSpot(index.toDouble(), viewData[index].profileViews.toDouble()),
    );

    // Create spots for artwork views line
    final artworkViewSpots = List.generate(
      viewData.length,
      (index) =>
          FlSpot(index.toDouble(), viewData[index].artworkViews.toDouble()),
    );

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: 20,
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value >= viewData.length) {
                return const Text('');
              }
              // Show every other day or adapt based on time period
              if (value.toInt() % 4 != 0) {
                return const Text('');
              }
              final date = viewData[value.toInt()].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              );
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              );
            },
            reservedSize: 30,
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      minX: 0,
      maxX: viewData.length - 1.toDouble(),
      minY: 0,
      lineBarsData: [
        LineChartBarData(
          spots: profileViewSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
        LineChartBarData(
          spots: artworkViewSpots,
          isCurved: true,
          color: Colors.purple,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.purple.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  String _getSubscriptionPriceText() {
    switch (_artistProfile!.subscriptionStatus.toLowerCase()) {
      case 'basic':
        return 'Free';
      case 'pro':
        return '\$9.99/month';
      case 'business':
        return '\$24.99/month';
      default:
        return '';
    }
  }

  String _getAccountStatusText() {
    if (_artistProfile?.subscriptionStatus.toLowerCase() == 'basic') {
      return 'Active';
    }

    if (_artistProfile?.subscriptionEndDate != null) {
      if (_artistProfile!.subscriptionEndDate!.isAfter(DateTime.now())) {
        return 'Active';
      } else {
        return 'Expired';
      }
    }

    return 'Unknown';
  }

  List<_Recommendation> _getRecommendations() {
    final recommendations = <_Recommendation>[];

    // Based on subscription status
    if (_artistProfile?.subscriptionStatus.toLowerCase() == 'basic') {
      recommendations.add(
        const _Recommendation(
          title: 'Upgrade to Pro',
          description:
              'Get more visibility by upgrading to Pro and being featured in the discover section.',
          icon: Icons.star,
          iconColor: Colors.amber,
        ),
      );
    }

    // Based on analytics
    if (_analytics != null) {
      // If low artwork count
      if (_analytics!.totalArtworks < 5) {
        recommendations.add(
          const _Recommendation(
            title: 'Add More Artwork',
            description: 'Artists with 10+ artworks get 3x more profile views.',
            icon: Icons.add_photo_alternate,
            iconColor: Colors.green,
          ),
        );
      }

      // If low profile completeness
      if (_analytics!.profileCompleteness < 80) {
        recommendations.add(
          const _Recommendation(
            title: 'Complete Your Profile',
            description:
                'Add a bio, profile image, and specializations to improve visibility.',
            icon: Icons.person,
            iconColor: Colors.blue,
          ),
        );
      }

      // If no events
      if (_analytics!.totalEvents == 0) {
        recommendations.add(
          const _Recommendation(
            title: 'Create an Event',
            description:
                'Hosting events can increase profile views by up to 50%.',
            icon: Icons.event,
            iconColor: Colors.purple,
          ),
        );
      }
    }

    // Add default recommendation if none generated
    if (recommendations.isEmpty) {
      recommendations.add(
        const _Recommendation(
          title: 'Share Your Profile',
          description:
              'Share your ArtBeat profile on social media to increase visibility.',
          icon: Icons.share,
          iconColor: Colors.cyan,
        ),
      );
    }

    return recommendations;
  }
}

class _Recommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const _Recommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

class ArtistAnalytics {
  final int profileViews;
  final int artworkViews;
  final int totalFavorites;
  final int inquiries;
  final int totalArtworks;
  final int totalEvents;
  final int profileCompleteness;
  final List<DailyViewData> dailyViewData;
  final List<TopArtwork> topArtworks;

  ArtistAnalytics({
    required this.profileViews,
    required this.artworkViews,
    required this.totalFavorites,
    required this.inquiries,
    required this.totalArtworks,
    required this.totalEvents,
    required this.profileCompleteness,
    required this.dailyViewData,
    required this.topArtworks,
  });
}

class DailyViewData {
  final DateTime date;
  final int profileViews;
  final int artworkViews;

  DailyViewData({
    required this.date,
    required this.profileViews,
    required this.artworkViews,
  });
}

class TopArtwork {
  final String id;
  final String title;
  final String imageUrl;
  final int views;
  final int favorites;

  TopArtwork({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.views,
    required this.favorites,
  });
}
