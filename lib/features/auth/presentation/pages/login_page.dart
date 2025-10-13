import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../../../core/models/user_settings.dart';
import '../../../anime_list/presentation/pages/anime_list_page.dart';
import 'profile_type_selection_page.dart';

class LoginPage extends StatefulWidget {
  final AuthService authService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;

  const LoginPage({
    super.key,
    required this.authService,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      // Authenticate with AniList
      final accessToken = await widget.authService.authenticateWithAniList();
      
      if (accessToken == null) {
        setState(() => _isLoading = false);
        _showError('Authentication failed');
        return;
      }

      // Show profile type selection
      if (mounted) {
        final settings = await Navigator.of(context).push<UserSettings>(
          MaterialPageRoute(
            builder: (_) => const ProfileTypeSelectionPage(),
          ),
        );

        if (settings == null) {
          setState(() => _isLoading = false);
          return;
        }

        // Save privacy settings
        await widget.localStorageService.saveUserSettings(settings);

        // Continue with data sync
        await _syncUserData(settings);
      }
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncUserData(UserSettings settings) async {
    try {
      print('🔄 Starting data sync...');
      print('📊 Settings: Public=${settings.isPublicProfile}, CloudSync=${settings.enableCloudSync}');
      
      // Fetch user data from AniList
      print('👤 Fetching user data from AniList...');
      final anilistService = AniListService(widget.authService);
      final userData = await anilistService.fetchCurrentUser();
      
      if (userData == null) {
        print('❌ Failed to fetch user data');
        _showError('Failed to fetch user data');
        return;
      }

      print('✅ User data received: ${userData['name']}');

      // Save user locally (always)
      print('💾 Saving user locally...');
      final user = UserModel.fromJson(userData);
      await widget.localStorageService.saveUser(user);
      print('✅ User saved locally (ID: ${user.id})');

      // Sync to cloud only if public profile (non-critical)
      if (settings.enableCloudSync) {
        try {
          print('☁️ Syncing user to Supabase...');
          await widget.supabaseService.syncUserData(user.toSupabaseJson());
          print('✅ User synced to cloud');
        } catch (e) {
          print('⚠️ Cloud sync failed (non-critical): $e');
          // Continue execution - local data is sufficient
        }
      }

      // Fetch and save anime list
      print('📺 Fetching anime list from AniList...');
      final animeListData = await anilistService.fetchAnimeList(user.id);
      print('📺 Anime list received: ${animeListData?.length ?? 0} entries');
      
      if (animeListData != null) {
        final animeList = animeListData
            .map((e) => MediaListEntry.fromJson(e))
            .toList();
        
        print('💾 Saving ${animeList.length} anime entries locally...');
        // Always save locally
        await widget.localStorageService.saveAnimeList(animeList);
        print('✅ Anime list saved locally');
        
        // Sync to cloud only if enabled (non-critical)
        if (settings.enableCloudSync) {
          try {
            print('☁️ Syncing anime list to Supabase...');
            await widget.supabaseService.syncAnimeList(
              user.id,
              animeList.map((e) => e.toSupabaseJson(isManga: false)).toList(),
            );
            print('✅ Anime list synced to cloud');
          } catch (e) {
            print('⚠️ Cloud sync failed (non-critical): $e');
            // Continue execution - local data is sufficient
          }
        }
      }

      // Fetch and save manga list
      print('📚 Fetching manga list from AniList...');
      final mangaListData = await anilistService.fetchMangaList(user.id);
      print('📚 Manga list received: ${mangaListData?.length ?? 0} entries');
      
      if (mangaListData != null) {
        final mangaList = mangaListData
            .map((e) => MediaListEntry.fromJson(e))
            .toList();
        
        print('💾 Saving ${mangaList.length} manga entries locally...');
        // Always save locally
        await widget.localStorageService.saveMangaList(mangaList);
        print('✅ Manga list saved locally');
        
        // Sync to cloud only if enabled (non-critical)
        if (settings.enableCloudSync) {
          try {
            print('☁️ Syncing manga list to Supabase...');
            await widget.supabaseService.syncMangaList(
              user.id,
              mangaList.map((e) => e.toSupabaseJson(isManga: true)).toList(),
            );
            print('✅ Manga list synced to cloud');
          } catch (e) {
            print('⚠️ Cloud sync failed (non-critical): $e');
            // Continue execution - local data is sufficient
          }
        }
      }

      // Fetch and save favorites
      print('⭐ Fetching favorites from AniList...');
      final favorites = await anilistService.fetchUserFavorites(user.id);
      if (favorites != null) {
        print('💾 Saving favorites locally...');
        // Always save locally
        await widget.localStorageService.saveFavorites(favorites);
        print('✅ Favorites saved locally');
        
        // Sync to cloud only if enabled (non-critical)
        if (settings.enableCloudSync) {
          try {
            print('☁️ Syncing favorites to Supabase...');
            await widget.supabaseService.syncFavorites(user.id, favorites);
            print('✅ Favorites synced to cloud');
          } catch (e) {
            print('⚠️ Cloud sync failed (non-critical): $e');
            // Continue execution - local data is sufficient
          }
        }
      }

      // Save last sync time
      await widget.localStorageService.saveLastSyncTime(DateTime.now());
      
      print('🎉 Data sync completed successfully!');

      // Show success message
      if (mounted) {
        final profileType = settings.isPublicProfile ? 'public' : 'private';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome! Your $profileType profile is ready.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to main page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AnimeListPage(
              authService: widget.authService,
              localStorageService: widget.localStorageService,
              supabaseService: widget.supabaseService,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Data sync failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/title with manga-style
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        offset: const Offset(6, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MiyoList',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unofficial AniList Client',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Description
                Text(
                  'Track your anime and manga lists\nwith style',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Login with AniList',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Info text
                Text(
                  'You will be redirected to AniList\nto authorize this app',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
