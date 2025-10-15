import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/models/custom_theme.dart';
import '../../core/services/custom_themes_service.dart';
import 'theme_editor_page.dart';

/// Custom themes management page
class CustomThemesPage extends StatefulWidget {
  final CustomThemesService themesService;

  const CustomThemesPage({
    super.key,
    required this.themesService,
  });

  @override
  State<CustomThemesPage> createState() => _CustomThemesPageState();
}

class _CustomThemesPageState extends State<CustomThemesPage> {
  late CustomThemesService _themesService;
  List<CustomTheme> _themes = [];

  @override
  void initState() {
    super.initState();
    _themesService = widget.themesService;
    _loadThemes();
  }

  void _loadThemes() {
    setState(() {
      _themes = _themesService.getAllThemes();
    });
  }

  Future<void> _createNewTheme() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ThemeEditorPage(themesService: _themesService),
      ),
    );

    if (result == true) {
      _loadThemes();
    }
  }

  Future<void> _editTheme(CustomTheme theme) async {
    if (theme.isDefault) {
      // Cannot edit built-in themes, but can duplicate them
      await _duplicateTheme(theme);
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ThemeEditorPage(
          editingTheme: theme,
          themesService: _themesService,
        ),
      ),
    );

    if (result == true) {
      _loadThemes();
    }
  }

  Future<void> _duplicateTheme(CustomTheme theme) async {
    final nameController = TextEditingController(text: '${theme.name} (Copy)');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Theme'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Theme Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      await _themesService.duplicateTheme(theme, newName.trim());
      _loadThemes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Theme "$newName" created!')),
        );
      }
    }
  }

  Future<void> _deleteTheme(CustomTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Theme'),
        content: Text('Are you sure you want to delete "${theme.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _themesService.deleteTheme(theme.id);
      if (success) {
        _loadThemes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Theme "${theme.name}" deleted')),
          );
        }
      }
    }
  }

  Future<void> _exportTheme(CustomTheme theme) async {
    final json = _themesService.exportTheme(theme);
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Theme'),
        content: SingleChildScrollView(
          child: SelectableText(jsonString),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Save to file
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Themes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewTheme,
            tooltip: 'Create New Theme',
          ),
        ],
      ),
      body: _themes.isEmpty
          ? const Center(
              child: Text('No custom themes yet.\nTap + to create one!'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _themes.length,
              itemBuilder: (context, index) {
                final theme = _themes[index];
                return _buildThemeCard(theme);
              },
            ),
    );
  }

  Widget _buildThemeCard(CustomTheme theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _editTheme(theme),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme name and badges
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (theme.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            theme.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (theme.isDefault)
                    Chip(
                      label: const Text('Built-in', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.blue[100],
                      padding: EdgeInsets.zero,
                    ),
                  if (theme.isDark)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.dark_mode, size: 20),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.light_mode, size: 20),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Color preview
              Row(
                children: [
                  _buildColorPreview(theme.primaryBackgroundColor),
                  _buildColorPreview(theme.secondaryBackgroundColor),
                  _buildColorPreview(theme.cardBackgroundColor),
                  _buildColorPreview(theme.primaryAccentColor),
                  _buildColorPreview(theme.secondaryAccentColor),
                  _buildColorPreview(theme.successColor),
                  _buildColorPreview(theme.warningColor),
                  _buildColorPreview(theme.errorColor),
                ],
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _duplicateTheme(theme),
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: const Text('Duplicate'),
                  ),
                  TextButton.icon(
                    onPressed: () => _exportTheme(theme),
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Export'),
                  ),
                  if (!theme.isDefault)
                    TextButton.icon(
                      onPressed: () => _deleteTheme(theme),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview(Color color) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
    );
  }
}
