import 'package:flutter/material.dart';
import 'package:miyolist/core/theme/app_theme.dart';
import 'package:miyolist/features/social/domain/services/social_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page to create a new text activity (status post)
class CreateActivityPage extends StatefulWidget {
  final SocialService socialService;
  final int? currentUserId;
  final Map<String, dynamic>? existingActivity; // For editing

  const CreateActivityPage({
    super.key,
    required this.socialService,
    this.currentUserId,
    this.existingActivity,
  });

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _textController = TextEditingController();
  bool _isPosting = false;
  int _characterCount = 0;
  static const int _maxCharacters = 2000; // AniList limit

  @override
  void initState() {
    super.initState();
    
    // If editing, populate with existing text
    if (widget.existingActivity != null) {
      final existingText = widget.existingActivity!['text'] as String? ?? '';
      _textController.text = existingText;
      _characterCount = existingText.length;
    }

    _textController.addListener(() {
      setState(() {
        _characterCount = _textController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _postActivity() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_characterCount > _maxCharacters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text too long ($_characterCount/$_maxCharacters characters)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final activityId = widget.existingActivity?['id'] as int?;
      
      final result = await widget.socialService.postTextActivity(
        text: _textController.text.trim(),
        activityId: activityId,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(activityId != null ? 'Activity updated!' : 'Activity posted!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        throw Exception('Failed to post activity');
      }
    } catch (e) {
      print('Post activity error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post activity'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingActivity != null;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Activity' : 'Create Activity'),
        backgroundColor: AppTheme.cardGray,
        actions: [
          if (_isPosting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _postActivity,
              child: Text(
                isEditing ? 'Update' : 'Post',
                style: TextStyle(
                  color: _textController.text.trim().isEmpty
                      ? Colors.grey
                      : AppTheme.accentBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.cardGray,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 16),
                enabled: !_isPosting,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Character count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_characterCount / $_maxCharacters',
                  style: TextStyle(
                    color: _characterCount > _maxCharacters
                        ? Colors.red
                        : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                
                // Tips
                if (_characterCount == 0)
                  Text(
                    'Share your thoughts with the community',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Formatting tips and Guidelines link
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardGray,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Formatting Tips:',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFormatTip('**bold**', 'Bold text'),
                  _buildFormatTip('*italic*', 'Italic text'),
                  _buildFormatTip('~~strikethrough~~', 'Strikethrough'),
                  _buildFormatTip('@username', 'Mention user'),
                  const SizedBox(height: 12),
                  // Guidelines link
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://anilist.co/forum/thread/14');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.book, size: 16, color: AppTheme.accentBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Read AniList Guidelines (avoid violations)',
                            style: TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Icon(Icons.open_in_new, size: 14, color: AppTheme.accentBlue),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatTip(String syntax, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            syntax,
            style: TextStyle(
              color: AppTheme.accentBlue,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '→ $description',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
