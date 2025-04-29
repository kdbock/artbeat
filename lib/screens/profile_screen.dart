import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../routing/route_names.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final eventService = Provider.of<EventService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(RouteNames.editProfile);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          authService.getUserProfile(),
          eventService.getUserCreatedEvents(authService.currentUserId!),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile'));
          }

          final userProfile = snapshot.data![0];
          final userEvents = snapshot.data![1];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: userProfile.imageUrl != null
                          ? NetworkImage(userProfile.imageUrl!)
                          : null,
                      child: userProfile.imageUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(userProfile.email),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // My Events Section
                const Text(
                  'My Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (userEvents.isEmpty)
                  const Text('You have not created any events yet.'),
                ...userEvents.map((event) => ListTile(
                      title: Text(event.title),
                      subtitle: Text(
                        '${event.startDate} - ${event.endDate}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            RouteNames.editEvent,
                            arguments: {'eventId': event.id},
                          );
                        },
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
