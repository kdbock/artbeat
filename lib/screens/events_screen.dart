import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import '../routing/route_names.dart';
import '../core/themes/app_theme.dart';
import '../widgets/favorite_button.dart';
import '../services/event_service.dart';

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Event> _upcomingEvents = [];
  List<Event> _pastEvents = [];
  List<Event> _recommendedEvents = [];
  int? _zipCode;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  List<String> _categories = ['All', 'Art', 'Music', 'Workshops', 'Exhibitions'];
  String? _selectedSortOption;
  final List<String> _sortOptions = ['Popularity', 'Date', 'Proximity'];

  Future<void> _loadRecommendations() async {
    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUserId;

      if (userId != null) {
        final recommendations = await eventService.getUserFavoriteEvents(userId);
        setState(() {
          _recommendedEvents = recommendations.take(5).toList(); // Limit to 5 recommendations
        });
      }
    } catch (e) {
      // Handle errors gracefully
      setState(() {
        _recommendedEvents = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      final events = await eventService.getEvents(
        zipCode: _zipCode,
        searchQuery:
            _searchController.text.isEmpty ? null : _searchController.text,
        startDate: _selectedDate,
      );

      final now = DateTime.now();

      if (mounted) {
        setState(() {
          _upcomingEvents =
              events.where((event) => event.startDate.isAfter(now)).toList()
                ..sort((a, b) => a.startDate.compareTo(b.startDate));

          _pastEvents =
              events.where((event) => event.startDate.isBefore(now)).toList()
                ..sort(
                  (a, b) => b.startDate.compareTo(a.startDate),
                ); // Sort past events by most recent

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
            content: Text(
              'Failed to load events. Please check your connection and try again.',
            ),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadEvents,
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadEvents();
    }
  }

  void _clearFilters() {
    setState(() {
      _zipCode = null;
      _selectedDate = null;
      _searchController.clear();
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Events'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentColor,
          labelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
          unselectedLabelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.white70,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: Column(
        children: [
          // Recommendations section
          if (_recommendedEvents.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended for You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recommendedEvents.length,
                      itemBuilder: (context, index) {
                        final event = _recommendedEvents[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 16),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event image
                                if (event.imageUrl != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      event.imageUrl!,
                                      height: 100,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Search, filter, and category section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: () => _showFilterDialog(),
                          ),
                        ),
                        onSubmitted: (_) => _loadEvents(),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedSortOption,
                      hint: const Text('Sort by'),
                      items: _sortOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSortOption = value;
                        });
                        _loadEvents();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                          _loadEvents();
                        },
                        decoration: InputDecoration(
                          hintText: 'Select Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Date'
                            : DateFormat('MM/dd').format(_selectedDate!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendar view
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            eventLoader: (day) {
              return _upcomingEvents
                  .where((event) => isSameDay(event.startDate, day))
                  .toList();
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
              _loadEvents();
            },
          ),

          // Events list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming events tab
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _upcomingEvents.isEmpty
                    ? _buildEmptyState('No upcoming events found')
                    : _buildEventsList(_upcomingEvents),

                // Past events tab
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _pastEvents.isEmpty
                    ? _buildEmptyState('No past events found')
                    : _buildEventsList(_pastEvents),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          authService.isArtist
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(RouteNames.createEvent);
                },
                backgroundColor: AppColors.accentColor,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filters'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add filter options here (e.g., date range, artist, event type)
              TextField(
                decoration: const InputDecoration(labelText: 'Event Type'),
                onChanged: (value) {
                  // Handle filter input
                },
              ),
              // Additional filters can be added here
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadEvents();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different search terms or remove filters',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                RouteNames.eventDetails,
                arguments: {'eventId': event.id},
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event banner with favorite button overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          event.imageUrl != null
                              ? Image.network(
                                event.imageUrl!,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      width: double.infinity,
                                      height: 100,
                                      color: AppColors.primaryColor.withOpacity(
                                        0.2,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                              )
                              : Container(
                                width: double.infinity,
                                height: 100,
                                color: AppColors.primaryColor.withOpacity(0.2),
                                child: const Center(
                                  child: Icon(Icons.event, size: 50),
                                ),
                              ),
                    ),
                    // Favorite button positioned at top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: FavoriteButton(
                          eventId: event.id,
                          size: 22,
                          inactiveColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Event details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                  ),
                                ),
                                Text(
                                  DateFormat('dd').format(event.startDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('h:mm a').format(event.startDate)} - ${DateFormat('h:mm a').format(event.endDate)}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 4),
                                if (event.location != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          event.location!,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (event.description != null)
                        Text(
                          event.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),

                      // Artist info
                      if (event.artistId != null && event.artistName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage:
                                    event.artistImageUrl != null
                                        ? NetworkImage(event.artistImageUrl!)
                                        : null,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                child:
                                    event.artistImageUrl == null
                                        ? const Icon(Icons.person, size: 14)
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'By ${event.artistName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Share functionality here
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
}

class Event {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? location;
  final String? imageUrl;
  final String? artistId;
  final String? artistName;
  final String? artistImageUrl;

  Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.description,
    this.location,
    this.imageUrl,
    this.artistId,
    this.artistName,
    this.artistImageUrl,
  });
}
