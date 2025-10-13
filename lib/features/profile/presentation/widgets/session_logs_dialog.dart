import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/crash_reporter.dart';
import '../../../../core/theme/app_theme.dart';

/// Dialog for viewing current session logs
class SessionLogsDialog extends StatefulWidget {
  const SessionLogsDialog({super.key});

  @override
  State<SessionLogsDialog> createState() => _SessionLogsDialogState();
}

class _SessionLogsDialogState extends State<SessionLogsDialog> {
  final _crashReporter = CrashReporter();
  String _logs = 'Loading logs...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    try {
      final logs = await _crashReporter.getCurrentSessionLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _logs = 'Error loading logs: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Logs copied to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardGray,
        title: const Text('Clear Logs?'),
        content: const Text(
          'This will delete all session logs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _crashReporter.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Logs cleared'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardGray,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: AppTheme.accentBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Logs',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        'View logs from current session',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textGray),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.accentBlue,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These logs can help developers debug issues. '
                      'Copy and share them when reporting bugs.',
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Logs content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading logs...',
                              style: TextStyle(color: AppTheme.textGray),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: SelectableText(
                          _logs,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            color: AppTheme.textWhite,
                            height: 1.4,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _copyToClipboard,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy to Clipboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentBlue,
                      side: const BorderSide(color: AppTheme.accentBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _clearLogs,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear Logs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
