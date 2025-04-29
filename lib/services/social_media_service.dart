import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';

class SocialMediaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createPost({
    required String artistId,
    required String content,
    String? imageUrl,
    String? videoUrl,
    String? location,
    int? zipCode,
  }) async {
    try {
      await _supabase.from('posts').insert({
        'artist_id': artistId,
        'content': content,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'location': location,
        'zip_code': zipCode,
        'created_at': DateTime.now().toIso8601String(),
      });
      Logger.logInfo('Post created successfully');
    } catch (e, stackTrace) {
      Logger.logError('Error creating post', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPosts({int? zipCode}) async {
    try {
      var query = _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      if (zipCode != null) {
        query = query.filter('zip_code', 'eq', zipCode);
      }

      final response = await query;

      if (response != null) {
        Logger.logInfo('Posts fetched successfully');
        return List<Map<String, dynamic>>.from(response as List);
      }
      return [];
    } catch (e, stackTrace) {
      Logger.logError('Error fetching posts', e, stackTrace);
      return [];
    }
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
      Logger.logInfo('Comment added successfully');
    } catch (e, stackTrace) {
      Logger.logError('Error adding comment', e, stackTrace);
      rethrow;
    }
  }

  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _supabase.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      Logger.logInfo('Post liked successfully');
    } catch (e, stackTrace) {
      Logger.logError('Error liking post', e, stackTrace);
      rethrow;
    }
  }

  Future<void> donateToArtist({
    required String artistId,
    required String userId,
    required double amount,
  }) async {
    try {
      await _supabase.from('donations').insert({
        'artist_id': artistId,
        'user_id': userId,
        'amount': amount,
        'created_at': DateTime.now().toIso8601String(),
      });
      Logger.logInfo('Donation made successfully');
    } catch (e, stackTrace) {
      Logger.logError('Error making donation', e, stackTrace);
      rethrow;
    }
  }
}

extension on PostgrestTransformBuilder<PostgrestList> {
  PostgrestTransformBuilder<PostgrestList> filter(
    String s,
    String t,
    int zipCode,
  ) {
    throw UnimplementedError('The filter method is not implemented yet.');
  }
}
