# Auto-Sync and Sync Cooldown Features

## Overview
Implemented intelligent synchronization system with automatic syncing on modifications and cooldown protection to prevent API spam.

## Implementation Date
December 2024 - v1.1.2

## Features

### 1. Sync Button Cooldown (1 minute)
Prevents manual sync spam by enforcing a 1-minute cooldown between syncs.

**Behavior:**
- Button disabled for 60 seconds after each sync
- Shows remaining seconds in tooltip (e.g., "Wait 45s")
- Visual feedback: grayed out icon when disabled
- Loading spinner animation during sync
- Success/error notifications

**Implementation:**
```dart
static const Duration _syncCooldown = Duration(minutes: 1);
DateTime? _lastSyncTime;
bool _isSyncing = false;

bool _canSync() {
  if (_isSyncing) return false;
  if (_lastSyncTime == null) return true;
  
  final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
  return timeSinceLastSync >= _syncCooldown;
}
```

### 2. Auto-Sync on Modifications (2 minute delay)
Automatically syncs changes after 2 minutes of inactivity following any modification.

**Triggers:**
- After editing an entry (status, score, progress, etc.)
- After deleting an entry
- After adding to favorites (future)

**Behavior:**
- Timer starts after each modification
- Timer resets if another modification occurs
- Syncs silently in background (no notification)
- Cancels if manual sync is performed
- Respects cooldown period

**Implementation:**
```dart
static const Duration _autoSyncDelay = Duration(minutes: 2);
DateTime? _lastModificationTime;
Timer? _autoSyncTimer;

void _markAsModified() {
  _lastModificationTime = DateTime.now();
  
  // Cancel existing timer
  _autoSyncTimer?.cancel();
  
  // Start new auto-sync timer (2 minutes)
  _autoSyncTimer = Timer(_autoSyncDelay, () {
    if (_lastModificationTime != null) {
      _syncWithAniList(isAutoSync: true);
    }
  });
}
```

### 3. Background Sync on App Pause
Syncs pending changes when app goes to background or becomes inactive.

**Lifecycle Events:**
- `AppLifecycleState.paused` - app minimized
- `AppLifecycleState.inactive` - app losing focus

**Behavior:**
- Checks for pending modifications
- Performs silent sync before app closes
- No user notification
- Best-effort (non-blocking)

**Implementation:**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);
  
  // Sync when app goes to background
  if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
    if (_lastModificationTime != null) {
      _syncWithAniList(isAutoSync: true);
    }
  }
}
```

## User Experience

### Manual Sync
1. User clicks sync button
2. Button shows loading spinner
3. Sync completes → green success notification
4. Button disabled for 1 minute
5. Tooltip shows countdown: "Wait 45s"
6. After 1 minute → button re-enabled

### Auto-Sync Flow
1. User edits entry → saves
2. Timer starts (2 minutes)
3. User makes another edit → timer resets
4. User idle for 2 minutes → automatic sync
5. Silent sync (no notification)
6. Modifications cleared

### Background Sync
1. User edits multiple entries
2. User minimizes app (swipes away)
3. App detects lifecycle change
4. Pending changes sync before pause
5. App fully paused after sync

## Technical Details

### State Management
```dart
// Sync state
bool _isSyncing = false;
DateTime? _lastSyncTime;
DateTime? _lastModificationTime;
Timer? _autoSyncTimer;

// Lifecycle observer
class _AnimeListPageState extends State<AnimeListPage> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
```

### Sync Methods
```dart
// Public method (manual sync with cooldown check)
Future<void> _syncData() async {
  if (!_canSync()) {
    final secondsRemaining = _getSecondsUntilNextSync();
    // Show cooldown message
    return;
  }
  await _syncWithAniList(isAutoSync: false);
}

// Private method (actual sync logic)
Future<void> _syncWithAniList({required bool isAutoSync}) async {
  if (_isSyncing) return;
  
  setState(() => _isSyncing = true);
  
  try {
    // Get user
    final user = widget.localStorageService.getUser();
    
    // Sync if cloud enabled
    if (widget.localStorageService.isCloudSyncEnabled()) {
      final animeJson = _animeList.map((e) => e.toSupabaseJson()).toList();
      final mangaJson = _mangaList.map((e) => e.toSupabaseJson()).toList();
      
      await widget.supabaseService.syncAnimeList(user.id, animeJson);
      await widget.supabaseService.syncMangaList(user.id, mangaJson);
    }
    
    _lastSyncTime = DateTime.now();
    _lastModificationTime = null;
    _autoSyncTimer?.cancel();
    
    // Show success (manual sync only)
    if (!isAutoSync) {
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  } catch (e) {
    // Handle error
  } finally {
    setState(() => _isSyncing = false);
  }
}
```

## UI Components

### Sync Button States
1. **Idle (enabled)**: Normal sync icon
2. **Syncing**: Circular progress indicator (20x20)
3. **Cooldown**: Grayed icon, disabled button
4. **Error**: Red notification, button re-enabled

### Visual Feedback
```dart
IconButton(
  icon: _isSyncing
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
      : Icon(
          Icons.sync,
          color: _canSync() ? null : Colors.grey,
        ),
  onPressed: _canSync() && !_isSyncing ? _syncData : null,
  tooltip: _isSyncing
      ? 'Syncing...'
      : _canSync()
          ? 'Sync with AniList'
          : 'Wait ${_getSecondsUntilNextSync()}s',
)
```

## Configuration

### Timing Constants
```dart
static const Duration _syncCooldown = Duration(minutes: 1);  // Manual sync cooldown
static const Duration _autoSyncDelay = Duration(minutes: 2);  // Auto-sync delay
```

### Customization
To change timing, modify constants:
```dart
// Shorter cooldown (30 seconds)
static const Duration _syncCooldown = Duration(seconds: 30);

// Longer auto-sync delay (5 minutes)
static const Duration _autoSyncDelay = Duration(minutes: 5);
```

## Edge Cases Handled

### 1. Multiple Rapid Edits
- ✅ Timer resets on each edit
- ✅ Only one auto-sync after final edit
- ✅ No duplicate syncs

### 2. Manual Sync During Auto-Sync Timer
- ✅ Auto-sync timer cancelled
- ✅ Manual sync takes precedence
- ✅ Cooldown applies to both

### 3. App Backgrounding During Cooldown
- ✅ Background sync still triggers
- ✅ Cooldown only affects manual button
- ✅ Pending modifications sync regardless

### 4. Network Errors
- ✅ Silent failure for auto-sync
- ✅ Error notification for manual sync
- ✅ Modifications remain pending
- ✅ Next sync will retry

### 5. App Closure
- ✅ Timer cancelled in dispose()
- ✅ Background sync in lifecycle observer
- ✅ No memory leaks
- ✅ Clean shutdown

## Performance Considerations

### Memory
- Single Timer instance (cancelled and recreated)
- DateTime objects (minimal memory)
- No memory leaks (proper dispose)

### Battery
- Timer doesn't wake device
- Background sync is best-effort
- No polling or constant checks

### Network
- Cooldown prevents API spam
- Auto-sync batches changes
- Silent failures for non-critical sync

## Testing Scenarios

### Manual Sync
- [ ] Button disabled during sync
- [ ] Cooldown enforced after sync
- [ ] Tooltip shows countdown
- [ ] Success notification appears
- [ ] Error handled gracefully

### Auto-Sync
- [ ] Timer starts after edit
- [ ] Timer resets on new edit
- [ ] Syncs after 2 minutes idle
- [ ] No notification shown
- [ ] Cancels on manual sync

### Background Sync
- [ ] Syncs when app minimized
- [ ] Syncs when app loses focus
- [ ] No sync if no modifications
- [ ] Silent operation
- [ ] Doesn't block app pause

### Cooldown
- [ ] 60 second cooldown works
- [ ] Countdown accurate
- [ ] Button re-enables after cooldown
- [ ] Visual feedback correct
- [ ] Doesn't affect auto-sync

## Future Enhancements
- [ ] Configurable timing in settings
- [ ] Sync queue for offline changes
- [ ] Retry logic with exponential backoff
- [ ] Sync status indicator (last synced time)
- [ ] Manual "Sync Now" override (ignore cooldown)
- [ ] Selective sync (anime only, manga only)
- [ ] Conflict resolution for concurrent edits

## Known Limitations
1. Background sync best-effort (may not complete if app killed)
2. No persistent queue (changes lost if sync fails and app closes)
3. No conflict detection (last write wins)
4. Desktop/Web: lifecycle events may differ from mobile
5. No sync progress indicator for large lists

## Platform Compatibility
- ✅ **Android**: Full support (lifecycle events work)
- ✅ **iOS**: Full support (lifecycle events work)
- ⚠️ **Desktop**: Limited (app pause detection may differ)
- ⚠️ **Web**: Limited (no true backgrounding)

## Dependencies
- `dart:async` - Timer functionality
- `WidgetsBindingObserver` - Lifecycle monitoring
- No external packages required

## Security
- Syncs only if cloud sync enabled
- Respects user privacy settings
- No data sent if private profile
- Secure Supabase connection
