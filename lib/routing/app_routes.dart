import 'package:flutter/material.dart';
import './route_names.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/art_map_screen.dart';
import '../screens/events_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/events/event_details_screen.dart';
import '../screens/art/art_details_screen.dart';
import '../screens/events/create_event_screen.dart';
import '../screens/tours/create_tour_screen.dart';
import '../screens/artist/artist_profile_screen.dart';
import '../screens/art/management/gallery_management_screen.dart';
import '../screens/artist/subscription/subscription_dashboard_screen.dart';
import '../features/favorites/favorites_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    // Auth routes
    RouteNames.splash: (context) => const SplashScreen(),
    RouteNames.login: (context) => const LoginScreen(),
    RouteNames.register: (context) => const RegisterScreen(),
    RouteNames.forgotPassword: (context) => const ForgotPasswordScreen(),

    // Main routes
    RouteNames.home: (context) => const HomeScreen(),

    // These routes can also be accessed via bottom navigation
    // but we include them here for deep linking
    RouteNames.explore: (context) => const ExploreScreen(),
    RouteNames.artMap: (context) => const ArtMapScreen(),
    RouteNames.events: (context) => const EventsScreen(),
    RouteNames.profile: (context) => const ProfileScreen(),

    // User management routes
    RouteNames.favorites: (context) => const FavoritesScreen(),
  };

  // For routes that need arguments or dynamic content
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.artistProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        final artistId = args?['artistId'] as String?;
        if (artistId == null) return null;

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ArtistProfileScreen(artistId: artistId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );

      case RouteNames.eventDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId == null) return null;

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              EventDetailsScreen(eventId: eventId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );

      case RouteNames.createWalkingTour:
        final args = settings.arguments as Map<String, dynamic>?;
        final artLocationIds = args?['artLocationIds'] as List<String>?;
        if (artLocationIds == null) return null;

        return MaterialPageRoute(
          builder: (context) => CreateWalkingTourScreen(artLocationIds: artLocationIds),
        );

      case RouteNames.artistGallery:
        final args = settings.arguments as Map<String, dynamic>?;
        final artistId = args?['artistId'] as String?;
        if (artistId == null) return null;

        return MaterialPageRoute(
          builder: (context) => GalleryManagementScreen(),
        );

      default:
        return null;
    }
  }

  static Route<dynamic> unknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder:
          (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Page "${settings.name}" not found',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(RouteNames.home);
                    },
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
