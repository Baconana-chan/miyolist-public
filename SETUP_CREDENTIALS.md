# 🔐 Setting Up Credentials

Before running MiyoList, you need to set up your API credentials. This guide will walk you through the process.

## ⚠️ Important Notice

The `app_constants.dart` file contains sensitive information and should never be committed to version control with real credentials. We've provided an example file (`app_constants.dart.example`) that you should copy and modify.

## 📋 Quick Setup

### Step 1: Copy the Example File

```bash
# Copy the example file
cp lib/core/constants/app_constants.dart.example lib/core/constants/app_constants.dart
```

### Step 2: Get AniList Credentials

1. Go to [AniList Developer Settings](https://anilist.co/settings/developer)
2. Create a new API Client
3. Set the redirect URI to:
   - **For Desktop (Windows/Linux/macOS)**: `http://localhost:8080/auth`
   - **For Mobile**: `miyolist://auth`
4. Copy your **Client ID** and **Client Secret**

### Step 3: (Optional) Set Up Supabase

If you want cloud sync functionality:

1. Create a free account at [Supabase](https://supabase.com)
2. Create a new project
3. Go to Settings → API
4. Copy your:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **Anon/Public Key**
5. Run the SQL schema from `supabase_schema.sql` in your Supabase project

> **Note**: Supabase is optional. The app works perfectly fine with local storage only (using Hive).

### Step 4: Update app_constants.dart

Open `lib/core/constants/app_constants.dart` and replace the placeholders:

```dart
class AppConstants {
  // Replace these with your actual credentials
  static const String anilistClientId = 'YOUR_ANILIST_CLIENT_ID';
  static const String anilistClientSecret = 'YOUR_ANILIST_CLIENT_SECRET';
  
  // Optional: Replace if using Supabase
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // ... rest of the file
}
```

## 🔒 Security Best Practices

1. **Never commit `app_constants.dart` with real credentials** to public repositories
2. The file is already in `.gitignore` - keep it that way!
3. For production apps, consider using environment variables or secure storage
4. Don't share your Client Secret publicly

## ✅ Verification

After setup, you should be able to:
- ✓ Launch the app
- ✓ Sign in with AniList
- ✓ Access your anime/manga lists
- ✓ (Optional) Sync with Supabase if configured

## 🆘 Troubleshooting

### "Invalid Client ID" Error
- Double-check your AniList Client ID is correct
- Ensure you've created an API Client on AniList

### "Invalid Redirect URI" Error
- Make sure the redirect URI in your AniList app settings matches exactly
- For Windows: use `http://localhost:8080/auth`

### Supabase Connection Issues
- Verify your Supabase URL and Anon Key are correct
- Check that you've run the SQL schema
- Supabase is optional - the app works without it

## 📚 Additional Resources

- [AniList API Documentation](https://anilist.gitbook.io/anilist-apiv2-docs/)
- [Supabase Documentation](https://supabase.com/docs)
- [Project README](README.md)

---

**Need help?** Open an issue on GitHub!
