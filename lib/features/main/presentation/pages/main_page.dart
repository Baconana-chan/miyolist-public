import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../activity/presentation/pages/activity_page.dart';
import '../../../anime_list/presentation/pages/anime_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  final AuthService authService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;
  
  const MainPage({
    super.key,
    required this.authService,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      // Activity Page (default)
      ActivityPage(
        authService: widget.authService,
        localStorageService: widget.localStorageService,
        supabaseService: widget.supabaseService,
      ),
      
      // Anime/Manga/Novel Lists
      AnimeListPage(
        authService: widget.authService,
        localStorageService: widget.localStorageService,
        supabaseService: widget.supabaseService,
      ),
      
      // Profile
      ProfilePage(
        authService: widget.authService,
        localStorageService: widget.localStorageService,
        supabaseService: widget.supabaseService,
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: AppTheme.secondaryBlack,
        selectedItemColor: AppTheme.accentRed,
        unselectedItemColor: AppTheme.textGray,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'My Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
