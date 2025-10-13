# AniList OAuth2 Setup Guide

## Important: Redirect URL Configuration

When setting up your AniList API Client, you need to specify the correct Redirect URL based on your platform:

### For Android:
```
miyolist://auth
```

### For Windows (Development):
```
http://localhost:8080/auth
```
OR
```
miyolist://auth
```

### For Windows (Production):
After building and installing your app, register the custom URL scheme:

1. Navigate to `windows/` folder in your project
2. Edit `miyolist-protocol.reg` and update the path:
   ```
   @="\"C:\\Path\\To\\Your\\build\\windows\\x64\\runner\\Release\\miyolist.exe\" \"%1\""
   ```
3. Run the .reg file as Administrator
4. Use `miyolist://auth` as Redirect URL in AniList

### Setting up AniList API Client:

1. Go to https://anilist.co/settings/developer
2. Click "Create New Client"
3. Fill in:
   - **Name**: MiyoList (or any name you prefer)
   - **Redirect URL**: 
     - If testing on Android only: `miyolist://auth`
     - If testing on Windows: `miyolist://auth` (after registry setup)
     - Multiple URLs: You can create separate clients for each platform
4. Save and copy your **Client ID**
5. Update `lib/core/constants/app_constants.dart`:
   ```dart
   static const String anilistClientId = 'YOUR_CLIENT_ID_HERE';
   ```

### Testing the Redirect:

**Android:**
- The app automatically handles `miyolist://` scheme
- No additional setup needed after manifest configuration

**Windows:**
- After registry setup, test by opening a browser and typing: `miyolist://auth?code=test`
- Your app should launch and receive the callback

### Multiple Redirect URLs:

AniList allows only ONE redirect URL per client. If you need to test on multiple platforms:

**Option 1: Create Multiple Clients**
- Create one client for Android (`miyolist://auth`)
- Create another for Windows (`miyolist://auth` or `http://localhost:8080/auth`)
- Switch Client IDs based on platform in your code

**Option 2: Use Same Custom Scheme**
- Use `miyolist://auth` for both platforms
- Ensure Windows registry is set up properly
- This is the recommended approach for production

### Troubleshooting:

**Windows not catching the redirect:**
- Verify registry was applied (run as Administrator)
- Check that the exe path in registry is correct
- Restart your browser after registry changes
- Try `http://localhost:8080/auth` as alternative during development

**Android not catching the redirect:**
- Verify AndroidManifest.xml has the intent-filter
- Rebuild the app after manifest changes
- Check that scheme is exactly `miyolist` (lowercase)

**"Invalid redirect URI" error:**
- Redirect URL in AniList settings must EXACTLY match the one in your app
- No trailing slashes
- Case sensitive
- Include the host (`auth`) for custom schemes
