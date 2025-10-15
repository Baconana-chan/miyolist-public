/// GraphQL queries for social features (Following/Followers system)
class SocialQueries {
  /// Get user's following list
  static const String getFollowing = r'''
    query ($userId: Int!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
        }
        following(userId: $userId, sort: USERNAME) {
          id
          name
          avatar {
            large
            medium
          }
          bannerImage
          about
          isFollowing
          isFollower
          donatorTier
          donatorBadge
          statistics {
            anime {
              count
              episodesWatched
              meanScore
            }
            manga {
              count
              chaptersRead
              meanScore
            }
          }
        }
      }
    }
  ''';

  /// Get user's followers list
  static const String getFollowers = r'''
    query ($userId: Int!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
        }
        followers(userId: $userId, sort: USERNAME) {
          id
          name
          avatar {
            large
            medium
          }
          bannerImage
          about
          isFollowing
          isFollower
          donatorTier
          donatorBadge
          statistics {
            anime {
              count
              episodesWatched
              meanScore
            }
            manga {
              count
              chaptersRead
              meanScore
            }
          }
        }
      }
    }
  ''';

  /// Toggle follow/unfollow user
  static const String toggleFollow = r'''
    mutation ($userId: Int!) {
      ToggleFollow(userId: $userId) {
        id
        name
        isFollowing
      }
    }
  ''';

  /// Get public user profile (without requiring Supabase)
  static const String getUserProfile = r'''
    query ($userId: Int, $name: String) {
      User(id: $userId, name: $name) {
        id
        name
        avatar {
          large
          medium
        }
        bannerImage
        about
        isFollowing
        isFollower
        isBlocked
        bans
        donatorTier
        donatorBadge
        moderatorRoles
        options {
          profileColor
          displayAdultContent
        }
        statistics {
          anime {
            count
            episodesWatched
            minutesWatched
            meanScore
            standardDeviation
            statuses {
              status
              count
              minutesWatched
              meanScore
            }
            formats {
              format
              count
              minutesWatched
              meanScore
            }
            genres {
              genre
              count
              minutesWatched
              meanScore
            }
            tags {
              tag {
                id
                name
              }
              count
              minutesWatched
              meanScore
            }
          }
          manga {
            count
            chaptersRead
            volumesRead
            meanScore
            standardDeviation
            statuses {
              status
              count
              chaptersRead
              meanScore
            }
            formats {
              format
              count
              chaptersRead
              meanScore
            }
            genres {
              genre
              count
              chaptersRead
              meanScore
            }
            tags {
              tag {
                id
                name
              }
              count
              chaptersRead
              meanScore
            }
          }
        }
        favourites {
          anime {
            nodes {
              id
              title {
                romaji
                english
                native
                userPreferred
              }
              coverImage {
                large
                medium
              }
              format
              type
            }
          }
          manga {
            nodes {
              id
              title {
                romaji
                english
                native
                userPreferred
              }
              coverImage {
                large
                medium
              }
              format
              type
            }
          }
          characters {
            nodes {
              id
              name {
                full
                native
              }
              image {
                large
                medium
              }
            }
          }
          staff {
            nodes {
              id
              name {
                full
                native
              }
              image {
                large
                medium
              }
            }
          }
          studios {
            nodes {
              id
              name
              isAnimationStudio
            }
          }
        }
      }
    }
  ''';

  /// Search users by username
  static const String searchUsers = r'''
    query ($search: String!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
        }
        users(search: $search, sort: SEARCH_MATCH) {
          id
          name
          avatar {
            large
            medium
          }
          bannerImage
          about
          isFollowing
          isFollower
          donatorTier
          donatorBadge
          statistics {
            anime {
              count
              episodesWatched
              meanScore
            }
            manga {
              count
              chaptersRead
              meanScore
            }
          }
        }
      }
    }
  ''';

  /// Get activity feed from followed users
  static const String getFollowingActivity = r'''
    query ($userId: Int!, $page: Int, $perPage: Int, $isFollowing: Boolean) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
        }
        activities(userId: $userId, isFollowing: $isFollowing, sort: ID_DESC, type_in: [TEXT, ANIME_LIST, MANGA_LIST]) {
          ... on TextActivity {
            id
            type
            text
            createdAt
            user {
              id
              name
              avatar {
                large
              }
            }
            replies {
              id
              text
              createdAt
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            likes {
              id
              name
            }
            replyCount
            likeCount
          }
          ... on ListActivity {
            id
            type
            status
            progress
            createdAt
            user {
              id
              name
              avatar {
                large
              }
            }
            media {
              id
              type
              title {
                userPreferred
              }
              coverImage {
                large
              }
              format
            }
            replies {
              id
              text
              createdAt
              user {
                id
                name
                avatar {
                  large
                }
              }
            }
            likes {
              id
              name
            }
            replyCount
            likeCount
          }
        }
      }
    }
  ''';

  /// Get users who have specific media in their list (for Following section on MediaDetailsPage)
  static const String getMediaFollowingStatus = r'''
    query ($mediaId: Int!, $userId: Int!) {
      Media(id: $mediaId) {
        id
        # Get current user's following who have this media
        # Note: This requires iterating through following list manually
        # as AniList doesn't have direct query for this
      }
    }
  ''';

  /// Get user's media list collection (to check following users' status on media)
  static const String getUserMediaList = r'''
    query ($userId: Int!, $type: MediaType) {
      MediaListCollection(userId: $userId, type: $type, status_in: [CURRENT, PLANNING, COMPLETED, PAUSED, DROPPED, REPEATING]) {
        lists {
          entries {
            id
            mediaId
            status
            score
            progress
            progressVolumes
            repeat
            private
            notes
            startedAt {
              year
              month
              day
            }
            completedAt {
              year
              month
              day
            }
            updatedAt
            media {
              id
              title {
                romaji
                english
                native
                userPreferred
              }
              coverImage {
                large
                medium
              }
              format
              type
              episodes
              chapters
              volumes
            }
          }
        }
      }
    }
  ''';

  /// Get multiple users' media lists in a single batch request
  /// Uses GraphQL aliases to query multiple users at once
  /// Example: getBatchUserMediaLists(userIds: [1, 2, 3], mediaType: 'ANIME')
  static String getBatchUserMediaLists(List<int> userIds, String mediaType) {
    final aliases = userIds.map((userId) {
      return '''
        user$userId: MediaListCollection(userId: $userId, type: $mediaType, status_in: [CURRENT, PLANNING, COMPLETED, PAUSED, DROPPED, REPEATING]) {
          lists {
            entries {
              id
              mediaId
              status
              score
              progress
              progressVolumes
              repeat
              private
            }
          }
        }
      ''';
    }).join('\n');

    return '''
      query {
        $aliases
      }
    ''';
  }

  /// Get following users who have specific media in their list
  static const String getFollowingWithMedia = r'''
    query ($userId: Int!, $mediaId: Int!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
        }
        following(userId: $userId, sort: USERNAME) {
          id
          name
          avatar {
            large
            medium
          }
          donatorTier
          donatorBadge
          isFollowing
          mediaListOptions {
            scoreFormat
          }
        }
      }
      Media(id: $mediaId) {
        id
        type
      }
    }
  ''';
}
