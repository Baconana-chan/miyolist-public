import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/models/custom_theme.dart';
import '../../core/services/custom_themes_service.dart';

/// Theme editor page for creating/editing custom themes
class ThemeEditorPage extends StatefulWidget {
  final CustomTheme? editingTheme;
  final CustomThemesService themesService;

  const ThemeEditorPage({
    super.key,
    this.editingTheme,
    required this.themesService,
  });

  @override
  State<ThemeEditorPage> createState() => _ThemeEditorPageState();
}

class _ThemeEditorPageState extends State<ThemeEditorPage> {
  late CustomThemesService _themesService;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late bool _isDark;
  late Map<String, Color> _colors;

  @override
  void initState() {
    super.initState();

    _themesService = widget.themesService;

    if (widget.editingTheme != null) {
      // Editing existing theme
      _nameController.text = widget.editingTheme!.name;
      _descriptionController.text = widget.editingTheme!.description ?? '';
      _isDark = widget.editingTheme!.isDark;
      _colors = {
        'Primary Background': widget.editingTheme!.primaryBackgroundColor,
        'Secondary Background': widget.editingTheme!.secondaryBackgroundColor,
        'Card Background': widget.editingTheme!.cardBackgroundColor,
        'Primary Text': widget.editingTheme!.primaryTextColor,
        'Secondary Text': widget.editingTheme!.secondaryTextColor,
        'Tertiary Text': widget.editingTheme!.tertiaryTextColor,
        'Primary Accent': widget.editingTheme!.primaryAccentColor,
        'Secondary Accent': widget.editingTheme!.secondaryAccentColor,
        'Tertiary Accent': widget.editingTheme!.tertiaryAccentColor,
        'Success': widget.editingTheme!.successColor,
        'Warning': widget.editingTheme!.warningColor,
        'Error': widget.editingTheme!.errorColor,
        'Info': widget.editingTheme!.infoColor,
        'Divider': widget.editingTheme!.dividerColor,
        'Shadow': widget.editingTheme!.shadowColor,
      };
    } else {
      // Creating new theme - default to dark theme colors
      _isDark = true;
      _colors = {
        'Primary Background': const Color(0xFF121212),
        'Secondary Background': const Color(0xFF1A1A1A),
        'Card Background': const Color(0xFF1E1E1E),
        'Primary Text': const Color(0xFFFFFFFF),
        'Secondary Text': const Color(0xFFB0B0B0),
        'Tertiary Text': const Color(0xFF808080),
        'Primary Accent': const Color(0xFFE63946),
        'Secondary Accent': const Color(0xFF457B9D),
        'Tertiary Accent': const Color(0xFF2D2D2D),
        'Success': const Color(0xFF4CAF50),
        'Warning': const Color(0xFFFF9800),
        'Error': const Color(0xFFE63946),
        'Info': const Color(0xFF457B9D),
        'Divider': const Color(0xFF2D2D2D),
        'Shadow': const Color(0xFF000000),
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickColor(String colorName) async {
    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $colorName'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _colors[colorName]!,
            onColorChanged: (color) {
              // Update immediately
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _colors[colorName]),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (pickedColor != null) {
      setState(() {
        _colors[colorName] = pickedColor;
      });
    }
  }

  Future<void> _saveTheme() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a theme name')),
      );
      return;
    }

    final theme = CustomTheme.fromThemeColors(
      id: widget.editingTheme?.id ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      primaryBackground: _colors['Primary Background']!,
      secondaryBackground: _colors['Secondary Background']!,
      cardBackground: _colors['Card Background']!,
      primaryText: _colors['Primary Text']!,
      secondaryText: _colors['Secondary Text']!,
      tertiaryText: _colors['Tertiary Text']!,
      primaryAccent: _colors['Primary Accent']!,
      secondaryAccent: _colors['Secondary Accent']!,
      tertiaryAccent: _colors['Tertiary Accent']!,
      success: _colors['Success']!,
      warning: _colors['Warning']!,
      error: _colors['Error']!,
      info: _colors['Info']!,
      divider: _colors['Divider']!,
      shadow: _colors['Shadow']!,
      isDark: _isDark,
    );

    await _themesService.saveTheme(theme);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Theme "${theme.name}" saved successfully!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors['Primary Background'],
      appBar: AppBar(
        title: Text(
          widget.editingTheme != null ? 'Edit Theme' : 'Create Theme',
          style: TextStyle(color: _colors['Primary Text']),
        ),
        backgroundColor: _colors['Secondary Background'],
        iconTheme: IconThemeData(color: _colors['Primary Text']),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTheme,
            tooltip: 'Save Theme',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Info Section
          _buildSection(
            title: 'Theme Info',
            children: [
              TextField(
                controller: _nameController,
                style: TextStyle(color: _colors['Primary Text']),
                decoration: InputDecoration(
                  labelText: 'Theme Name',
                  labelStyle: TextStyle(color: _colors['Secondary Text']),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _colors['Divider']!),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _colors['Primary Accent']!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                style: TextStyle(color: _colors['Primary Text']),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: _colors['Secondary Text']),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _colors['Divider']!),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _colors['Primary Accent']!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(color: _colors['Primary Text']),
                ),
                subtitle: Text(
                  _isDark ? 'Dark theme' : 'Light theme',
                  style: TextStyle(color: _colors['Secondary Text']),
                ),
                value: _isDark,
                onChanged: (value) => setState(() => _isDark = value),
                activeColor: _colors['Primary Accent'],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Background Colors
          _buildSection(
            title: 'Background Colors',
            children: [
              _buildColorTile('Primary Background'),
              _buildColorTile('Secondary Background'),
              _buildColorTile('Card Background'),
            ],
          ),

          const SizedBox(height: 24),

          // Text Colors
          _buildSection(
            title: 'Text Colors',
            children: [
              _buildColorTile('Primary Text'),
              _buildColorTile('Secondary Text'),
              _buildColorTile('Tertiary Text'),
            ],
          ),

          const SizedBox(height: 24),

          // Accent Colors
          _buildSection(
            title: 'Accent Colors',
            children: [
              _buildColorTile('Primary Accent'),
              _buildColorTile('Secondary Accent'),
              _buildColorTile('Tertiary Accent'),
            ],
          ),

          const SizedBox(height: 24),

          // Status Colors
          _buildSection(
            title: 'Status Colors',
            children: [
              _buildColorTile('Success'),
              _buildColorTile('Warning'),
              _buildColorTile('Error'),
              _buildColorTile('Info'),
            ],
          ),

          const SizedBox(height: 24),

          // Special Colors
          _buildSection(
            title: 'Special Colors',
            children: [
              _buildColorTile('Divider'),
              _buildColorTile('Shadow'),
            ],
          ),

          const SizedBox(height: 24),

          // Preview Section
          _buildSection(
            title: 'Preview',
            children: [
              _buildPreview(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors['Card Background'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colors['Divider']!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _colors['Primary Text'],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildColorTile(String colorName) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _colors[colorName],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _colors['Divider']!, width: 2),
        ),
      ),
      title: Text(
        colorName,
        style: TextStyle(color: _colors['Primary Text']),
      ),
      subtitle: Text(
        '#${_colors[colorName]!.value.toRadixString(16).substring(2).toUpperCase()}',
        style: TextStyle(color: _colors['Secondary Text'], fontSize: 12),
      ),
      trailing: Icon(Icons.edit, color: _colors['Primary Accent']),
      onTap: () => _pickColor(colorName),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors['Secondary Background'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _colors['Card Background'],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample Card',
                  style: TextStyle(
                    color: _colors['Primary Text'],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is how text will look',
                  style: TextStyle(color: _colors['Secondary Text']),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        'Action',
                        style: TextStyle(color: _colors['Primary Text']),
                      ),
                      backgroundColor: _colors['Primary Accent'],
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        'Comedy',
                        style: TextStyle(color: _colors['Primary Text']),
                      ),
                      backgroundColor: _colors['Secondary Accent'],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Status colors preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusChip('Success', _colors['Success']!),
              _buildStatusChip('Warning', _colors['Warning']!),
              _buildStatusChip('Error', _colors['Error']!),
              _buildStatusChip('Info', _colors['Info']!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: _colors['Primary Text'], fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
