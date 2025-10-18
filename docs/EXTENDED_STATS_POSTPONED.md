# Extended Statistics Postponed to v1.2.0+

## 📊 **Decision Summary**

**Date:** October 15, 2025  
**Version:** v1.1.0 "Botan (牡丹)"  
**Status:** POSTPONED to v1.2.0+

---

## 🎯 **Features Postponed**

### 1. Studio Distribution Statistics
- **Feature**: Top studios pie chart and list
- **Complexity**: High - requires storing studio data locally
- **Effort**: 2-3 days of development

### 2. Voice Actors Statistics  
- **Feature**: Top seiyu with character lists
- **Complexity**: Very High - requires character/VA relationship data
- **Effort**: 3-4 days of development

### 3. Staff Statistics
- **Feature**: Top staff (directors, writers, composers) with role filtering
- **Complexity**: Very High - requires staff/role relationship data
- **Effort**: 3-4 days of development

**Total Estimated Effort:** 8-11 days

---

## 🤔 **Why Postpone?**

### Technical Challenges

1. **Data Model Limitations**
   - Current `MediaListEntry` model doesn't store extended details
   - Studios, characters, voice actors, and staff data not persisted locally
   - Only available via AniList GraphQL API (slow, rate-limited)

2. **GraphQL API Issues**
   - Request timeout (30 seconds) with large lists
   - Rate limiting (30 requests/minute)
   - Large payload size (studios + characters + staff for all anime)
   - Unreliable for real-time computation

3. **Architecture Requirements**
   ```dart
   // Current Model (v1.1.0)
   class MediaListEntry {
     int mediaId;
     String mediaTitle;
     String? format;  // ✅ Available
     List<String> genres;  // ✅ Available
     // ❌ NO studios data
     // ❌ NO characters data
     // ❌ NO voice actors data
     // ❌ NO staff data
   }
   
   // Required Model (v1.2.0+)
   class MediaListEntry {
     // ... existing fields
     List<Studio> studios;  // 🔄 NEW
     List<Character> characters;  // 🔄 NEW
     List<VoiceActor> voiceActors;  // 🔄 NEW
     List<Staff> staff;  // 🔄 NEW
   }
   ```

4. **Sync Complexity**
   - Current sync only handles basic media info
   - Extended sync would need to:
     - Fetch studios for each anime (N queries)
     - Fetch characters + VA for each anime (N queries)
     - Fetch staff for each anime (N queries)
   - Total: **3N additional GraphQL queries** (where N = number of anime)
   - For a user with 200 anime: 600 additional queries! 😱

### User Experience Concerns

1. **Loading Times**
   - Current implementation: 30+ second timeout
   - With 200 anime: Could take 5-10 minutes to load
   - Poor UX, app appears frozen

2. **Battery & Data Usage**
   - Massive GraphQL queries drain battery
   - Large data downloads (images, names, relationships)
   - Not suitable for mobile devices

3. **Storage Requirements**
   - Studios/Characters/VA/Staff data would significantly increase database size
   - ~100KB additional data per anime
   - 200 anime = 20MB+ additional storage

---

## ✅ **Current Implementation (v1.1.0)**

### Placeholder Tabs
We've created placeholder tabs with "Coming Soon" messages:

```dart
Widget _buildStudiosTab() {
  return Center(
    child: Column(
      children: [
        Icon(Icons.business, size: 64),
        Text('Studios statistics coming in v1.2.0'),
        Text('This feature requires enhanced data storage'),
      ],
    ),
  );
}

Widget _buildVoiceActorsTab() { /* Similar placeholder */ }
Widget _buildStaffTab() { /* Similar placeholder */ }
```

### Benefits of Placeholders
- ✅ Shows users what's coming
- ✅ Doesn't block v1.1.0 release
- ✅ Sets expectations for future features
- ✅ Clean UI without broken functionality

---

## 🚀 **Roadmap for v1.2.0+**

### Phase 1: Enhanced Data Model (v1.2.0)
**Effort:** 1-2 weeks

1. **Extend MediaListEntry Model**
   ```dart
   @HiveType(typeId: 1)
   class MediaListEntry extends HiveObject {
     // ... existing fields
     
     @HiveField(20)
     List<Studio>? studios;
     
     @HiveField(21)
     List<Character>? characters;
     
     @HiveField(22)
     List<VoiceActor>? voiceActors;
     
     @HiveField(23)
     List<Staff>? staff;
   }
   ```

2. **Create New Hive Models**
   ```dart
   @HiveType(typeId: 30)
   class Studio {
     @HiveField(0)
     int id;
     
     @HiveField(1)
     String name;
     
     @HiveField(2)
     bool isMain;
   }
   
   @HiveType(typeId: 31)
   class Character {
     @HiveField(0)
     int id;
     
     @HiveField(1)
     String name;
     
     @HiveField(2)
     String? image;
     
     @HiveField(3)
     String role;  // MAIN, SUPPORTING, BACKGROUND
     
     @HiveField(4)
     List<VoiceActor> voiceActors;
   }
   
   @HiveType(typeId: 32)
   class VoiceActor {
     @HiveField(0)
     int id;
     
     @HiveField(1)
     String name;
     
     @HiveField(2)
     String? image;
     
     @HiveField(3)
     String language;  // JAPANESE, ENGLISH, etc.
   }
   
   @HiveType(typeId: 33)
   class Staff {
     @HiveField(0)
     int id;
     
     @HiveField(1)
     String name;
     
     @HiveField(2)
     String? image;
     
     @HiveField(3)
     String role;  // Director, Music, Original Creator, etc.
   }
   ```

3. **Regenerate Hive Adapters**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

### Phase 2: Intelligent Sync (v1.2.0)
**Effort:** 2-3 weeks

1. **Batch GraphQL Queries**
   - Fetch extended data for 10 anime at a time
   - Show progress indicator during sync
   - Allow cancellation

2. **Incremental Sync**
   - Only fetch extended data for new/updated entries
   - Skip if already stored locally
   - Lazy loading on demand

3. **Background Sync**
   - Sync extended data in background (WorkManager)
   - Low priority, doesn't block UI
   - Retry on failure with exponential backoff

4. **Cache Strategy**
   - 30-day cache for studios/characters/VA/staff
   - Auto-refresh if data is stale
   - Manual "Refresh Extended Stats" button

### Phase 3: Statistics UI (v1.2.0)
**Effort:** 1-2 weeks

1. **Studios Tab**
   - Pie chart with top 10-15 studios
   - Full list with anime counts
   - Tap to see anime list

2. **Voice Actors Tab**
   - Top 50 VA ranked by anime count
   - Expandable character lists
   - Character role filtering
   - Tap VA to see all anime

3. **Staff Tab**
   - Top 50 staff ranked by anime count
   - Role filtering (Director, Music, etc.)
   - Tap staff to see all anime

### Phase 4: Testing & Polish (v1.2.1)
**Effort:** 1 week

- Unit tests for new models
- Integration tests for sync
- Performance optimization
- Memory leak checks
- Battery drain testing

**Total Estimated Timeline:** 5-8 weeks for complete implementation

---

## 📈 **Alternatives Considered**

### Option 1: On-Demand API Calls (REJECTED)
- **Pros**: No storage overhead
- **Cons**: Slow, rate-limited, poor UX
- **Decision**: Too slow for good UX

### Option 2: Server-Side Aggregation (REJECTED)
- **Pros**: Fast, pre-computed
- **Cons**: Requires backend server, hosting costs
- **Decision**: Adds complexity, not self-hosted

### Option 3: Local Computation with Minimal Data (CHOSEN for v1.2.0)
- **Pros**: Fast, offline-first, privacy-friendly
- **Cons**: Storage overhead, complex sync
- **Decision**: Best balance of performance and UX

---

## 🎯 **v1.1.0 Focus**

Instead of extended statistics, we're focusing on:

### ✅ Implemented Features
1. **Activity Tracking** with GitHub-style heatmap ✅
2. **Genre Distribution** pie chart ✅
3. **Score Distribution** histogram ✅
4. **Format Distribution** pie chart ✅
5. **Period Filters** (7/30/90/365 days) ✅
6. **Export/Import** functionality ✅
7. **OAuth UX Improvements** ✅

### ⏳ Remaining v1.1.0 Features
1. **Watching History Timeline** (monthly/yearly view)
2. **Interactive Tooltips** on hover
3. **Smooth Animations** for charts
4. **Export Charts as Images** (PNG/SVG)

These features are **lighter, faster, and don't require architecture changes**.

---

## 📝 **User Communication**

### In-App Message
```
📊 Extended Statistics (Studios, Voice Actors, Staff)

These features are coming in v1.2.0!

Why wait?
- Requires enhanced local storage
- Better performance & offline support
- More reliable than API-only approach

Current tabs show placeholders to give you a preview.

Stay tuned! 🚀
```

### Release Notes
```markdown
## v1.1.0 "Botan (牡丹)" - Activity & Charts

### ✨ New Features
- Activity tracking with GitHub-style heatmap
- Genre, Score, and Format distribution charts
- Period filters and export functionality
- OAuth authentication improvements

### 📌 Coming Soon (v1.2.0+)
- Extended statistics (Studios, Voice Actors, Staff)
- Watching history timeline
- Interactive chart tooltips
- Export charts as images

These features require architectural changes and will be 
implemented in v1.2.0 for better performance and UX.
```

---

## 🎉 **Summary**

**Decision:** Postpone Studios/VA/Staff statistics to v1.2.0+  
**Reason:** Requires significant architecture changes, would delay v1.1.0 release  
**Impact:** Minimal - placeholder tabs show "Coming Soon" message  
**Benefit:** v1.1.0 releases on time with solid, fast features  
**Timeline:** Extended stats will be fully implemented in v1.2.0 (5-8 weeks after v1.1.0)

**v1.1.0 Status:** ✅ Ready for release with Activity Tracking + Charts  
**v1.2.0 Status:** 📅 Planned for Q1 2026 with Extended Statistics

---

**Author:** VIC  
**Date:** October 15, 2025  
**Version:** v1.1.0 "Botan (牡丹)"
