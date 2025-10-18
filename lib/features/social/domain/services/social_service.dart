import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:miyolist/core/graphql/social_queries.dart';
import 'package:miyolist/features/social/data/models/social_user.dart';

/// Service for managing social features (Following/Followers system)
class SocialService {
  final GraphQLClient _client;

  SocialService(this._client);

  /// Follow a user
  Future<bool> followUser(int userId) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.toggleFollow),
          variables: {'userId': userId},
        ),
      );

      if (result.hasException) {
        print('Follow user error: ${result.exception}');
        return false;
      }

      final data = result.data?['ToggleFollow'];
      return data?['isFollowing'] == true;
    } catch (e) {
      print('Follow user exception: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(int userId) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.toggleFollow),
          variables: {'userId': userId},
        ),
      );

      if (result.hasException) {
        print('Unfollow user error: ${result.exception}');
        return false;
      }

      final data = result.data?['ToggleFollow'];
      return data?['isFollowing'] == false;
    } catch (e) {
      print('Unfollow user exception: $e');
      return false;
    }
  }

  /// Toggle follow/unfollow (single call handles both)
  Future<bool> toggleFollow(int userId) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.toggleFollow),
          variables: {'userId': userId},
        ),
      );

      if (result.hasException) {
        print('Toggle follow error: ${result.exception}');
        return false;
      }

      final data = result.data?['ToggleFollow'];
      return data?['isFollowing'] == true;
    } catch (e) {
      print('Toggle follow exception: $e');
      return false;
    }
  }

  /// Get user's following list
  Future<List<SocialUser>> getFollowing(int userId, {int page = 1, int perPage = 50}) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SocialQueries.getFollowing),
          variables: {
            'userId': userId,
            'page': page,
            'perPage': perPage,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Get following error: ${result.exception}');
        return [];
      }

      final following = result.data?['Page']?['following'] as List<dynamic>?;
      if (following == null) return [];

      return following
          .map((json) => SocialUser.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get following exception: $e');
      return [];
    }
  }

  /// Get user's followers list
  Future<List<SocialUser>> getFollowers(int userId, {int page = 1, int perPage = 50}) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SocialQueries.getFollowers),
          variables: {
            'userId': userId,
            'page': page,
            'perPage': perPage,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Get followers error: ${result.exception}');
        return [];
      }

      final followers = result.data?['Page']?['followers'] as List<dynamic>?;
      if (followers == null) return [];

      return followers
          .map((json) => SocialUser.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get followers exception: $e');
      return [];
    }
  }

  /// Check if current user is following target user
  Future<bool> checkIfFollowing(int targetUserId) async {
    try {
      // We can get this info from getUserProfile
      final profile = await getUserProfile(userId: targetUserId);
      return profile?.isFollowing ?? false;
    } catch (e) {
      print('Check if following exception: $e');
      return false;
    }
  }

  /// Get public user profile (no Supabase required)
  Future<PublicUserProfile?> getUserProfile({int? userId, String? username}) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SocialQueries.getUserProfile),
          variables: {
            if (userId != null) 'userId': userId,
            if (username != null) 'name': username,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Get user profile error: ${result.exception}');
        return null;
      }

      final userData = result.data?['User'];
      if (userData == null) return null;

      return PublicUserProfile.fromJson(userData as Map<String, dynamic>);
    } catch (e) {
      print('Get user profile exception: $e');
      return null;
    }
  }

  /// Search users by username
  Future<List<SocialUser>> searchUsers(String query, {int page = 1, int perPage = 20}) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SocialQueries.searchUsers),
          variables: {
            'search': query,
            'page': page,
            'perPage': perPage,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Search users error: ${result.exception}');
        return [];
      }

      final users = result.data?['Page']?['users'] as List<dynamic>?;
      if (users == null) return [];

      return users
          .map((json) => SocialUser.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Search users exception: $e');
      return [];
    }
  }

  /// Get activity feed from followed users
  Future<List<Map<String, dynamic>>> getFollowingActivity(
    int userId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SocialQueries.getFollowingActivity),
          variables: {
            'userId': userId,
            'page': page,
            'perPage': perPage,
            'isFollowing': true,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Get following activity error: ${result.exception}');
        return [];
      }

      final activities = result.data?['Page']?['activities'] as List<dynamic>?;
      if (activities == null) return [];

      return activities.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Get following activity exception: $e');
      return [];
    }
  }

  /// Get user's media list (to check following users' status on specific media)
  Future<List<Map<String, dynamic>>> getUserMediaList(
    int userId,
    String mediaType, // 'ANIME' or 'MANGA'
  ) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SocialQueries.getUserMediaList),
          variables: {
            'userId': userId,
            'type': mediaType,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Get user media list error: ${result.exception}');
        
        // Check for specific error types
        final exception = result.exception;
        if (exception != null) {
          final errorMessage = exception.toString();
          
          // Handle private user
          if (errorMessage.contains('Private User')) {
            print('User $userId has a private list');
            return [];
          }
          
          // Handle rate limiting
          if (errorMessage.contains('Too Many Requests') || 
              errorMessage.contains('429')) {
            print('Rate limit hit for user $userId - waiting before retry');
            await Future.delayed(const Duration(seconds: 2));
            // Don't retry immediately, just return empty
            return [];
          }
        }
        
        return [];
      }

      final collection = result.data?['MediaListCollection'];
      if (collection == null) return [];

      final lists = collection['lists'] as List<dynamic>?;
      if (lists == null) return [];

      final entries = <Map<String, dynamic>>[];
      for (final list in lists) {
        final listEntries = list['entries'] as List<dynamic>?;
        if (listEntries != null) {
          entries.addAll(listEntries.map((e) => e as Map<String, dynamic>));
        }
      }

      return entries;
    } catch (e) {
      print('Get user media list exception: $e');
      return [];
    }
  }

  /// Get multiple users' media lists in a single batch request
  /// Returns a map of userId -> list of media entries
  Future<Map<int, List<Map<String, dynamic>>>> getBatchUserMediaLists(
    List<int> userIds,
    String mediaType,
  ) async {
    if (userIds.isEmpty) return {};
    
    try {
      // Split into chunks of 20 users to avoid query size limits
      const chunkSize = 20;
      final result = <int, List<Map<String, dynamic>>>{};
      
      for (int i = 0; i < userIds.length; i += chunkSize) {
        final chunk = userIds.skip(i).take(chunkSize).toList();
        
        // Add delay between chunks
        if (i > 0) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        final queryString = SocialQueries.getBatchUserMediaLists(chunk, mediaType);
        
        final queryResult = await _client.query(
          QueryOptions(
            document: gql(queryString),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );

        if (queryResult.hasException) {
          print('Batch query error: ${queryResult.exception}');
          // Continue with next chunk
          continue;
        }

        if (queryResult.data == null) continue;

        // Parse each user's data from the response
        for (final userId in chunk) {
          final userKey = 'user$userId';
          final collection = queryResult.data![userKey];
          
          if (collection == null) {
            result[userId] = [];
            continue;
          }

          final lists = collection['lists'] as List<dynamic>?;
          if (lists == null) {
            result[userId] = [];
            continue;
          }

          final entries = <Map<String, dynamic>>[];
          for (final list in lists) {
            final listEntries = list['entries'] as List<dynamic>?;
            if (listEntries != null) {
              entries.addAll(listEntries.map((e) => e as Map<String, dynamic>));
            }
          }
          
          result[userId] = entries;
        }
      }
      
      return result;
    } catch (e) {
      print('Get batch user media lists exception: $e');
      return {};
    }
  }

  /// Get following users who have specific media in their list
  /// (for "Following" section on MediaDetailsPage)
  /// Uses batch queries for better performance
  /// Limited to 20 users to avoid API overload
  Future<List<Map<String, dynamic>>> getFollowingWithMedia(
    int currentUserId,
    int mediaId,
    String mediaType,
  ) async {
    try {
      // 1. Get following list (limited to 20 for performance)
      final following = await getFollowing(currentUserId, perPage: 20);
      
      if (following.isEmpty) return [];
      
      print('📦 Fetching media lists for ${following.length} users (limited to 20)...');
      
      // 2. Get all user IDs
      final userIds = following.map((user) => user.id).toList();
      
      // 3. Batch query all users' media lists (single batch for ≤20 users)
      final allMediaLists = await getBatchUserMediaLists(userIds, mediaType);
      
      print('✅ Received media lists for ${allMediaLists.length} users');
      
      // 4. Process results and find users with this specific media
      final followingWithMedia = <Map<String, dynamic>>[];
      
      for (final user in following) {
        final userId = user.id;
        final mediaList = allMediaLists[userId] ?? [];
        
        // Find entry for this specific media
        final entry = mediaList.firstWhere(
          (e) => e['mediaId'] == mediaId,
          orElse: () => <String, dynamic>{},
        );

        if (entry.isNotEmpty) {
          followingWithMedia.add({
            'user': user,
            'status': entry['status'],
            'score': entry['score'],
            'progress': entry['progress'],
          });
        }
      }

      print('🎯 Found ${followingWithMedia.length} users with this media');
      return followingWithMedia;
    } catch (e) {
      print('Get following with media exception: $e');
      return [];
    }
  }

  /// Toggle like on activity
  Future<bool> toggleActivityLike(int activityId) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.toggleActivityLike),
          variables: {'activityId': activityId},
        ),
      );

      if (result.hasException) {
        print('Toggle activity like error: ${result.exception}');
        return false;
      }

      // Check if liked in response
      final data = result.data?['ToggleLikeV2'];
      return data?['isLiked'] == true;
    } catch (e) {
      print('Toggle activity like exception: $e');
      return false;
    }
  }

  /// Toggle like on activity reply
  Future<bool> toggleActivityReplyLike(int replyId) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.toggleActivityReplyLike),
          variables: {'replyId': replyId},
        ),
      );

      if (result.hasException) {
        print('Toggle reply like error: ${result.exception}');
        return false;
      }

      final data = result.data?['ToggleLikeV2'];
      return data?['isLiked'] == true;
    } catch (e) {
      print('Toggle reply like exception: $e');
      return false;
    }
  }

  /// Post a reply to an activity
  Future<Map<String, dynamic>?> postActivityReply({
    required int activityId,
    required String text,
    int? replyId, // For editing existing reply
  }) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.saveActivityReply),
          variables: {
            'activityId': activityId,
            'text': text,
            if (replyId != null) 'id': replyId,
          },
        ),
      );

      if (result.hasException) {
        print('Post activity reply error: ${result.exception}');
        return null;
      }

      final data = result.data?['SaveActivityReply'];
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('Post activity reply exception: $e');
      return null;
    }
  }

  /// Delete activity reply
  Future<bool> deleteActivityReply(int replyId) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.deleteActivityReply),
          variables: {'id': replyId},
        ),
      );

      if (result.hasException) {
        print('Delete activity reply error: ${result.exception}');
        return false;
      }

      final data = result.data?['DeleteActivityReply'];
      return data?['deleted'] == true;
    } catch (e) {
      print('Delete activity reply exception: $e');
      return false;
    }
  }

  /// Post a text activity (status update)
  Future<Map<String, dynamic>?> postTextActivity({
    required String text,
    int? activityId, // For editing existing activity
  }) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.saveTextActivity),
          variables: {
            'text': text,
            if (activityId != null) 'id': activityId,
          },
        ),
      );

      if (result.hasException) {
        print('Post text activity error: ${result.exception}');
        return null;
      }

      final data = result.data?['SaveTextActivity'];
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('Post text activity exception: $e');
      return null;
    }
  }

  /// Delete activity
  Future<bool> deleteActivity(int activityId) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(SocialQueries.deleteActivity),
          variables: {'id': activityId},
        ),
      );

      if (result.hasException) {
        print('Delete activity error: ${result.exception}');
        return false;
      }

      final data = result.data?['DeleteActivity'];
      return data?['deleted'] == true;
    } catch (e) {
      print('Delete activity exception: $e');
      return false;
    }
  }

  /// Get activity replies
  Future<List<Map<String, dynamic>>> getActivityReplies(
    int activityId, {
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SocialQueries.getActivityReplies),
          variables: {
            'activityId': activityId,
            'page': page,
            'perPage': perPage,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        print('Get activity replies error: ${result.exception}');
        return [];
      }

      final replies = result.data?['Page']?['activityReplies'] as List<dynamic>?;
      if (replies == null) return [];

      return replies
          .map((json) => Map<String, dynamic>.from(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get activity replies exception: $e');
      return [];
    }
  }
}
