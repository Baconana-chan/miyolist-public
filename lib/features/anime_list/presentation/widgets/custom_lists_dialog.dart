import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CustomListsDialog extends StatefulWidget {
  final List<String> initialLists;
  final List<String> allAvailableLists; // All custom lists from user's account

  const CustomListsDialog({
    super.key,
    required this.initialLists,
    required this.allAvailableLists,
  });

  @override
  State<CustomListsDialog> createState() => _CustomListsDialogState();
}

class _CustomListsDialogState extends State<CustomListsDialog> {
  late Set<String> _selectedLists;
  final TextEditingController _newListController = TextEditingController();
  late List<String> _availableLists;

  @override
  void initState() {
    super.initState();
    _selectedLists = Set.from(widget.initialLists);
    _availableLists = List.from(widget.allAvailableLists);
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  void _addNewList() {
    final newList = _newListController.text.trim();
    if (newList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list name')),
      );
      return;
    }

    if (_availableLists.contains(newList)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This list already exists')),
      );
      return;
    }

    setState(() {
      _availableLists.add(newList);
      _selectedLists.add(newList);
      _newListController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.playlist_add, color: AppTheme.accentBlue),
                  const SizedBox(width: 12),
                  const Text(
                    'Custom Lists',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _availableLists.isEmpty
                  ? _buildEmptyState()
                  : _buildListContent(),
            ),

            // Add new list section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack.withOpacity(0.5),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newListController,
                      decoration: const InputDecoration(
                        hintText: 'New list name...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _addNewList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addNewList,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedLists.length} selected',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedLists.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No custom lists yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first custom list below',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableLists.length,
      itemBuilder: (context, index) {
        final listName = _availableLists[index];
        final isSelected = _selectedLists.contains(listName);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected 
              ? AppTheme.accentBlue.withOpacity(0.2)
              : AppTheme.secondaryBlack.withOpacity(0.5),
          child: CheckboxListTile(
            title: Text(
              listName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            value: isSelected,
            activeColor: AppTheme.accentBlue,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedLists.add(listName);
                } else {
                  _selectedLists.remove(listName);
                }
              });
            },
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Remove list',
              onPressed: () {
                _showDeleteConfirmation(listName);
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(String listName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Custom List'),
        content: Text('Are you sure you want to delete "$listName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _availableLists.remove(listName);
                _selectedLists.remove(listName);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
