import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

/// Dialog for manual authorization code entry
/// Used as a fallback when automatic code retrieval fails
class ManualCodeEntryDialog extends StatefulWidget {
  const ManualCodeEntryDialog({super.key});

  @override
  State<ManualCodeEntryDialog> createState() => _ManualCodeEntryDialogState();
}

class _ManualCodeEntryDialogState extends State<ManualCodeEntryDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _openBrowser() async {
    final url = Uri.parse(AppConstants.webAuthUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the authorization code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Authorization Code'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To complete authentication:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Click "Open Browser" below'),
            const Text('2. Authorize with AniList'),
            const Text('3. Copy the code from the callback page'),
            const Text('4. Paste it here and submit'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Authorization Code',
                hintText: 'Paste code here...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _codeController.text = data!.text!;
                    }
                  },
                  tooltip: 'Paste from clipboard',
                ),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Browser'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: The code will be displayed on the callback page after you authorize.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

/// Show manual code entry dialog
Future<String?> showManualCodeEntryDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const ManualCodeEntryDialog(),
  );
}
