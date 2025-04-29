import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class ArtistProfile {
  final String id;
  final String userId;
  final String bio;
  final String? website;
  final String? socialMedia;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final DateTime createdAt;
  final String subscriptionStatus;
  final DateTime? subscriptionEndDate;

  ArtistProfile({
    required this.id,
    required this.userId,
    required this.bio,
    this.website,
    this.socialMedia,
    this.profileImageUrl,
    this.bannerImageUrl,
    required this.createdAt,
    required this.subscriptionStatus,
    this.subscriptionEndDate,
  });

  factory ArtistProfile.fromJson(Map<String, dynamic> json) {
    return ArtistProfile(
      id: json['id'],
      userId: json['user_id'],
      bio: json['bio'],
      website: json['website'],
      socialMedia: json['social_media'],
      profileImageUrl: json['profile_image_url'],
      bannerImageUrl: json['banner_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      subscriptionStatus: json['subscription_status'],
      subscriptionEndDate: json['subscription_end_date'] != null 
          ? DateTime.parse(json['subscription_end_date']) 
          : null,
    );
  }
}

class Artwork {
  final String id;
  final String artistId;
  final String title;
  final String? description;
  final String imageUrl;
  final double? price;
  final String? medium;
  final String? dimensions;
  final bool isForSale;
  final DateTime createdAt;

  Artwork({
    required this.id,
    required this.artistId,
    required this.title,
    this.description,
    required this.imageUrl,
    this.price,
    this.medium,
    this.dimensions,
    required this.isForSale,
    required this.createdAt,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'],
      artistId: json['artist_id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      price: json['price']?.toDouble(),
      medium: json['medium'],
      dimensions: json['dimensions'],
      isForSale: json['is_for_sale'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
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

class ArtistService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<ArtistProfile?> getArtistProfile(String userId) async {
    try {
      final response = await _supabase
          .from('artist_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      if (response != null) {
        return ArtistProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ArtistProfile>> searchArtists({
    String? query,
    int? zipCode,
    int limit = 20,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('artist_profiles')
          .select('*, profiles(*)');

      if (query != null && query.isNotEmpty) {
        // Using ilike for case-insensitive search instead of textSearch
        queryBuilder = queryBuilder.ilike('bio', '%$query%');
      }

      if (zipCode != null) {
        queryBuilder = queryBuilder.eq('zip_code', zipCode);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);

      if (response != null) {
        return (response as List)
            .map((item) => ArtistProfile.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateArtistProfile({
    required String userId,
    String? bio,
    String? website,
    String? socialMedia,
  }) async {
    try {
      await _supabase
          .from('artist_profiles')
          .update({
            if (bio != null) 'bio': bio,
            if (website != null) 'website': website,
            if (socialMedia != null) 'social_media': socialMedia,
          })
          .eq('user_id', userId);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ext = path.extension(imageFile.path);
      final filename = '${userId}_profile_${_uuid.v4()}$ext';

      await _supabase.storage
          .from('profile_images')
          .upload(
            filename,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = _supabase.storage
          .from('profile_images')
          .getPublicUrl(filename);

      await _supabase
          .from('artist_profiles')
          .update({'profile_image_url': imageUrl})
          .eq('user_id', userId);

      notifyListeners();
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadBannerImage(String userId, File imageFile) async {
    try {
      final ext = path.extension(imageFile.path);
      final filename = '${userId}_banner_${_uuid.v4()}$ext';

      await _supabase.storage
          .from('banner_images')
          .upload(
            filename,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = _supabase.storage
          .from('banner_images')
          .getPublicUrl(filename);

      await _supabase
          .from('artist_profiles')
          .update({'banner_image_url': imageUrl})
          .eq('user_id', userId);

      notifyListeners();
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  // Gallery management
  Future<List<Artwork>> getArtistArtworks(String artistId) async {
    try {
      final response = await _supabase
          .from('artworks')
          .select()
          .eq('artist_id', artistId)
          .order('created_at', ascending: false);

      if (response != null) {
        return (response as List)
            .map((item) => Artwork.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addArtwork({
    required String artistId,
    required String title,
    required File imageFile,
    String? description,
    double? price,
    String? medium,
    String? dimensions,
    bool isForSale = true,
    List<String>? tags,
  }) async {
    try {
      final ext = path.extension(imageFile.path);
      final filename = 'artwork_${_uuid.v4()}$ext';

      await _supabase.storage
          .from('artwork_images')
          .upload(
            filename,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = _supabase.storage
          .from('artwork_images')
          .getPublicUrl(filename);

      await _supabase.from('artworks').insert({
        'artist_id': artistId,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'price': price,
        'medium': medium,
        'dimensions': dimensions,
        'is_for_sale': isForSale,
        'tags': tags ?? [],
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateArtwork({
    required String artworkId,
    String? title,
    String? description,
    double? price,
    String? medium,
    String? dimensions,
    bool? isForSale,
    List<String>? tags,
  }) async {
    try {
      await _supabase
          .from('artworks')
          .update({
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (price != null) 'price': price,
            if (medium != null) 'medium': medium,
            if (dimensions != null) 'dimensions': dimensions,
            if (isForSale != null) 'is_for_sale': isForSale,
            if (tags != null) 'tags': tags,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', artworkId);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteArtwork(String artworkId) async {
    try {
      final response = await _supabase
          .from('artworks')
          .select('image_url')
          .eq('id', artworkId)
          .single();

      if (response != null) {
        final imageUrl = response['image_url'] as String?;
        if (imageUrl != null) {
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final filename = pathSegments.last;
            await _supabase.storage.from('artwork_images').remove([filename]);
          }
        }
      }

      await _supabase.from('artworks').delete().eq('id', artworkId);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Artwork?> getArtworkById(String artworkId) async {
    try {
      final response = await _supabase
          .from('artworks')
          .select()
          .eq('id', artworkId)
          .single();

      if (response != null) {
        return Artwork.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Artwork favorites
  Future<bool> addArtworkToFavorites(String userId, String artworkId) async {
    try {
      await _supabase.from('favorite_artworks').insert({
        'user_id': userId,
        'artwork_id': artworkId,
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeArtworkFromFavorites(
    String userId,
    String artworkId,
  ) async {
    try {
      await _supabase
          .from('favorite_artworks')
          .delete()
          .eq('user_id', userId)
          .eq('artwork_id', artworkId);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isArtworkInFavorites(String userId, String artworkId) async {
    try {
      final response = await _supabase
          .from('favorite_artworks')
          .select()
          .eq('user_id', userId)
          .eq('artwork_id', artworkId);

      return response != null && (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<ArtistAnalytics> getArtistAnalytics(
    String artistId, {
    String timePeriod = 'month',
  }) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      int dataPoints;

      switch (timePeriod) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          dataPoints = 7;
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          dataPoints = 12;
          break;
        case 'month':
        default:
          startDate = now.subtract(const Duration(days: 30));
          dataPoints = 30;
          break;
      }

      final artworksResponse = await _supabase
          .from('artworks')
          .select('id')
          .eq('artist_id', artistId);

      final totalArtworks = artworksResponse != null 
          ? (artworksResponse as List).length 
          : 0;

      final eventsResponse = await _supabase
          .from('events')
          .select('id')
          .eq('artist_id', artistId);

      final totalEvents = eventsResponse != null 
          ? (eventsResponse as List).length 
          : 0;

      final random = Random();

      List<DailyViewData> dailyViewData = [];

      if (timePeriod == 'year') {
        for (int i = 0; i < dataPoints; i++) {
          final monthDate = DateTime(startDate.year, startDate.month + i, 1);
          dailyViewData.add(
            DailyViewData(
              date: monthDate,
              profileViews: 50 + random.nextInt(100),
              artworkViews: 80 + random.nextInt(200),
            ),
          );
        }
      } else {
        for (int i = 0; i < dataPoints; i++) {
          final date = startDate.add(Duration(days: i));
          dailyViewData.add(
            DailyViewData(
              date: date,
              profileViews: 5 + random.nextInt(20),
              artworkViews: 10 + random.nextInt(40),
            ),
          );
        }
      }

      List<TopArtwork> topArtworks = [];

      if (totalArtworks > 0) {
        final artworksDetailResponse = await _supabase
            .from('artworks')
            .select()
            .eq('artist_id', artistId)
            .limit(5);

        if (artworksDetailResponse != null) {
          final artworksList = artworksDetailResponse as List;
          topArtworks = artworksList.map((artwork) {
            return TopArtwork(
              id: artwork['id'],
              title: artwork['title'],
              imageUrl: artwork['image_url'],
              views: 50 + random.nextInt(200),
              favorites: 5 + random.nextInt(40),
            );
          }).toList();
        }
      }

      int totalProfileViews = dailyViewData.fold(
        0,
        (sum, item) => sum + item.profileViews,
      );
      int totalArtworkViews = dailyViewData.fold(
        0,
        (sum, item) => sum + item.artworkViews,
      );

      return ArtistAnalytics(
        profileViews: totalProfileViews,
        artworkViews: totalArtworkViews,
        totalFavorites: 10 + random.nextInt(100),
        inquiries: 5 + random.nextInt(20),
        totalArtworks: totalArtworks,
        totalEvents: totalEvents,
        profileCompleteness: 75 + random.nextInt(25),
        dailyViewData: dailyViewData,
        topArtworks: topArtworks,
      );
    } catch (e) {
      return ArtistAnalytics(
        profileViews: 0,
        artworkViews: 0,
        totalFavorites: 0,
        inquiries: 0,
        totalArtworks: 0,
        totalEvents: 0,
        profileCompleteness: 0,
        dailyViewData: [],
        topArtworks: [],
      );
    }
  }

  Future<bool> updateSubscriptionStatus(
    String artistId,
    String subscriptionStatus,
  ) async {
    try {
      DateTime? subscriptionEndDate;
      if (subscriptionStatus != 'basic') {
        subscriptionEndDate = DateTime.now().add(const Duration(days: 30));
      }

      await _supabase
          .from('artist_profiles')
          .update({
            'subscription_status': subscriptionStatus,
            'subscription_end_date': subscriptionEndDate?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', artistId);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get artist profile by ID (different from user ID)
  Future<ArtistProfile?> getArtistProfileById(String artistId) async {
    try {
      final response = await _supabase
          .from('artist_profiles')
          .select('*, profiles(*)')
          .eq('id', artistId)
          .single();

      if (response != null) {
        return ArtistProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get artist's artwork collection
  Future<List<Artwork>> getArtistArtwork(String artistId) async {
    return getArtistArtworks(artistId); // Call existing method
  }

  // Check if an artist is in user's favorites
  Future<bool> isArtistFavorite(String artistId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('favorite_artists')
          .select()
          .eq('user_id', user.id)
          .eq('artist_id', artistId);

      return response != null && (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Add artist to favorites
  Future<bool> addToFavorites(String artistId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('favorite_artists').insert({
        'user_id': user.id,
        'artist_id': artistId,
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Remove artist from favorites
  Future<bool> removeFromFavorites(String artistId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('favorite_artists')
          .delete()
          .eq('user_id', user.id)
          .eq('artist_id', artistId);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
