# MiyoList Web OAuth Integration

## Overview
Унифицированная веб-авторизация для MiyoList, решающая проблему с разными redirect URI для разных платформ.

## Проблема
- **Mobile**: Требуется custom scheme `miyolist://auth`
- **Desktop**: Требуется `http://localhost:8080/auth`
- **Решение**: Единый веб-redirect `https://miyo.my/auth/callback`

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Desktop/     │
│   Mobile)      │
└────────┬────────┘
         │
         │ 1. Opens browser
         ▼
┌─────────────────┐
│  miyo.my   │
│  /auth/login    │
└────────┬────────┘
         │
         │ 2. Redirects to AniList
         ▼
┌─────────────────┐
│  AniList OAuth  │
│  Authorization  │
└────────┬────────┘
         │
         │ 3. Returns with code
         ▼
┌─────────────────┐
│  miyo.my   │
│  /auth/callback │
│  ?code=xxxxx    │
└────────┬────────┘
         │
         │ 4. App extracts code
         ▼
┌─────────────────┐
│  Flutter App    │
│  Exchange code  │
│  for token      │
└─────────────────┘
```

## Web Site Setup

### Tech Stack
- **Framework**: Astro 5.14.4
- **Styling**: Tailwind CSS 3.4
- **Hosting**: TBD (Vercel/Netlify/Cloudflare Pages)

### Pages

#### 1. Landing Page (`/`)
- Hero section with gradient animations
- Feature cards (6 main features)
- Download section with GitHub links
- Responsive navbar and footer

#### 2. Login Page (`/auth/login`)
- AniList OAuth initiation
- Clear user instructions
- Account creation link
- Privacy notice

#### 3. Callback Page (`/auth/callback`)
- Handles OAuth code
- Success/Error states
- Auto-close timer (5 seconds)
- Manual copy fallback

### OAuth Flow

```typescript
// Login page generates auth URL
const CLIENT_ID = '31113';
const REDIRECT_URI = 'https://miyo.my/auth/callback';
const AUTH_URL = `https://anilist.co/api/v2/oauth/authorize
  ?client_id=${CLIENT_ID}
  &redirect_uri=${REDIRECT_URI}
  &response_type=code`;
```

```typescript
// Callback page extracts code
const code = Astro.url.searchParams.get('code');
const error = Astro.url.searchParams.get('error');

// Code is made available for app to read
<div id="auth-code" data-code={code}></div>
```

## Flutter Integration

### Updated Auth Service

```dart
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String _webAuthUrl = 'https://miyo.my/auth/login';
  static const String _callbackUrl = 'https://miyo.my/auth/callback';
  static const String _clientId = '31113';
  static const String _clientSecret = 'YOUR_SECRET';
  
  // Unified auth for all platforms
  Future<String?> signIn() async {
    try {
      // 1. Open web auth in browser
      final uri = Uri.parse(_webAuthUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      
      // 2. Wait for user to complete auth
      // Options:
      //   A. Polling the callback page
      //   B. Deep link interception
      //   C. Manual code entry
      
      final code = await _waitForAuthCode();
      if (code == null) return null;
      
      // 3. Exchange code for token
      final token = await _exchangeCodeForToken(code);
      return token;
      
    } catch (e) {
      print('Auth error: $e');
      return null;
    }
  }
  
  Future<String?> _waitForAuthCode() async {
    // Implementation depends on chosen method:
    
    // Method A: HTTP Server (Desktop only)
    // Start local server, listen for redirect
    
    // Method B: Deep Link (Mobile)
    // Use app_links package to intercept custom scheme
    
    // Method C: Manual Entry (Fallback)
    // Show dialog for user to paste code
  }
  
  Future<String?> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse('https://anilist.co/api/v2/oauth/token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'grant_type': 'authorization_code',
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'redirect_uri': _callbackUrl,
        'code': code,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'];
    }
    return null;
  }
}
```

### Method A: HTTP Server (Recommended for Desktop)

```dart
import 'dart:io';
import 'dart:async';

class DesktopAuthHandler {
  HttpServer? _server;
  final _codeCompleter = Completer<String>();
  
  Future<String?> waitForCallback() async {
    try {
      // Start local server on random port
      _server = await HttpServer.bind('127.0.0.1', 0);
      final port = _server!.port;
      
      print('Listening on http://localhost:$port');
      
      _server!.listen((request) async {
        final code = request.uri.queryParameters['code'];
        
        if (code != null) {
          // Return success page
          request.response
            ..headers.contentType = ContentType.html
            ..write('<h1>Success! You can close this window.</h1>')
            ..close();
          
          _codeCompleter.complete(code);
          await _server!.close();
        }
      });
      
      // Wait for code with timeout
      return await _codeCompleter.future
        .timeout(Duration(minutes: 5));
        
    } catch (e) {
      print('Server error: $e');
      await _server?.close();
      return null;
    }
  }
}
```

### Method B: App Links (Mobile)

```yaml
# pubspec.yaml
dependencies:
  app_links: ^6.0.0
```

```dart
import 'package:app_links/app_links.dart';

class MobileAuthHandler {
  final _appLinks = AppLinks();
  
  Future<String?> waitForCallback() async {
    // Listen for deep links
    final subscription = _appLinks.uriLinkStream.listen((uri) {
      final code = uri.queryParameters['code'];
      // Handle code
    });
    
    // Wait and cleanup
    // ...
  }
}
```

### Method C: Manual Entry (Fallback)

```dart
Future<String?> showCodeEntryDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enter Authorization Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Copy the code from the browser and paste it here:'),
          SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Authorization Code',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(_webAuthUrl)),
            child: Text('Open Browser Again'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _codeController.text);
          },
          child: Text('Submit'),
        ),
      ],
    ),
  );
}
```

## Deployment

### Option 1: Vercel (Recommended)
```bash
npm install -g vercel
cd c:\Users\VIC\miyomy
vercel --prod
```

### Option 2: Netlify
```bash
npm install -g netlify-cli
cd c:\Users\VIC\miyomy
netlify deploy --prod --dir=dist
```

### Option 3: Cloudflare Pages
```bash
npm install -g wrangler
cd c:\Users\VIC\miyomy
npm run build
wrangler pages deploy dist
```

### Custom Domain Setup
1. Buy domain: `miyo.my` or `miyolist.app`
2. Configure DNS records
3. Update OAuth redirect URIs in AniList settings
4. Update Flutter app constants

## AniList Configuration

After deploying, update your AniList app settings:

```
https://anilist.co/settings/developer

Redirect URI:
https://miyo.my/auth/callback
```

## Security Considerations

### PKCE (Proof Key for Code Exchange)
Consider implementing PKCE for enhanced security:

```dart
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PKCEHelper {
  String generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
  
  String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
```

### Environment Variables
Never commit secrets to git:

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String anilistClientId = String.fromEnvironment(
    'ANILIST_CLIENT_ID',
    defaultValue: '31113',
  );
  
  static const String anilistClientSecret = String.fromEnvironment(
    'ANILIST_CLIENT_SECRET',
  );
}
```

Build with secrets:
```bash
flutter build windows --dart-define=ANILIST_CLIENT_SECRET=your_secret
```

## Testing

### Local Testing
```bash
# Start Astro dev server
cd c:\Users\VIC\miyomy
npm run dev

# Update Flutter constants temporarily
static const String _webAuthUrl = 'http://localhost:4321/auth/login';
static const String _callbackUrl = 'http://localhost:4321/auth/callback';
```

### Production Testing
```bash
# Build and deploy
npm run build
vercel --prod

# Test auth flow
1. Open app
2. Click "Sign In"
3. Browser opens
4. Authorize on AniList
5. Redirect to callback
6. App receives code
7. Token exchange
8. Success!
```

## Troubleshooting

### Issue: Browser doesn't open
```dart
// Check if URL can be launched
final uri = Uri.parse(_webAuthUrl);
if (!await canLaunchUrl(uri)) {
  print('Cannot launch URL: $_webAuthUrl');
}
```

### Issue: Code not received
- Check browser console for errors
- Verify redirect URI matches exactly
- Check AniList app settings
- Test callback page directly

### Issue: Token exchange fails
- Verify client secret is correct
- Check redirect URI parameter
- Ensure code hasn't expired (valid ~10 minutes)

## Future Enhancements

### 1. WebSocket Communication
Real-time communication between web and app:
```dart
// Web: Send code via WebSocket
const ws = new WebSocket('wss://miyo.my/ws');
ws.send(JSON.stringify({ type: 'auth_code', code: code }));

// App: Receive code via WebSocket
final channel = WebSocketChannel.connect(
  Uri.parse('wss://miyo.my/ws'),
);
channel.stream.listen((message) {
  final data = json.decode(message);
  if (data['type'] == 'auth_code') {
    handleAuthCode(data['code']);
  }
});
```

### 2. QR Code Auth
Scan QR code from desktop app:
```dart
// Web: Display QR code
import QRCode from 'qrcode';
const qr = await QRCode.toDataURL(authUrl);

// App: Scan QR code
import 'package:mobile_scanner/mobile_scanner.dart';
final scanner = MobileScanner();
```

### 3. OAuth State Parameter
Prevent CSRF attacks:
```dart
final state = generateRandomState();
// Store state in session
final authUrl = '$baseUrl?state=$state';
// Verify state on callback
```

## Migration Path

### Phase 1: Deploy Web (✅ Current)
- Create Astro site
- Set up OAuth pages
- Deploy to hosting

### Phase 2: Update Flutter (Next)
- Implement HTTP server method
- Add manual code entry fallback
- Test on Windows desktop

### Phase 3: Mobile Support (Future)
- Add app_links package
- Configure deep linking
- Test on Android/iOS

### Phase 4: Polish (Future)
- Add WebSocket support
- Implement PKCE
- Add QR code option

## Resources

- [AniList API Docs](https://anilist.gitbook.io/anilist-apiv2-docs/)
- [OAuth 2.0 Spec](https://oauth.net/2/)
- [Astro Docs](https://docs.astro.build/)
- [Flutter URL Launcher](https://pub.dev/packages/url_launcher)
- [App Links Package](https://pub.dev/packages/app_links)

