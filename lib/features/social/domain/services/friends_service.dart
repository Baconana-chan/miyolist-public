import 'package:miyolist/features/social/data/models/social_user.dart';
import 'package:miyolist/features/social/domain/services/social_service.dart';

/// Service for managing friends (mutual follows)
/// Built on top of the SocialService as a wrapper
class FriendsService {
  final SocialService _socialService;

  FriendsService(this._socialService);

  /// Get list of friends (users who mutually follow each other)
  /// Friends = users where both isFollowing AND isFollower are true
  Future<List<SocialUser>> getFriends(int userId, {int page = 1, int perPage = 50}) async {
    try {
      // Get following list
      final following = await _socialService.getFollowing(userId, page: page, perPage: perPage);
      
      // Filter for mutual follows (friends)
      // A friend is someone where isFollowing=true AND isFollower=true
      final friends = following.where((user) {
        return user.isFollowing && user.isFollower;
      }).toList();

      print('Friends found: ${friends.length} out of ${following.length} following');
      return friends;
    } catch (e) {
      print('Get friends exception: $e');
      return [];
    }
  }

  /// Get friend requests (users who follow you but you don't follow back)
  /// These are potential friends waiting for you to follow back
  Future<List<SocialUser>> getFriendRequests(int userId, {int page = 1, int perPage = 50}) async {
    try {
      // Get followers list
      final followers = await _socialService.getFollowers(userId, page: page, perPage: perPage);
      
      // Filter for users you're NOT following back
      // Friend request = isFollower=true AND isFollowing=false
      final requests = followers.where((user) {
        return user.isFollower && !user.isFollowing;
      }).toList();

      print('Friend requests found: ${requests.length} out of ${followers.length} followers');
      return requests;
    } catch (e) {
      print('Get friend requests exception: $e');
      return [];
    }
  }

  /// Get suggested friends (users you follow but they don't follow back yet)
  /// These are your outgoing "friend requests"
  Future<List<SocialUser>> getSuggestedFriends(int userId, {int page = 1, int perPage = 50}) async {
    try {
      // Get following list
      final following = await _socialService.getFollowing(userId, page: page, perPage: perPage);
      
      // Filter for users who don't follow you back yet
      // Suggested friend = isFollowing=true AND isFollower=false
      final suggested = following.where((user) {
        return user.isFollowing && !user.isFollower;
      }).toList();

      print('Suggested friends found: ${suggested.length} out of ${following.length} following');
      return suggested;
    } catch (e) {
      print('Get suggested friends exception: $e');
      return [];
    }
  }

  /// Accept friend request (follow back a user who follows you)
  Future<bool> acceptFriendRequest(int userId) async {
    try {
      // Just follow the user back
      return await _socialService.toggleFollow(userId);
    } catch (e) {
      print('Accept friend request exception: $e');
      return false;
    }
  }

  /// Remove friend (unfollow a mutual follow)
  Future<bool> removeFriend(int userId) async {
    try {
      // Just unfollow the user
      return await _socialService.toggleFollow(userId);
    } catch (e) {
      print('Remove friend exception: $e');
      return false;
    }
  }

  /// Check if user is a friend (mutual follow)
  Future<bool> isFriend(int userId, int targetUserId) async {
    try {
      final profile = await _socialService.getUserProfile(userId: targetUserId);
      if (profile == null) return false;
      
      // Friend if both following each other
      return profile.isFollowing && profile.isFollower;
    } catch (e) {
      print('Check if friend exception: $e');
      return false;
    }
  }

  /// Get friend count (total mutual follows)
  Future<int> getFriendCount(int userId) async {
    try {
      final friends = await getFriends(userId);
      return friends.length;
    } catch (e) {
      print('Get friend count exception: $e');
      return 0;
    }
  }

  /// Get friend request count (followers you don't follow back)
  Future<int> getFriendRequestCount(int userId) async {
    try {
      final requests = await getFriendRequests(userId);
      return requests.length;
    } catch (e) {
      print('Get friend request count exception: $e');
      return 0;
    }
  }
}
