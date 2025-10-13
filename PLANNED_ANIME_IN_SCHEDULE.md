# 📅 Planned Anime in Airing Schedule

**Date**: October 13, 2025  
**Status**: ✅ Implemented

---

## 🎯 Feature Overview

Аниме из списка "Запланировано" (PLANNING) теперь автоматически появляются в календаре онгоингов за **5 дней** до выхода первого эпизода. Это помогает пользователям не пропустить премьеры запланированных аниме.

---

## 💡 How It Works

### Before
```
Календарь онгоингов показывал только:
✅ CURRENT (Смотрю)
✅ REPEATING (Пересматриваю)
```

### After
```
Календарь онгоингов показывает:
✅ CURRENT (Смотрю) - все эпизоды
✅ REPEATING (Пересматриваю) - все эпизоды
✅ PLANNING (Запланировано) - только первые эпизоды за 5 дней до выхода
```

---

## 🔍 Implementation Details

### AiringScheduleService Changes

**File**: `lib/core/services/airing_schedule_service.dart`

#### 1. GraphQL Query Extended
Добавлен третий запрос для статуса PLANNING:

```dart
planning: MediaListCollection(userId: $userId, type: ANIME, status: PLANNING) {
  lists {
    entries {
      media {
        id
        nextAiringEpisode {
          id
          airingAt
          timeUntilAiring
          episode
        }
        title { romaji english }
        episodes
        coverImage { large }
      }
    }
  }
}
```

#### 2. Smart Filtering Logic
```dart
void processEntries(List<dynamic>? lists, {bool filterByDate = false}) {
  // ...
  
  // Для PLANNING: показываем только если это первый эпизод и выходит в ближайшие 5 дней
  if (filterByDate) {
    if (episode != 1) continue; // Только первый эпизод
    if (airingAt.isAfter(fiveDaysLater)) continue; // Только в ближайшие 5 дней
  }
  
  // ...
}
```

#### 3. Processing All Three Lists
```dart
processEntries(watching);              // CURRENT - без фильтра
processEntries(repeating);             // REPEATING - без фильтра  
processEntries(planning, filterByDate: true); // PLANNING - с фильтром
```

---

## 📋 Filtering Rules for PLANNING

### Condition 1: First Episode Only
```dart
if (episode != 1) continue;
```
- Показываем только эпизод 1
- Остальные эпизоды не показываются (пока аниме в PLANNING)
- **Reason**: После выхода первого эпизода пользователь переместит аниме в "Смотрю"

### Condition 2: Within 5 Days
```dart
final now = DateTime.now();
final fiveDaysLater = now.add(Duration(days: 5));

if (airingAt.isAfter(fiveDaysLater)) continue;
```
- Показываем только если осталось ≤ 5 дней
- **Example timeline**:
  - **Day -6**: Не показываем (слишком рано)
  - **Day -5**: ✅ Показываем
  - **Day -4**: ✅ Показываем
  - **Day -3**: ✅ Показываем
  - **Day -2**: ✅ Показываем
  - **Day -1**: ✅ Показываем
  - **Day 0**: ✅ Показываем (день выхода)

---

## 🎨 User Experience

### Empty State Updated
Added hint in empty state message:

```dart
subtitle: 'Add anime to your "Watching" list to see their airing schedule here.\n\n'
    'Tip: Planned anime will appear 5 days before their first episode airs! 📅',
```

### Visual Examples

#### Case 1: Planned Anime Appears
```
Today: October 13, 2025
Planned Anime: "New Show" - Episode 1 airs on October 17, 2025

Result: ✅ Shows in calendar (4 days until airing)
```

#### Case 2: Planned Anime Too Far
```
Today: October 13, 2025
Planned Anime: "Future Show" - Episode 1 airs on October 25, 2025

Result: ❌ Does not show in calendar (12 days until airing)
```

#### Case 3: Planned Anime - Episode 2
```
Today: October 13, 2025
Planned Anime: "Ongoing Show" - Episode 2 airs on October 15, 2025

Result: ❌ Does not show (not episode 1)
Note: User should move to "Watching" after episode 1
```

---

## 🔄 Duplicate Handling

The service automatically removes duplicates by `mediaId`:

```dart
final seenMediaIds = <int>{};
final uniqueEpisodes = episodes.where((ep) {
  if (seenMediaIds.contains(ep.mediaId)) {
    return false; // Already seen
  }
  seenMediaIds.add(ep.mediaId);
  return true;
}).toList();
```

**Why?** An anime could theoretically be in multiple lists (though unlikely).

---

## 📊 Benefits

### For Users
1. **No Missed Premieres**: Get reminded 5 days before planned anime starts
2. **Better Planning**: See upcoming starts in advance
3. **Less Maintenance**: Don't need to manually check premiere dates
4. **Calendar Organization**: All upcoming content in one place

### For UX
1. **Discovery**: Users see what's starting soon
2. **Engagement**: Reminder to watch planned content
3. **Seamless Transition**: Easy to move from PLANNING → WATCHING after episode 1

---

## 🧪 Testing Scenarios

### Test 1: Planned Anime Within 5 Days
```
Given: Anime "Test Show" in PLANNING
And: Episode 1 airs in 3 days
When: Load airing schedule
Then: "Test Show" appears in calendar
```

### Test 2: Planned Anime Beyond 5 Days
```
Given: Anime "Future Show" in PLANNING
And: Episode 1 airs in 10 days
When: Load airing schedule
Then: "Future Show" does NOT appear in calendar
```

### Test 3: Planned Anime Episode 2
```
Given: Anime "Started Show" in PLANNING
And: Episode 2 airs in 2 days
When: Load airing schedule
Then: "Started Show" does NOT appear (not episode 1)
```

### Test 4: Multiple Lists
```
Given: Anime "Show A" in WATCHING (episode 5 airing)
And: Anime "Show B" in PLANNING (episode 1 in 3 days)
And: Anime "Show C" in REPEATING (episode 10 airing)
When: Load airing schedule
Then: All three shows appear in calendar
```

---

## 🔧 Technical Notes

### Performance
- **Query Cost**: One additional GraphQL query section (PLANNING)
- **Filtering**: Happens in-memory after fetch (negligible performance impact)
- **Network**: Same single request, no extra calls

### Data Flow
```
1. Fetch CURRENT + REPEATING + PLANNING lists
2. Parse all entries
3. Filter PLANNING by episode=1 AND date≤5days
4. Merge all results
5. Remove duplicates by mediaId
6. Sort by airingAt (ascending)
7. Return list
```

### Edge Cases Handled
- ✅ Anime without nextAiringEpisode (skipped)
- ✅ Duplicate mediaId (removed)
- ✅ NULL checks on all fields
- ✅ Missing title data (fallback to "Unknown")

---

## 📝 Documentation Updates

### Files Modified
1. ✅ `lib/core/services/airing_schedule_service.dart`
   - Extended GraphQL query
   - Added filterByDate logic
   - Updated documentation comments

2. ✅ `lib/features/activity/presentation/pages/activity_page.dart`
   - Updated empty state message
   - Added helpful tip about 5-day window

3. ✅ `PLANNED_ANIME_IN_SCHEDULE.md` (this file)
   - Comprehensive feature documentation

---

## 🎯 User Workflow

### Ideal Flow
```
1. User adds anime to PLANNING before it starts
2. 5 days before premiere: Anime appears in calendar 📅
3. User sees countdown timer
4. Day of premiere: User watches episode 1
5. User moves anime to WATCHING
6. Continues to see future episodes in calendar
```

---

## 🚀 Future Enhancements

Possible improvements (not in current scope):

1. **Configurable Window**: Let users choose 3/5/7 days
2. **Notification**: Push notification when planned anime enters 5-day window
3. **Badge**: Visual indicator for "Starting Soon" vs "Ongoing"
4. **Auto-Move**: Option to auto-move to WATCHING after watching episode 1
5. **Custom Filters**: "Show only starting anime" toggle

---

## ✅ Completion Checklist

- [x] GraphQL query extended with PLANNING status
- [x] Filtering logic implemented (episode=1, date≤5days)
- [x] Processing function updated with filterByDate parameter
- [x] Duplicate removal working correctly
- [x] Documentation comments updated
- [x] Empty state message updated with helpful tip
- [x] Code compilation verified (no errors)
- [x] Feature documentation created

---

**Status**: ✅ Ready for production  
**Testing**: Manual testing recommended before release

_Implementation completed: October 13, 2025_
