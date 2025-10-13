class AppConstants {
  // AniList OAuth2
  // Получите эти значения на https://anilist.co/settings/developer
  static const String anilistClientId = 'YOUR_CLIENT_ID_HERE';
  static const String anilistClientSecret = 'YOUR_CLIENT_SECRET_HERE';
  
  static const String anilistAuthUrl = 'https://anilist.co/api/v2/oauth/authorize';
  static const String anilistTokenUrl = 'https://anilist.co/api/v2/oauth/token';
  static const String anilistGraphQLUrl = 'https://graphql.anilist.co';
  
  // Redirect URI for mobile and desktop
  static const String redirectUriMobile = 'miyolist://auth';
  static const String redirectUriDesktop = 'http://localhost:8080/auth';
  
  // Supabase - Замените на свои значения
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Hive Boxes
  static const String userBox = 'user_box';
  static const String animeListBox = 'anime_list_box';
  static const String mangaListBox = 'manga_list_box';
  static const String favoritesBox = 'favorites_box';
  static const String settingsBox = 'settings_box';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String lastSyncKey = 'last_sync';
}
