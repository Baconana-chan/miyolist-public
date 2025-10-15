import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../../../core/models/user_settings.dart';
import '../../../main/presentation/pages/main_page.dart';
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
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to open browser - don't block if it fails
      try {
        await _openAuthBrowser();
      } catch (browserError) {
        print('⚠️ Could not open browser automatically: $browserError');
        // Show a helpful message but continue to manual entry
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Browser didn\'t open? No problem! Manually visit:\nhttps://miyo.my/auth/login',
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Copy Link',
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'https://miyo.my/auth/login'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
      
      // Show manual code entry dialog
      if (mounted) {
        setState(() => _isLoading = false);
        await _handleManualCodeEntry();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _openAuthBrowser() async {
    final webAuthUrl = Uri.parse('https://miyo.my/auth/login');
    if (await canLaunchUrl(webAuthUrl)) {
      await launchUrl(
        webAuthUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch auth URL');
    }
  }

  Future<void> _handleManualCodeEntry() async {
    final code = await _showManualCodeDialog();
    
    if (code != null && code.isNotEmpty && mounted) {
      setState(() => _isLoading = true);
      
      try {
        final accessToken = await widget.authService.authenticateWithManualCode(code);
        
        if (accessToken == null) {
          setState(() {
            _errorMessage = 'Failed to exchange code for token';
            _isLoading = false;
          });
          return;
        }
        
        await _continueWithAuth();
      } catch (e) {
        setState(() {
          _errorMessage = 'Manual authentication failed: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showManualCodeDialog() async {
    final codeController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.vpn_key, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Enter Authorization Code'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'How to get the authorization code:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow('1', 'A browser will open to https://miyo.my/auth/login'),
                    const SizedBox(height: 6),
                    _buildStepRow('2', 'Click "Authorize" on AniList'),
                    const SizedBox(height: 6),
                    _buildStepRow('3', 'After authorization, you\'ll be redirected to https://miyo.my/auth/callback'),
                    const SizedBox(height: 6),
                    _buildStepRow('4', 'Copy the entire callback URL or just the code from the page'),
                    const SizedBox(height: 6),
                    _buildStepRow('5', 'Paste it below - the app will automatically extract your code'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12, 
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  const TextSpan(text: 'The callback page is on '),
                                  TextSpan(
                                    text: 'miyo.my',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: '. You can paste either the full URL or just the code!'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Browser didn\'t open?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade200,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final url = Uri.parse('https://miyo.my/auth/login');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          Clipboard.setData(const ClipboardData(text: 'https://miyo.my/auth/login'));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link copied! Open it manually in your browser'),
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Open Login Page',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Authorization Code',
                  hintText: 'Paste your code here...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.code),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        String code = data!.text!.trim();
                        // Remove URL prefix if user pasted full callback URL
                        if (code.contains('miyo.my/auth/callback?code=')) {
                          code = code.split('code=').last.split('&').first;
                        } else if (code.startsWith('http')) {
                          // Handle any URL format
                          try {
                            final uri = Uri.parse(code);
                            code = uri.queryParameters['code'] ?? code;
                          } catch (_) {
                            // If parsing fails, use as is
                          }
                        }
                        codeController.text = code;
                      }
                    },
                    tooltip: 'Paste from clipboard',
                  ),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final code = codeController.text.trim();
                  if (code.isNotEmpty) {
                    Navigator.pop(context, code);
                  }
                },
                onChanged: (value) {
                  // Auto-clean URL if user types/pastes directly
                  if (value.contains('miyo.my/auth/callback?code=')) {
                    final cleaned = value.split('code=').last.split('&').first;
                    if (cleaned != value) {
                      codeController.text = cleaned;
                      codeController.selection = TextSelection.fromPosition(
                        TextPosition(offset: cleaned.length),
                      );
                    }
                  } else if (value.startsWith('http')) {
                    try {
                      final uri = Uri.parse(value);
                      final code = uri.queryParameters['code'];
                      if (code != null && code != value) {
                        codeController.text = code;
                        codeController.selection = TextSelection.fromPosition(
                          TextPosition(offset: code.length),
                        );
                      }
                    } catch (_) {}
                  }
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  // Re-open browser
                  final webAuthUrl = Uri.parse('https://miyo.my/auth/login');
                  if (await canLaunchUrl(webAuthUrl)) {
                    await launchUrl(
                      webAuthUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Browser Again'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter the authorization code'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, code);
            },
            icon: const Icon(Icons.check),
            label: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _continueWithAuth() async {
    if (!mounted) return;
    
    try {
      // Show profile type selection
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to continue: $e';
        _isLoading = false;
      });
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

      // Fetch all media lists in a single optimized query
      print('� Fetching all media lists from AniList (anime + manga)...');
      final allMediaLists = await anilistService.fetchAllMediaLists(user.id);
      
      // Process anime list
      final animeListData = allMediaLists['anime'];
      print('📺 Anime list received: ${animeListData?.length ?? 0} entries');
      
      if (animeListData != null && animeListData.isNotEmpty) {
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

      // Process manga list
      final mangaListData = allMediaLists['manga'];
      print('📚 Manga list received: ${mangaListData?.length ?? 0} entries');
      
      if (mangaListData != null && mangaListData.isNotEmpty) {
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
            builder: (_) => MainPage(
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
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                
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
                
                const SizedBox(height: 12),
                
                // Manual code entry button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleManualCodeEntry,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Enter Code Manually',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
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

  /// Helper method to build instruction step rows
  Widget _buildStepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
