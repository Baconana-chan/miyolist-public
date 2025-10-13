# AniList GraphQL Query Examples

This file contains useful GraphQL queries and mutations for the AniList API.
These are already implemented in `anilist_service.dart`, but you can use them for testing or extending functionality.

## Authentication

The app uses OAuth2 Bearer token authentication. All requests include:
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

## Useful Queries

### 1. Get Current User
```graphql
query {
  Viewer {
    id
    name
    avatar {
      large
      medium
    }
    bannerImage
    about
    statistics {
      anime {
        count
        episodesWatched
        minutesWatched
      }
      manga {
        count
        chaptersRead
        volumesRead
      }
    }
    createdAt
    updatedAt
  }
}
```

### 2. Get User's Anime List
```graphql
query($userId: Int, $type: MediaType) {
  MediaListCollection(userId: $userId, type: $type) {
    lists {
      name
      isCustomList
      entries {
        id
        mediaId
        status
        score
        progress
        repeat
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
          }
          coverImage {
            large
            extraLarge
          }
          bannerImage
          episodes
          status
          format
          season
          seasonYear
          averageScore
          popularity
          description
          genres
          studios {
            nodes {
              name
            }
          }
        }
      }
    }
  }
}

Variables:
{
  "userId": 123456,
  "type": "ANIME"
}
```

### 3. Search Anime/Manga
```graphql
query($search: String, $type: MediaType) {
  Page(page: 1, perPage: 20) {
    media(search: $search, type: $type) {
      id
      title {
        romaji
        english
      }
      coverImage {
        large
      }
      episodes
      status
      averageScore
      format
      season
      seasonYear
    }
  }
}

Variables:
{
  "search": "Attack on Titan",
  "type": "ANIME"
}
```

### 4. Get Media Details
```graphql
query($id: Int) {
  Media(id: $id) {
    id
    title {
      romaji
      english
      native
    }
    coverImage {
      extraLarge
    }
    bannerImage
    description
    episodes
    duration
    status
    format
    season
    seasonYear
    averageScore
    popularity
    genres
    studios {
      nodes {
        name
      }
    }
    relations {
      edges {
        relationType
        node {
          id
          title {
            romaji
          }
          coverImage {
            large
          }
        }
      }
    }
    characters {
      edges {
        role
        node {
          id
          name {
            full
          }
          image {
            large
          }
        }
      }
    }
  }
}

Variables:
{
  "id": 16498
}
```

### 5. Get User Favorites
```graphql
query($userId: Int) {
  User(id: $userId) {
    favourites {
      anime {
        nodes {
          id
          title {
            romaji
            english
          }
          coverImage {
            large
          }
        }
      }
      manga {
        nodes {
          id
          title {
            romaji
            english
          }
          coverImage {
            large
          }
        }
      }
      characters {
        nodes {
          id
          name {
            full
          }
          image {
            large
          }
        }
      }
      staff {
        nodes {
          id
          name {
            full
          }
          image {
            large
          }
        }
      }
      studios {
        nodes {
          id
          name
        }
      }
    }
  }
}

Variables:
{
  "userId": 123456
}
```

## Useful Mutations

### 1. Save/Update Media List Entry
```graphql
mutation(
  $mediaId: Int,
  $status: MediaListStatus,
  $score: Float,
  $progress: Int,
  $progressVolumes: Int,
  $repeat: Int,
  $notes: String,
  $startedAt: FuzzyDateInput,
  $completedAt: FuzzyDateInput
) {
  SaveMediaListEntry(
    mediaId: $mediaId,
    status: $status,
    score: $score,
    progress: $progress,
    progressVolumes: $progressVolumes,
    repeat: $repeat,
    notes: $notes,
    startedAt: $startedAt,
    completedAt: $completedAt
  ) {
    id
    mediaId
    status
    score
    progress
    progressVolumes
    repeat
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
  }
}

Variables:
{
  "mediaId": 16498,
  "status": "CURRENT",
  "score": 9.5,
  "progress": 15,
  "notes": "Amazing anime!",
  "startedAt": {
    "year": 2025,
    "month": 1,
    "day": 1
  }
}
```

### 2. Delete Media List Entry
```graphql
mutation($id: Int) {
  DeleteMediaListEntry(id: $id) {
    deleted
  }
}

Variables:
{
  "id": 123456789
}
```

### 3. Toggle Favorite
```graphql
mutation($animeId: Int, $mangaId: Int, $characterId: Int, $staffId: Int, $studioId: Int) {
  ToggleFavourite(
    animeId: $animeId,
    mangaId: $mangaId,
    characterId: $characterId,
    staffId: $staffId,
    studioId: $studioId
  ) {
    anime {
      nodes {
        id
      }
    }
    manga {
      nodes {
        id
      }
    }
    characters {
      nodes {
        id
      }
    }
    staff {
      nodes {
        id
      }
    }
    studios {
      nodes {
        id
      }
    }
  }
}

Variables (use only one):
{
  "animeId": 16498
}
```

## Status Values

### MediaListStatus
- `CURRENT` - Currently watching/reading
- `PLANNING` - Planning to watch/read
- `COMPLETED` - Completed
- `DROPPED` - Dropped
- `PAUSED` - Paused
- `REPEATING` - Rewatching/Rereading

### MediaStatus
- `FINISHED` - Has completed and is no longer being released
- `RELEASING` - Currently releasing
- `NOT_YET_RELEASED` - To be released at a later date
- `CANCELLED` - Ended before the work could be finished

## Testing Queries

You can test these queries at: https://anilist.co/graphiql

1. Login to AniList
2. Go to the GraphiQL interface
3. Paste any query
4. Add variables if needed
5. Click Execute

## Rate Limiting

AniList API has rate limits:
- 90 requests per minute
- Burst of 30 requests

The app handles this by:
- Caching data locally with Hive
- Syncing to Supabase for cross-device access
- Only calling AniList API when necessary

## Additional Resources

- AniList API Documentation: https://anilist.gitbook.io/anilist-apiv2-docs/
- GraphQL Docs: https://graphql.org/learn/
- AniList Discord: https://discord.gg/TF428cr
