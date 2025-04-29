import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import '../routing/route_names.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Discover Events",
          body: "Find local art events and connect with artists in your area.",
          image: Center(
            child: Image.asset('assets/images/art/discover_events.png', height: 175.0),
          ),
        ),
        PageViewModel(
          title: "Save Your Favorites",
          body: "Keep track of events and artists you love.",
          image: Center(
            child: Image.asset('assets/images/art/save_favorites.png', height: 175.0),
          ),
        ),
        PageViewModel(
          title: "Engage with the Community",
          body: "Like, comment, and share posts in the community feed.",
          image: Center(
            child: Image.asset('assets/images/art/community_engagement.png', height: 175.0),
          ),
        ),
      ],
      onDone: () {
        Navigator.of(context).pushReplacementNamed(RouteNames.home);
      },
      onSkip: () {
        Navigator.of(context).pushReplacementNamed(RouteNames.home);
      },
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}