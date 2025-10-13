import 'package:flutter/material.dart';
import 'package:miyolist/core/theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors;
    
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.secondaryBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                // Left side - Text content
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Version badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentBlue, AppTheme.accentRed],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'v1.0.0 "Aoi (葵)"',
                            style: TextStyle(
                              color: colors.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Welcome to MiyoList!',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          '🌸 Blue skies ahead',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Features list
                        _buildFeature('⚡', 'Lightning Fast', 
                          'Pagination handles 2000+ titles smoothly'),
                        const SizedBox(height: 16),
                        _buildFeature('🔔', 'Real-time Updates', 
                          'Airing schedules with countdown timers'),
                        const SizedBox(height: 16),
                        _buildFeature('📱', 'Offline Ready', 
                          'Full functionality without internet'),
                        const SizedBox(height: 16),
                        _buildFeature('🎨', 'Manga-styled UI', 
                          'Beautiful dark theme with kaomoji'),
                        const SizedBox(height: 32),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              foregroundColor: colors.primaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right side - Image
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF87CEEB), // Sky blue
                          Color(0xFF4A90E2), // Deeper blue
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative elements
                        Positioned(
                          top: 20,
                          right: 20,
                          child: _buildFloatingFlower(),
                        ),
                        Positioned(
                          bottom: 40,
                          left: 20,
                          child: _buildFloatingFlower(),
                        ),
                        
                        // Main image placeholder (will use the uploaded image)
                        Center(
                          child: Image.asset(
                            'assets/images/welcome/aoi_welcome.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if image not found
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    size: 80,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '葵',
                                    style: TextStyle(
                                      fontSize: 72,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String emoji, String title, String description) {
    final colors = AppTheme.colors;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: colors.tertiaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingFlower() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.local_florist,
        color: Colors.white70,
        size: 24,
      ),
    );
  }
}
