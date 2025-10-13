import 'package:flutter/material.dart';
import '../../../../core/models/user_settings.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileTypeSelectionPage extends StatefulWidget {
  const ProfileTypeSelectionPage({super.key});

  @override
  State<ProfileTypeSelectionPage> createState() => _ProfileTypeSelectionPageState();
}

class _ProfileTypeSelectionPageState extends State<ProfileTypeSelectionPage> {
  bool? _selectedPublic;

  void _selectPrivate() {
    setState(() => _selectedPublic = false);
  }

  void _selectPublic() {
    setState(() => _selectedPublic = true);
  }

  void _continue() {
    if (_selectedPublic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile type')),
      );
      return;
    }

    final settings = _selectedPublic!
        ? UserSettings.defaultPublic()
        : UserSettings.defaultPrivate();

    Navigator.of(context).pop(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Profile Type'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Icon(
              Icons.privacy_tip_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Choose Your Privacy',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            Text(
              'Select how you want to use MiyoList',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Private Profile Card
            _buildProfileCard(
              isSelected: _selectedPublic == false,
              onTap: _selectPrivate,
              icon: Icons.lock,
              title: 'Private Profile',
              subtitle: 'Local only - Maximum privacy',
              features: [
                '✓ All data stored locally on your device',
                '✓ No cloud synchronization',
                '✓ Complete privacy',
                '✗ No cross-device sync',
                '✗ No social features',
              ],
              color: AppTheme.accentBlue,
            ),
            
            const SizedBox(height: 24),
            
            // Public Profile Card
            _buildProfileCard(
              isSelected: _selectedPublic == true,
              onTap: _selectPublic,
              icon: Icons.public,
              title: 'Public Profile',
              subtitle: 'Cloud sync - Full features',
              features: [
                '✓ Local storage for fast access',
                '✓ Cloud sync across devices',
                '✓ Access from anywhere',
                '✓ Social features enabled',
                '✓ Share with community',
              ],
              color: AppTheme.accentRed,
            ),
            
            const SizedBox(height: 32),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textGray.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can change this setting later in your profile',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Continue button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedPublic != null ? _continue : null,
                child: Text(
                  'Continue',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> features,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.textGray.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isSelected ? color : AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 32,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.textGray),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.substring(0, 1),
                    style: TextStyle(
                      fontSize: 16,
                      color: feature.startsWith('✓') ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.substring(2),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
