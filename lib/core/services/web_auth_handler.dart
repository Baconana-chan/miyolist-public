import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Handler for web-based OAuth authentication
/// Supports different methods based on platform
class WebAuthHandler {
  HttpServer? _server;
  Timer? _pollTimer;
  
  /// Wait for authorization code using the appropriate method for the platform
  Future<String?> waitForAuthCode() async {
    if (kIsWeb) {
      // Web platform: Not supported in this implementation
      return null;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop: Use HTTP server to receive callback
      return await _waitViaHttpServer();
    } else {
      // Mobile: Fall back to manual entry
      // In a real app, you might use app_links package for deep linking
      return null; // Will trigger manual entry dialog
    }
  }
  
  /// Method A: Local HTTP server (for Desktop platforms)
  /// Creates a temporary local server to receive the OAuth callback
  Future<String?> _waitViaHttpServer() async {
    try {
      // Find an available port
      _server = await HttpServer.bind('127.0.0.1', 0);
      final port = _server!.port;
      
      print('🌐 Listening for auth callback on http://localhost:$port');
      
      final completer = Completer<String>();
      
      // Listen for incoming connections
      _server!.listen((HttpRequest request) async {
        final uri = request.uri;
        print('📨 Received request: $uri');
        
        // Check if this is an auth callback
        if (uri.path == '/auth' || uri.path == '/auth/callback') {
          final code = uri.queryParameters['code'];
          final error = uri.queryParameters['error'];
          
          if (code != null) {
            // Success! Send a nice response page
            await _sendSuccessPage(request);
            
            if (!completer.isCompleted) {
              completer.complete(code);
            }
            
            // Close server after handling callback
            await Future.delayed(Duration(seconds: 2));
            await _cleanup();
          } else if (error != null) {
            // Error occurred
            await _sendErrorPage(request, error);
            
            if (!completer.isCompleted) {
              completer.completeError(Exception('OAuth error: $error'));
            }
            
            await Future.delayed(Duration(seconds: 2));
            await _cleanup();
          }
        } else {
          // Unknown request
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });
      
      // Wait for code with 5-minute timeout
      return await completer.future.timeout(
        Duration(minutes: 5),
        onTimeout: () {
          print('⏱️ Auth timeout');
          _cleanup();
          throw TimeoutException('Authentication timed out');
        },
      );
    } catch (e) {
      print('❌ HTTP server error: $e');
      await _cleanup();
      rethrow;
    }
  }
  
  /// Send success HTML page
  Future<void> _sendSuccessPage(HttpRequest request) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Authentication Successful</title>
  <style>
    body {
      font-family: system-ui, -apple-system, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .container {
      background: white;
      padding: 3rem;
      border-radius: 1rem;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      text-align: center;
      max-width: 400px;
    }
    .success-icon {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: #10b981;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 1.5rem;
    }
    .checkmark {
      color: white;
      font-size: 48px;
      font-weight: bold;
    }
    h1 {
      color: #1f2937;
      margin: 0 0 0.5rem;
      font-size: 1.875rem;
    }
    p {
      color: #6b7280;
      margin: 0 0 1.5rem;
      font-size: 1rem;
    }
    .note {
      font-size: 0.875rem;
      color: #9ca3af;
      margin-top: 1rem;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="success-icon">
      <div class="checkmark">✓</div>
    </div>
    <h1>Authentication Successful!</h1>
    <p>You can close this window now.</p>
    <p class="note">Returning to MiyoList...</p>
  </div>
  <script>
    setTimeout(() => window.close(), 2000);
  </script>
</body>
</html>
''';
    
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }
  
  /// Send error HTML page
  Future<void> _sendErrorPage(HttpRequest request, String error) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Authentication Failed</title>
  <style>
    body {
      font-family: system-ui, -apple-system, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #f87171 0%, #dc2626 100%);
    }
    .container {
      background: white;
      padding: 3rem;
      border-radius: 1rem;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      text-align: center;
      max-width: 400px;
    }
    .error-icon {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: #ef4444;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 1.5rem;
    }
    .cross {
      color: white;
      font-size: 48px;
      font-weight: bold;
    }
    h1 {
      color: #1f2937;
      margin: 0 0 0.5rem;
      font-size: 1.875rem;
    }
    p {
      color: #6b7280;
      margin: 0 0 1.5rem;
      font-size: 1rem;
    }
    .error-details {
      background: #fef2f2;
      border: 1px solid #fecaca;
      border-radius: 0.5rem;
      padding: 1rem;
      margin-top: 1rem;
      font-size: 0.875rem;
      color: #991b1b;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="error-icon">
      <div class="cross">✕</div>
    </div>
    <h1>Authentication Failed</h1>
    <p>There was a problem with authentication.</p>
    <div class="error-details">
      Error: $error
    </div>
  </div>
  <script>
    setTimeout(() => window.close(), 5000);
  </script>
</body>
</html>
''';
    
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }
  
  /// Clean up resources
  Future<void> _cleanup() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    
    try {
      await _server?.close(force: true);
    } catch (e) {
      print('Error closing server: $e');
    }
    _server = null;
  }
  
  /// Get the local server URL for desktop platforms
  String? getLocalServerUrl() {
    if (_server != null) {
      return 'http://localhost:${_server!.port}/auth';
    }
    return null;
  }
}
