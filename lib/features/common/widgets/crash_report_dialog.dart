import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/crash_reporter.dart';

/// Dialog shown when app detects a crash from previous session
class CrashReportDialog extends StatelessWidget {
  final String crashReport;

  const CrashReportDialog({
    super.key,
    required this.crashReport,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report,
                    color: Colors.orange.shade400,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unexpected Crash Detected',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'The app closed unexpectedly last time',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We detected that the app crashed in your last session. '
                      'This shouldn\'t happen! 😢',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please help us fix this by sharing the crash report with the developers. '
                      'You can copy it and send it via GitHub Issues or Discord.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Crash report section
                    Text(
                      'Crash Report:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        crashReport,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Help links
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBlack,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppTheme.accentBlue,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Where to report:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildLinkRow(
                            Icons.code,
                            'GitHub Issues',
                            'github.com/Baconana-chan/miyolist/issues',
                          ),
                          const SizedBox(height: 8),
                          _buildLinkRow(
                            Icons.chat,
                            'Discord Server',
                            'discord.gg/miyolist',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: crashReport));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Crash report copied to clipboard'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Report'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                      ),
                      child: const Text('Close'),
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

  Widget _buildLinkRow(IconData icon, String label, String url) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white60,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
        Expanded(
          child: Text(
            url,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.accentBlue,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Show crash report dialog
  static Future<void> showIfNeeded(BuildContext context) async {
    final crashReporter = CrashReporter();
    
    // Check if crashed in last session
    final didCrash = await crashReporter.didCrashInLastSession();
    
    if (!didCrash) return;
    
    // Get crash report
    final report = await crashReporter.getLastCrashReport();
    
    if (report == null || report.isEmpty) return;
    
    // Show dialog
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CrashReportDialog(crashReport: report),
      );
    }
  }
}
