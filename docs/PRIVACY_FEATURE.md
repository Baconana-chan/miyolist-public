# Privacy Feature

## Overview

MiyoList offers users complete control over their data privacy through a flexible privacy profile system. Users can choose between **Private** and **Public** profiles, each with different capabilities and data storage approaches.

## Profile Types

### 🔒 Private Profile

**Purpose:** Maximum privacy and local-only data storage

**Features:**
- ✅ Full anime and manga list management
- ✅ Local favorites and ratings
- ✅ AniList data sync (view-only)
- ✅ 100% local storage with Hive
- ❌ No cloud synchronization
- ❌ No cross-device sync
- ❌ No social features
- ❌ No community interactions

**Data Storage:**
- All data stored locally using Hive database
- No data sent to Supabase
- Complete offline functionality
- Data only accessible on current device

**Best For:**
- Users who value maximum privacy
- Single-device usage
- Users who don't need cloud backup
- Testing and development

---

### 🌐 Public Profile

**Purpose:** Full features with cloud synchronization

**Features:**
- ✅ Full anime and manga list management
- ✅ Cloud synchronization with Supabase
- ✅ Cross-device data sync
- ✅ Social features (future)
- ✅ Community interactions (future)
- ✅ Public profile sharing (future)
- ✅ Local and cloud storage

**Data Storage:**
- Local storage with Hive (instant access)
- Cloud backup with Supabase (sync across devices)
- Automatic bidirectional sync
- Data accessible from any device

**Best For:**
- Users who want cloud backup
- Multi-device usage (Windows + Android)
- Users who want social features
- Community participation

---

## User Flow

### Initial Selection (First Login)

1. User authenticates with AniList OAuth2
2. **ProfileTypeSelectionPage** appears
3. User sees two cards:
   - **Private Profile** (blue, lock icon)
   - **Public Profile** (red, globe icon)
4. User selects preferred type
5. System saves `UserSettings` to Hive
6. Data sync begins:
   - Private: Local sync only
   - Public: Local + Cloud sync
7. User navigates to main app

### Changing Privacy Settings

Users can change their privacy settings at any time:

1. Open **Profile** page
2. Click **Settings** icon (top right)
3. **PrivacySettingsDialog** opens
4. Toggle between Private/Public
5. Confirm changes

**Important Notes:**
- Switching from Public → Private: Cloud data remains but stops syncing
- Switching from Private → Public: Initiates full cloud sync
- Changes are saved immediately to Hive
- App shows confirmation snackbar

---

## Technical Implementation

### Models

#### UserSettings (Hive TypeId: 3)

```dart
@HiveType(typeId: 3)
class UserSettings extends HiveObject {
  @HiveField(0)
  final bool isPublicProfile;
  
  @HiveField(1)
  final bool enableCloudSync;
  
  @HiveField(2)
  final bool enableSocialFeatures;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final DateTime updatedAt;
}
```

### Services

#### LocalStorageService

**New Methods:**
- `saveUserSettings(UserSettings)` - Save privacy settings
- `getUserSettings()` - Get current settings
- `isPublicProfile()` - Quick check if public
- `isCloudSyncEnabled()` - Quick check if sync enabled

**Hive Box:** `settings_box`

#### SupabaseService

Conditional usage based on `UserSettings.enableCloudSync`:

```dart
if (settings?.enableCloudSync ?? false) {
  await supabaseService.syncUserData(user);
  await supabaseService.syncAnimeList(userId, list);
  // ...
}
```

### UI Components

#### ProfileTypeSelectionPage

- **Location:** `lib/features/auth/presentation/pages/`
- **Purpose:** Initial privacy selection after OAuth
- **Design:** Two-card layout with feature lists
- **Returns:** `UserSettings` object

#### PrivacySettingsDialog

- **Location:** `lib/features/profile/presentation/widgets/`
- **Purpose:** Change privacy settings after initial setup
- **Features:**
  - Radio buttons for Private/Public
  - Switch toggles (disabled for private)
  - Warning dialog when switching to private
  - Cloud sync trigger when switching to public

#### ProfilePage Badge

Shows current privacy status:
- 🔒 **Private Profile** (blue badge)
- 🌐 **Public Profile** (red badge)

Located under username/avatar

---

## Data Flow

### Private Profile Flow

```
AniList OAuth
  ↓
Select Private
  ↓
UserSettings {isPublic: false}
  ↓
Sync AniList → Hive (local only)
  ↓
Main App (local data only)
```

### Public Profile Flow

```
AniList OAuth
  ↓
Select Public
  ↓
UserSettings {isPublic: true, cloudSync: true}
  ↓
Sync AniList → Hive (local)
  ↓
Sync Hive → Supabase (cloud)
  ↓
Main App (local + cloud)
```

### Switching Flow

**Private → Public:**
```
User clicks "Switch to Public"
  ↓
Save UserSettings {isPublic: true}
  ↓
Trigger full cloud sync
  ↓
Upload all local data to Supabase
  ↓
Show success message
```

**Public → Private:**
```
User clicks "Switch to Private"
  ↓
Show warning dialog
  ↓
User confirms
  ↓
Save UserSettings {isPublic: false}
  ↓
Stop cloud sync
  ↓
Show confirmation
  ↓
(Cloud data remains but not updated)
```

---

## Database Schema

### Hive (Local)

**Boxes:**
- `user_box` - User profile (TypeId: 0)
- `anime_list_box` - Anime entries (TypeId: 1)
- `manga_list_box` - Manga entries (TypeId: 2)
- `favorites_box` - Favorites map
- `settings_box` - UserSettings (TypeId: 3) ← **NEW**

### Supabase (Cloud)

**Tables (only for public profiles):**
- `users` - User profiles
- `anime_lists` - Anime list entries
- `manga_lists` - Manga list entries
- `favorites` - User favorites

**Access Control:**
- Only written to if `enableCloudSync = true`
- Data persists even if user switches to private
- Can be re-synced if user switches back to public

---

## Privacy Guarantees

### Private Profile Guarantees

✅ **Local Only:** All data stored exclusively on device
✅ **No Cloud Upload:** Zero data sent to Supabase
✅ **AniList View Only:** Read from AniList but don't push changes
✅ **Offline First:** Full functionality without internet
✅ **Device Isolated:** Data never leaves the device

### Public Profile Guarantees

✅ **Data Encryption:** Supabase RLS policies protect data
✅ **User Control:** Can switch to private anytime
✅ **Data Ownership:** User owns all cloud data
✅ **Sync Transparency:** Clear UI indicators for sync status
✅ **Selective Sharing:** Control what's public (future feature)

---

## Future Enhancements

### Social Features (Public Only)

- [ ] Friend lists and following
- [ ] Comments on lists
- [ ] Recommendations sharing
- [ ] Activity feed
- [ ] Anime clubs/groups
- [ ] Direct messaging

### Privacy Enhancements

- [ ] Granular privacy controls (e.g., public lists but private favorites)
- [ ] Temporary public mode
- [ ] Data export (both profiles)
- [ ] Cloud data deletion (when switching to private)
- [ ] Privacy audit log

### Sync Improvements

- [ ] Conflict resolution UI
- [ ] Manual sync trigger
- [ ] Sync status indicator
- [ ] Selective sync (choose what to sync)
- [ ] Sync history

---

## User Communication

### In-App Messages

**First Login:**
> "Choose your privacy level:
> 
> **Private Profile** - Your data stays on this device only. No cloud sync.
> 
> **Public Profile** - Sync across devices and access social features.
> 
> You can change this later in your profile settings."

**Switching to Private:**
> "Switching to private profile will:
> 
> • Stop cloud synchronization
> • Disable social features
> • Keep data only on this device
> 
> Your existing cloud data will remain but won't be updated.
> 
> Continue?"

**Switching to Public:**
> "Switching to public profile will enable cloud sync and social features. Your local data will be uploaded to the cloud."

---

## Developer Notes

### Adding Privacy-Aware Features

When adding new features, always check privacy settings:

```dart
final settings = localStorageService.getUserSettings();

if (settings?.enableCloudSync ?? false) {
  // Public profile feature
  await supabaseService.syncData();
}

if (settings?.enableSocialFeatures ?? false) {
  // Social feature
  await showComments();
}
```

### Testing

**Test Cases:**
1. ✅ New user selects Private → No cloud sync
2. ✅ New user selects Public → Full cloud sync
3. ✅ Switch Private → Public → Cloud sync triggered
4. ✅ Switch Public → Private → Cloud sync stopped
5. ✅ Public user logs in on new device → Data synced
6. ✅ Private user logs in on new device → Fresh start

### Performance

**Local Storage (Hive):**
- Instant reads/writes
- No network dependency
- Works offline
- Used by both profile types

**Cloud Sync (Supabase):**
- Async background sync
- Only for public profiles
- Handles network failures gracefully
- Queued operations during offline

---

## FAQ

**Q: Can I switch between private and public?**
A: Yes! You can change your privacy settings anytime in your profile.

**Q: What happens to my cloud data when I switch to private?**
A: Your cloud data remains in Supabase but stops updating. If you switch back to public, it will resume syncing.

**Q: Can private profiles use social features?**
A: No, social features require cloud sync and are only available for public profiles.

**Q: Is my data secure?**
A: Yes! Private profiles keep data local-only. Public profiles use Supabase with Row Level Security (RLS) policies.

**Q: Can I export my data?**
A: Currently not available, but planned for future release. Both profile types will support data export.

**Q: Does private profile sync with AniList?**
A: Private profiles can view your AniList data but don't push changes back. Only local storage is updated.

---

## Summary

The privacy feature gives users **complete control** over their data:

- **Private users** get maximum privacy with local-only storage
- **Public users** get full features with cloud sync
- **Easy switching** between modes at any time
- **Clear communication** about what each mode offers
- **Future-proof** design for upcoming social features

This respects user privacy while enabling powerful features for those who want them.
