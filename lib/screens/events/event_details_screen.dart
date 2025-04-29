import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../core/themes/app_theme.dart';
import '../../routing/route_names.dart';
import '../../widgets/favorite_button.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final eventService = Provider.of<EventService>(context);
    final AuthService authService = Provider.of<AuthService>(context);

    Event event;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEvent(context, event),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date and Time Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Calendar Icon with Date
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MMM').format(event.startDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd').format(event.startDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy').format(event.startDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Time Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'When',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, y',
                          ).format(event.startDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('h:mm a').format(event.startDate)} - ${event.endDate != null ? DateFormat('h:mm a').format(event.endDate!) : 'End time not specified'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Location Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Map preview if coordinates available
                  if (event.latitude != null && event.longitude != null)
                    SizedBox(
                      height: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              event.latitude!,
                              event.longitude!,
                            ),
                            zoom: 14.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('event_location'),
                              position: LatLng(event.latitude!, event.longitude!),
                              infoWindow: InfoWindow(
                                title: event.title,
                                snippet: event.location,
                              ),
                            ),
                          },
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          onMapCreated: (
                            GoogleMapController controller,
                          ) {
                            // Save controller if needed for later
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMap(context, event),
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About this event',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Artist Info Section
          if (event.artistId != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organized by',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _viewArtistProfile(context, event),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: event.artistImageUrl != null
                                  ? NetworkImage(
                                      event.artistImageUrl!,
                                    )
                                  : null,
                              child: event.artistImageUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.artistName ?? 'Artist Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'View profile',
                                  style: TextStyle(
                                    color: AppColors.accentColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Share Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareEvent(context, event),
              icon: const Icon(Icons.share),
              label: const Text('Share Event'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // RSVP Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _rsvpToEvent(context, event),
              icon: const Icon(Icons.check_circle),
              label: const Text('RSVP'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Add to Calendar button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calendar integration coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Add to Calendar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _shareEvent(BuildContext context, Event event) {
    final String eventDetails =
        'Check out this event: ${event.title} on ${DateFormat('MMM d, y').format(event.startDate)} at ${event.location}';
    Share.share(eventDetails);
  }

  void _rsvpToEvent(BuildContext context, Event event) {
    // Logic to RSVP to the event (e.g., update database or state)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You have RSVP’d to ${event.title}')),
    );
  }

  Future<void> _openMap(BuildContext context, Event event) async {
    if (event.latitude == null || event.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location coordinates not available')),
      );
      return;
    }

    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${event.latitude},${event.longitude}',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application')),
        );
      }
    }
  }

  void _viewArtistProfile(BuildContext context, Event event) {
    if (event.artistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artist information not available')),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      RouteNames.artistProfile,
      arguments: {'artistId': event.artistId},
    );
  }
}
