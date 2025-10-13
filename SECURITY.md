# 🛡️ Security Guidelines for Contributors

## 🔐 Protecting Sensitive Data

This repository has been cleaned of sensitive data. If you're contributing, please follow these guidelines:

## ⛔ Never Commit

### API Keys & Secrets
- ❌ AniList Client ID
- ❌ AniList Client Secret  
- ❌ Supabase Project URL
- ❌ Supabase Anon/Public Key
- ❌ Any other API keys or tokens

### Personal Data
- ❌ User IDs
- ❌ Access tokens
- ❌ Email addresses
- ❌ Real user data in SQL files

### Environment Files
- ❌ `.env` files
- ❌ `.env.local` files
- ❌ Any file containing real credentials

## ✅ What's Safe to Commit

### Code & Schema
- ✅ Source code (Dart files)
- ✅ SQL schema (structure only, no data)
- ✅ Configuration templates (with placeholders)
- ✅ Documentation

### Example Files
- ✅ `app_constants.dart.example` (with placeholders)
- ✅ `.env.example` (with placeholders)
- ✅ Documentation with example/placeholder values

## 🔧 Setup Your Local Environment

### 1. Copy the Example File

```bash
cp lib/core/constants/app_constants.dart.example lib/core/constants/app_constants.dart
```

### 2. Add Your Credentials

Edit `app_constants.dart` and replace placeholders with your real credentials.

### 3. Verify .gitignore

The file `lib/core/constants/app_constants.dart` should be listed in `.gitignore`:

```gitignore
# Sensitive data - DO NOT COMMIT
lib/core/constants/app_constants.dart
```

## 🚨 Before Committing

### Run This Checklist

```bash
# 1. Check what you're about to commit
git status

# 2. Review the diff
git diff

# 3. Make sure no secrets are included
git diff | grep -i "secret\|token\|key\|password"

# 4. Verify app_constants.dart is NOT staged
git status | grep app_constants.dart
# Should see: nothing or "modified (not staged)"
```

## 🔍 If You Accidentally Commit Secrets

### Immediate Actions

1. **Don't push!** If you haven't pushed yet:
   ```bash
   git reset --soft HEAD~1
   ```

2. **If you've already pushed:**
   - Immediately revoke/regenerate all exposed credentials
   - Contact repository maintainers
   - Consider using `git filter-branch` or BFG Repo-Cleaner

### Regenerate Credentials

- **AniList**: Delete and recreate your OAuth app at https://anilist.co/settings/developer
- **Supabase**: Reset your project keys in Project Settings → API

## 📝 Testing Without Real Credentials

### Use Mock Services

For unit tests, use mocked services:

```dart
// ✅ Good - Using mocks
final mockService = MockAniListService();
when(mockService.getUser()).thenReturn(mockUser);

// ❌ Bad - Using real credentials in tests
final service = AniListService(clientId: '12345', clientSecret: 'xyz');
```

### Environment Variables (Advanced)

For CI/CD pipelines, use GitHub Secrets or environment variables:

```dart
static String get anilistClientId => 
    Platform.environment['ANILIST_CLIENT_ID'] ?? 'YOUR_ANILIST_CLIENT_ID';
```

## 🤝 Contributing

1. Fork the repository
2. Set up your local credentials (don't commit them!)
3. Make your changes
4. Test thoroughly
5. Submit a pull request
6. Ensure no secrets are in your PR

## 📚 Additional Resources

- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Git Secrets Tool](https://github.com/awslabs/git-secrets)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

---

**Remember**: Once a secret is pushed to GitHub, consider it compromised and regenerate it immediately!
