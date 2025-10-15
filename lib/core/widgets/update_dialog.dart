import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';

/// Dialog for showing available app update
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onSkip;
  final VoidCallback? onRemindLater;
  final VoidCallback? onUpdate;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onSkip,
    this.onRemindLater,
    this.onUpdate,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;

  Future<void> _openDownloadUrl() async {
    setState(() => _isDownloading = true);

    try {
      final url = Uri.parse(widget.updateInfo.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        widget.onUpdate?.call();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open download link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[UpdateDialog] Error opening download URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _openReleaseUrl() async {
    try {
      final url = Uri.parse(widget.updateInfo.releaseUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('[UpdateDialog] Error opening release URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Update icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_alt,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'Update Available',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Version info
                  Text(
                    'v${widget.updateInfo.currentVersion} → v${widget.updateInfo.version}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Published time
                  if (widget.updateInfo.publishedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Released ${widget.updateInfo.timeSincePublished}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Changelog section
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "What's New" header
                    Row(
                      children: [
                        Icon(
                          Icons.new_releases,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'What\'s New',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Changelog content
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.updateInfo.formattedChangelog,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Link to full release notes
                    Center(
                      child: TextButton.icon(
                        onPressed: _openReleaseUrl,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View Full Release Notes'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Primary action: Download
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _openDownloadUrl,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        _isDownloading ? 'Opening...' : 'Download Update',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary actions row
                  Row(
                    children: [
                      // Skip this version
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            widget.onSkip?.call();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Skip'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Remind me later
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            widget.onRemindLater?.call();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Remind Later'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
