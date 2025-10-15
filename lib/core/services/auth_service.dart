import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'web_auth_handler.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final WebAuthHandler _webAuthHandler = WebAuthHandler();
  
  /// Get platform-specific redirect URI
  /// Now uses unified web redirect for all platforms
  String get redirectUri {
    return AppConstants.redirectUriWeb;
  }

  /// Authenticate with AniList OAuth2 via web
  /// Returns access token on success
  Future<String?> authenticateWithAniList() async {
    try {
      print('🔐 Starting web-based OAuth authentication...');
      
      // Step 1: Open web browser with auth page
      final webAuthUrl = Uri.parse(AppConstants.webAuthUrl);
      
      print('🌐 Opening browser: $webAuthUrl');
      
      if (await canLaunchUrl(webAuthUrl)) {
        await launchUrl(
          webAuthUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch auth URL: $webAuthUrl');
      }
      
      // Step 2: Wait for authorization code
      print('⏳ Waiting for authorization code...');
      
      final code = await _waitForAuthCode();
      
      if (code == null) {
        throw Exception('Failed to receive authorization code');
      }
      
      print('✅ Authorization code received: ${code.substring(0, 10)}...');
      
      // Step 3: Exchange code for access token
      print('🔄 Exchanging code for access token...');
      
      final token = await _exchangeCodeForToken(code);
      
      if (token == null) {
        throw Exception('Failed to exchange code for token');
      }
      
      print('✅ Access token received successfully!');
      
      // Step 4: Save token securely
      await saveAccessToken(token);
      
      return token;
      
    } catch (e) {
      print('❌ Authentication error: $e');
      return null;
    }
  }
  
  /// Wait for authorization code using appropriate method for platform
  /// Takes an optional BuildContext for showing manual entry dialog
  Future<String?> _waitForAuthCode() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // Desktop: Use HTTP server to receive callback
      try {
        return await _webAuthHandler.waitForAuthCode();
      } catch (e) {
        print('⚠️ HTTP server method failed: $e');
        // Manual entry would require BuildContext, which we don't have here
        // This should be handled at a higher level (in the UI layer)
        return null;
      }
    } else {
      // Mobile or other platforms
      // TODO: Implement deep linking with app_links package
      print('⚠️ Mobile deep linking not yet implemented');
      return null;
    }
  }
  
  /// Exchange authorization code for access token
  Future<String?> _exchangeCodeForToken(String code) async {
    try {
      final tokenResponse = await http.post(
        Uri.parse(AppConstants.anilistTokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'grant_type': 'authorization_code',
          'client_id': AppConstants.anilistClientId,
          'client_secret': AppConstants.anilistClientSecret,
          'redirect_uri': redirectUri,
          'code': code,
        },
      );

      print('📥 Token response status: ${tokenResponse.statusCode}');
      
      if (tokenResponse.statusCode == 200) {
        final data = json.decode(tokenResponse.body);
        return data['access_token'] as String;
      } else {
        print('❌ Token exchange failed: ${tokenResponse.body}');
        return null;
      }
    } catch (e) {
      print('❌ Token exchange error: $e');
      return null;
    }
  }
  
  /// Authenticate with manual code entry
  /// Use this when automatic code retrieval fails
  Future<String?> authenticateWithManualCode(String code) async {
    try {
      print('🔐 Authenticating with manual code...');
      
      final token = await _exchangeCodeForToken(code);
      
      if (token == null) {
        throw Exception('Failed to exchange code for token');
      }
      
      print('✅ Access token received successfully!');
      
      await saveAccessToken(token);
      
      return token;
      
    } catch (e) {
      print('❌ Manual authentication error: $e');
      return null;
    }
  }

  /// Save access token securely
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: token,
    );
  }

  /// Get saved access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout - clear all stored data
  Future<void> logout() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.userIdKey);
  }
}
