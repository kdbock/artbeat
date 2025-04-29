import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'routing/app_routes.dart';
import 'routing/route_names.dart';
import 'services/auth_service.dart';
import 'services/artist_service.dart';
import 'services/event_service.dart';
import 'services/location_service.dart';

class ArtBeatApp extends StatelessWidget {
  const ArtBeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ProxyProvider<AuthService, ArtistService>(
          update: (_, authService, __) => ArtistService(),
        ),
        ProxyProvider<AuthService, EventService>(
          update: (_, authService, __) => EventService(),
        ),
        Provider<LocationService>(create: (_) => LocationService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'ArtBeat',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system, // Use system theme by default
            initialRoute: RouteNames.splash,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            onUnknownRoute: AppRoutes.unknownRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
