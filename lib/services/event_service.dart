import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../core/utils/logger.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final double? latitude;
  final double? longitude;
  final String artistId;
  final String? imageUrl;
  final bool isPublic;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    this.latitude,
    this.longitude,
    required this.artistId,
    this.imageUrl,
    required this.isPublic,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      artistId: json['artist_id'],
      imageUrl: json['image_url'],
      isPublic: json['is_public'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Event>> getUpcomingEvents({
    DateTime? fromDate,
    int? zipCode,
    int limit = 20,
  }) async {
    try {
      final now = fromDate ?? DateTime.now();

      var queryBuilder = _supabase
          .from('events')
          .select('*, artist_profiles(*)')
          .eq('is_public', true)
          .gte('start_date', now.toIso8601String())
          .order('start_date')
          .limit(limit);

      if (zipCode != null) {
        queryBuilder = queryBuilder.eq('zip_code', zipCode);
      }

      final response = await queryBuilder.execute();

      if (response.data != null) {
        Logger.logInfo('Upcoming events fetched successfully');
        return (response.data as List)
            .map((item) => Event.fromJson(item))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      Logger.logError('Error fetching upcoming events', e, stackTrace);
      return [];
    }
  }

  Future<Event?> getEventDetails(String eventId) async {
    try {
      final response =
          await _supabase
              .from('events')
              .select('*, artist_profiles(*)')
              .eq('id', eventId)
              .single()
              .execute();

      if (response.data != null) {
        return Event.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Event>> getArtistEvents(
    String artistId, {
    bool includePast = false,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('events')
          .select()
          .eq('artist_id', artistId);

      if (!includePast) {
        queryBuilder = queryBuilder.gte(
          'start_date',
          DateTime.now().toIso8601String(),
        );
      }

      final response = await queryBuilder.order('start_date').execute();

      if (response.data != null) {
        return (response.data as List)
            .map((item) => Event.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createEvent({
    required String artistId,
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required String location,
    File? imageFile,
    double? latitude,
    double? longitude,
    bool isPublic = true,
    int? zipCode,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        final ext = path.extension(imageFile.path);
        final filename = 'event_${_uuid.v4()}$ext';

        await _supabase.storage
            .from('event_images')
            .upload(
              filename,
              imageFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        imageUrl = _supabase.storage
            .from('event_images')
            .getPublicUrl(filename);
      }

      await _supabase.from('events').insert({
        'artist_id': artistId,
        'title': title,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'is_public': isPublic,
        'zip_code': zipCode,
        'created_at': DateTime.now().toIso8601String(),
      });

      Logger.logInfo('Event created successfully');
      return true;
    } catch (e, stackTrace) {
      Logger.logError('Error creating event', e, stackTrace);
      return false;
    }
  }

  Future<bool> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    bool? isPublic,
  }) async {
    try {
      await _supabase
          .from('events')
          .update({
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (startDate != null) 'start_date': startDate.toIso8601String(),
            if (endDate != null) 'end_date': endDate.toIso8601String(),
            if (location != null) 'location': location,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (imageUrl != null) 'image_url': imageUrl,
            if (isPublic != null) 'is_public': isPublic,
          })
          .eq('id', eventId)
          .execute();

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId).execute();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Community calendar filtering methods
  Future<List<Event>> getEventsInTimeRange({
    required DateTime startDate,
    required DateTime endDate,
    int? zipCode,
    int limit = 50,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('events')
          .select('*, artist_profiles(*)')
          .eq('is_public', true)
          .gte('start_date', startDate.toIso8601String())
          .lte('start_date', endDate.toIso8601String())
          .order('start_date')
          .limit(limit);

      if (zipCode != null) {
        queryBuilder = queryBuilder.eq('zip_code', zipCode);
      }

      final response = await queryBuilder.execute();

      if (response.data != null) {
        return (response.data as List)
            .map((item) => Event.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Save an event to user's favorites
  Future<bool> saveEventToFavorites(String userId, String eventId) async {
    try {
      await _supabase.from('favorite_events').insert({
        'user_id': userId,
        'event_id': eventId,
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Remove event from user's favorites
  Future<bool> removeEventFromFavorites(String userId, String eventId) async {
    try {
      await _supabase
          .from('favorite_events')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .execute();

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user's favorite events
  Future<List<Event>> getUserFavoriteEvents(String userId) async {
    try {
      final response =
          await _supabase
              .from('favorite_events')
              .select('event_id, events(*)')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .execute();

      if (response.data != null) {
        return (response.data as List)
            .map((item) => Event.fromJson(item['events']))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Check if an event is in user's favorites
  Future<bool> isEventInFavorites(String userId, String eventId) async {
    try {
      final response =
          await _supabase
              .from('favorite_events')
              .select()
              .eq('user_id', userId)
              .eq('event_id', eventId)
              .execute();

      return response.data != null && (response.data as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> notifyUpcomingEvent(String artistId, String eventTitle) async {
    // Subscribe users to the artist's topic for notifications

    // Log the notification setup
    print('Notification set up for artist: $artistId, event: $eventTitle');
  }

  Future<void> stopNotificationsForArtist(String artistId) async {
    // Unsubscribe users from the artist's topic

    // Log the unsubscription
    print('Stopped notifications for artist: $artistId');
  }
}
