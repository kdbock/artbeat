import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../routing/route_names.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _profile;
  var _events = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final eventService = Provider.of<EventService>(context, listen: false);
    final profile = await authService.getArtistProfile();
    final events = await eventService.getArtistEvents(
      profile?.id ?? '',
      includePast: true,
    );
    setState(() {
      _profile = profile;
      _events = events;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body:
          _profile == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              _profile.imageUrl != null
                                  ? NetworkImage(_profile.imageUrl!)
                                  : null,
                          child:
                              _profile.imageUrl == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(_profile.email),
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
                    if (_events.isEmpty)
                      const Text('You have not created any events yet.'),
                    ..._events.map(
                      (event) => ListTile(
                        title: Text(event.title),
                        subtitle: Text('${event.startDate} - ${event.endDate}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              RouteNames.editProfile,
                              arguments: {'eventId': event.id},
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
