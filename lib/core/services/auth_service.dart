import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../constants/app_constants.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Get platform-specific redirect URI
  String get redirectUri {
    // Windows/Linux/MacOS require http://localhost
    // Android/iOS can use custom scheme
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return AppConstants.redirectUriDesktop;
    } else {
      return AppConstants.redirectUriMobile;
    }
  }
  
  /// Get callback URL scheme for flutter_web_auth_2
  String get callbackUrlScheme {
    // Desktop: must be 'http://localhost:PORT' (exact format required)
    // Mobile: custom scheme without '://'
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:8080';
    } else {
      return 'miyolist';
    }
  }

  /// Authenticate with AniList OAuth2
  /// Returns access token on success
  Future<String?> authenticateWithAniList() async {
    try {
      // Build authorization URL with platform-specific redirect URI
      final authUrl = Uri.parse(AppConstants.anilistAuthUrl).replace(
        queryParameters: {
          'client_id': AppConstants.anilistClientId,
          'redirect_uri': redirectUri,
          'response_type': 'code',
        },
      );

      print('🔐 Auth URL: $authUrl');
      print('📍 Redirect URI: $redirectUri');
      print('🔗 Callback scheme: $callbackUrlScheme');

      // Launch web authentication with platform-specific callback scheme
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: callbackUrlScheme,
      );
      
      print('✅ Auth result: $result');

      // Extract authorization code from callback
      final code = Uri.parse(result).queryParameters['code'];
      
      if (code == null) {
        throw Exception('Authorization code not found');
      }

      print('🔄 Exchanging code for access token...');

      // Exchange code for access token (use same redirect URI)
      // AniList expects form-encoded data, not JSON
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
      print('📥 Token response body: ${tokenResponse.body}');

      if (tokenResponse.statusCode == 200) {
        final data = json.decode(tokenResponse.body);
        final accessToken = data['access_token'] as String;
        
        print('✅ Access token received successfully!');
        
        // Save token securely
        await saveAccessToken(accessToken);
        
        return accessToken;
      } else {
        throw Exception('Failed to get access token: ${tokenResponse.body}');
      }
    } catch (e) {
      print('Authentication error: $e');
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
