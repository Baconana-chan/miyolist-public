# Privacy Feature - Visual Guide

## 🎯 Profile Type Comparison

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PROFILE TYPES                                │
├─────────────────────────────────┬───────────────────────────────────┤
│     🔒 PRIVATE PROFILE          │      🌐 PUBLIC PROFILE            │
├─────────────────────────────────┼───────────────────────────────────┤
│ Data Storage                     │ Data Storage                      │
│  • Local only (Hive)            │  • Local (Hive) + Cloud (Supabase)│
│  • No cloud backup              │  • Automatic cloud backup         │
│  • Single device                │  • Multi-device sync              │
├─────────────────────────────────┼───────────────────────────────────┤
│ Features                         │ Features                          │
│  ✓ List management              │  ✓ List management                │
│  ✓ Offline access               │  ✓ Offline access                 │
│  ✓ Local favorites              │  ✓ Cloud sync                     │
│  ✗ Cloud sync                   │  ✓ Cross-device sync              │
│  ✗ Social features              │  ✓ Social features (soon)         │
├─────────────────────────────────┼───────────────────────────────────┤
│ Best For                         │ Best For                          │
│  • Maximum privacy              │  • Multi-device users             │
│  • Single device usage          │  • Cloud backup needs             │
│  • Offline-first                │  • Social interactions            │
│  • No account needed            │  • Community features             │
└─────────────────────────────────┴───────────────────────────────────┘
```

---

## 🔄 User Flow Diagram

### First Login Flow

```
┌─────────────┐
│  App Start  │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  Login Screen   │
│                 │
│ [Login Button]  │
└──────┬──────────┘
       │ Click
       ▼
┌──────────────────┐
│ AniList OAuth2   │
│                  │
│ (Browser Opens)  │
└──────┬───────────┘
       │ Auth Success
       ▼
┌───────────────────────────────────┐
│   Profile Type Selection          │
│                                   │
│  ┌──────────┐    ┌──────────┐   │
│  │🔒PRIVATE │    │🌐PUBLIC  │   │
│  │          │    │          │   │
│  │Local Only│    │Cloud Sync│   │
│  └──────────┘    └──────────┘   │
└───────┬───────────────┬───────────┘
        │               │
Private │               │ Public
        ▼               ▼
┌──────────────┐  ┌─────────────────┐
│Save Settings │  │  Save Settings  │
│{private:true}│  │  {public:true}  │
└──────┬───────┘  └────────┬────────┘
       │                   │
       ▼                   ▼
┌──────────────┐  ┌─────────────────┐
│Sync AniList  │  │  Sync AniList   │
│     ↓        │  │       ↓         │
│  To Hive     │  │   To Hive       │
│              │  │       ↓         │
│              │  │  To Supabase    │
└──────┬───────┘  └────────┬────────┘
       │                   │
       └─────────┬─────────┘
                 │
                 ▼
         ┌──────────────┐
         │  Main App    │
         │ (List View)  │
         └──────────────┘
```

---

## 🔧 Settings Change Flow

### Switching Profile Types

```
┌─────────────────┐
│  Profile Page   │
│                 │
│  👤 User Name   │
│  🔒 Private     │ ← Badge shows current type
│                 │
│      [⚙️ Settings] ← Click
└────────┬────────┘
         │
         ▼
┌──────────────────────────────┐
│  Privacy Settings Dialog     │
│                              │
│  Profile Type:               │
│  ⚪ Private (local only)     │
│  ⚫ Public (cloud sync)  ← Select
│                              │
│  Features:                   │
│  ☑ Cloud Sync                │
│  ☑ Social Features           │
│                              │
│      [Cancel]  [Save]        │
└────────┬─────────────────────┘
         │ Save
         ▼
    ┌─────────┐
    │Was Public│
    │  before? │
    └────┬────┬┘
         │    │
    Yes  │    │ No
         ▼    ▼
┌───────────────┐  ┌──────────────┐
│Show Warning:  │  │Enable Cloud  │
│               │  │Sync & Upload │
│"Stop cloud    │  │All Data      │
│ sync?"        │  └──────┬───────┘
│               │         │
│[Cancel][OK]   │         │
└───┬───────┬───┘         │
    │       │             │
Cancel│     │Confirm      │
    │       ▼             │
    │  ┌─────────────┐   │
    │  │Stop Cloud   │   │
    │  │Sync         │   │
    │  └──────┬──────┘   │
    │         │           │
    └─────────┴───────────┘
              │
              ▼
      ┌──────────────┐
      │Update Badge  │
      │& Show Toast  │
      └──────────────┘
```

---

## 💾 Data Storage Architecture

### Private Profile Data Flow

```
┌──────────────┐
│   AniList    │
│   GraphQL    │
└──────┬───────┘
       │ Read Only
       ↓
┌──────────────┐
│     App      │
│  (Flutter)   │
└──────┬───────┘
       │
       ↓ Write/Read
┌──────────────┐
│     Hive     │
│  (Local DB)  │
└──────────────┘
       ↓
  User's Device
  (No Cloud!)
```

### Public Profile Data Flow

```
┌──────────────┐
│   AniList    │
│   GraphQL    │
└──────┬───────┘
       │ Read/Write
       ↓
┌──────────────┐
│     App      │
│  (Flutter)   │
└───┬──────┬───┘
    │      │
    ↓      ↓
┌────────┐ ┌────────────┐
│  Hive  │ │  Supabase  │
│ (Local)│ │  (Cloud)   │
└────────┘ └────────────┘
    ↑           ↑
    │           │
User's Device   Cloud Backup
(Fast Access)   (Multi-Device)
```

---

## 🎨 UI Screenshots (Text-Based)

### Profile Type Selection Screen

```
┌──────────────────────────────────────────────────┐
│  ← MiyoList                               [✕]   │
├──────────────────────────────────────────────────┤
│                                                  │
│        Choose Your Privacy Level                 │
│                                                  │
│  ┌────────────────────┐  ┌────────────────────┐│
│  │   🔒                │  │   🌐                ││
│  │                     │  │                     ││
│  │  Private Profile    │  │  Public Profile     ││
│  │                     │  │                     ││
│  │  Local storage only │  │  Cloud sync enabled ││
│  │                     │  │                     ││
│  │  ✓ List management  │  │  ✓ List management  ││
│  │  ✓ Offline access   │  │  ✓ Cloud sync       ││
│  │  ✗ Cloud sync       │  │  ✓ Multi-device     ││
│  │  ✗ Social features  │  │  ✓ Social features  ││
│  │                     │  │                     ││
│  │    [  Select  ]     │  │    [  Select  ]     ││
│  └────────────────────┘  └────────────────────┘│
│                                                  │
│  You can change this setting later in profile   │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Profile Page with Privacy Badge

```
┌──────────────────────────────────────────────────┐
│  ← Profile                        ⚙️  🚪         │
├──────────────────────────────────────────────────┤
│                                                  │
│  ┌─────────────────────────────────────────────┐│
│  │                                              ││
│  │            [Banner Image]                    ││
│  │                                              ││
│  └─────────────────────────────────────────────┘│
│                                                  │
│  ┌────┐                                          │
│  │ 👤 │  UserName                                │
│  │    │  ┌────────────────┐                     │
│  └────┘  │🔒Private Profile│  ← Privacy Badge   │
│           └────────────────┘                     │
│                                                  │
│  About                                           │
│  ┌─────────────────────────────────────────────┐│
│  │ Anime and manga enthusiast...               ││
│  └─────────────────────────────────────────────┘│
│                                                  │
│  Favorites                                       │
│  ┌─────┐ ┌─────┐ ┌─────┐                       │
│  │█████│ │█████│ │█████│                       │
│  │█████│ │█████│ │█████│                       │
│  └─────┘ └─────┘ └─────┘                       │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Privacy Settings Dialog

```
┌──────────────────────────────────────────┐
│  🔒 Privacy Settings              [✕]   │
├──────────────────────────────────────────┤
│                                          │
│  Profile Type                            │
│                                          │
│  🔒 ⚪ Private Profile                   │
│     Local only, no cloud sync            │
│                                          │
│  🌐 ⚫ Public Profile                    │
│     Cloud sync and social features       │
│                                          │
│  ────────────────────────────────────    │
│                                          │
│  Features                                │
│                                          │
│  ☁️  ☑ Cloud Sync                        │
│      Sync data across devices            │
│                                          │
│  👥  ☑ Social Features                   │
│      Interact with community             │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ ℹ️  Private profiles cannot use    │ │
│  │    cloud sync or social features   │ │
│  └────────────────────────────────────┘ │
│                                          │
│          [Cancel]  [  Save  ]            │
└──────────────────────────────────────────┘
```

---

## 📊 Feature Matrix

```
┌────────────────────────────┬──────────┬──────────┐
│         Feature            │ Private  │  Public  │
├────────────────────────────┼──────────┼──────────┤
│ List Management            │    ✓     │    ✓     │
│ Local Storage (Hive)       │    ✓     │    ✓     │
│ Cloud Storage (Supabase)   │    ✗     │    ✓     │
│ Cross-Device Sync          │    ✗     │    ✓     │
│ Offline Access             │    ✓     │    ✓     │
│ AniList OAuth              │    ✓     │    ✓     │
│ Profile Viewing            │    ✓     │    ✓     │
│ Favorites                  │    ✓     │    ✓     │
│ Statistics                 │    ✓     │    ✓     │
│ Social Features            │    ✗     │   Soon   │
│ Comments                   │    ✗     │   Soon   │
│ Friends/Following          │    ✗     │   Soon   │
│ Activity Feed              │    ✗     │   Soon   │
│ Data Export                │  Planned │  Planned │
│ Privacy Controls           │    ✓     │    ✓     │
└────────────────────────────┴──────────┴──────────┘
```

---

## 🔐 Security & Privacy Flow

```
User Data Journey
═════════════════

PRIVATE PROFILE:
┌────────┐      ┌────────┐      ┌────────┐
│AniList │ ───> │  App   │ ───> │  Hive  │
│        │ Read │        │ Save │ Local  │
└────────┘      └────────┘      └────────┘
                    │
                    ▼
              ┌──────────┐
              │ NO CLOUD │
              │   EVER   │
              └──────────┘

PUBLIC PROFILE:
┌────────┐      ┌────────┐      ┌────────┐
│AniList │ <──> │  App   │ ───> │  Hive  │
│        │R/W   │        │ Save │ Local  │
└────────┘      └───┬────┘      └────────┘
                    │
                    ↓ Sync
              ┌──────────┐
              │ Supabase │
              │  Cloud   │
              └──────────┘
                    │
              Row Level Security
              User Owns Data
```

---

## 🎯 Design Decisions

### Why Two Profile Types?

```
┌──────────────────────────────────────────────┐
│  Design Philosophy                           │
├──────────────────────────────────────────────┤
│                                              │
│  Privacy First                               │
│  ├─ Users should have control               │
│  ├─ Default is explicit choice              │
│  └─ No hidden cloud uploads                 │
│                                              │
│  Feature Flexibility                         │
│  ├─ Private: Maximum privacy                │
│  ├─ Public: Maximum features                │
│  └─ Easy switching                           │
│                                              │
│  User Trust                                  │
│  ├─ Transparent data handling               │
│  ├─ Clear communication                      │
│  └─ Respect user wishes                      │
│                                              │
│  Future Growth                               │
│  ├─ Foundation for social features          │
│  ├─ Scalable architecture                    │
│  └─ Community building                       │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 📈 Usage Statistics (Future)

```
┌─────────────────────────────────────────┐
│  Analytics Dashboard (Planned)          │
├─────────────────────────────────────────┤
│                                         │
│  Profile Type Distribution              │
│  ┌────────┬──────────────────┐         │
│  │Private │████████░░ 43%    │         │
│  │Public  │████████████ 57%  │         │
│  └────────┴──────────────────┘         │
│                                         │
│  Feature Usage (Public Only)            │
│  ┌───────────┬─────────────────┐       │
│  │Cloud Sync │███████████ 98%  │       │
│  │Social     │████░░░░░░░ 35%  │       │
│  └───────────┴─────────────────┘       │
│                                         │
│  Switching Behavior                     │
│  Private → Public:  12%                 │
│  Public → Private:   3%                 │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🚀 Quick Reference

### For Developers

**Check Profile Type:**
```dart
final settings = localStorageService.getUserSettings();
if (settings?.isPublicProfile ?? false) {
  // Public profile - use cloud
} else {
  // Private profile - local only
}
```

**Check Cloud Sync:**
```dart
if (localStorageService.isCloudSyncEnabled()) {
  await supabaseService.syncData();
}
```

### For Users

**Want Maximum Privacy?**
→ Choose Private Profile 🔒

**Want Cloud Backup?**
→ Choose Public Profile 🌐

**Change Your Mind?**
→ Settings → Privacy Settings

---

**End of Visual Guide**
