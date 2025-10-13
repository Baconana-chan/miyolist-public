# 🚀 Post-Release Features Expansion

**Date**: October 13, 2025  
**Updated**: docs/TODO.md with new post-release features

---

## ✨ New Features Added

### 1. User Experience
- **Battery Saver Mode** (v1.2.0+)
  - Reduce animations, auto-refresh, image quality
  - Auto-enable when battery low (<20%)
  - Battery usage statistics

- **Voice Commands & Accessibility** (v1.3.0+)
  - Voice navigation and control
  - Add/update entries by voice
  - Screen reader optimization
  - High contrast mode
  - Помощь для слабовидящих пользователей

### 2. Media & Entertainment
- **Watch Party / Watch Together** (v1.4.0+)
  - Synchronized playback across devices
  - Real-time chat during watching
  - Up to 10 participants
  - Voice chat integration
  - Расширение для просмотра с друзьями

- **Streaming Service Integration** (v1.2.0+)
  - Direct links to episodes (Crunchyroll, Netflix, etc.)
  - "Watch Now" buttons
  - Free episode notifications
  - Regional availability check
  - Legal streaming links only

### 3. Social Features
- **Shared Lists with Friends** (v1.4.0+)
  - Collaborative list management
  - Real-time updates
  - Vote on what to watch next
  - Permission levels
  - Совместные списки с друзьями

- **Leaderboards & Rankings** (v1.3.0+)
  - Global and friend leaderboards
  - Monthly/yearly rankings
  - Achievement rankings
  - Custom challenges
  - Таблицы лидеров

### 4. Gamification
- **Achievements & Milestones** (v1.3.0+)
  - Badge and trophy system
  - Milestones (100/500/1000 anime)
  - Genre master badges
  - AniList integration via profile description
  - Достижения за действия

- **Watch Calendar & Planning** (v1.3.0+)
  - Plan watch schedule
  - Calendar view with reminders
  - Integration with airing schedule
  - Export to Google Calendar
  - Календарь планов на просмотр

### 5. Third-Party Integrations
- **MyAnimeList (MAL) Integration** (v1.3.0+)
  - Two-way sync (import/export)
  - Automatic synchronization
  - Conflict resolution
  - Score conversion (10-point ↔ 100-point)
  - Интеграция с MAL (как в README)

- **Kitsu Integration** (v1.4.0+)
  - Import/export Kitsu library
  - Cross-platform sync

- **Trakt Integration** (v1.5.0+)
  - Universal media tracking

---

## 📋 Feature Organization

Features are now organized into logical sections:

### User Experience (Comfort & Accessibility)
- Battery saver mode
- Voice commands
- Custom themes
- Widgets

### Media & Entertainment (Watching Experience)
- In-app trailer viewer
- Local media player
- Watch party
- Streaming service integration
- OP/ED themes

### Social Features (Community)
- Phase 1: Friends, following, shared lists
- Phase 2: Comments, activity feed, recommendations, leaderboards
- Phase 3: Achievements, watch calendar

### Third-Party Integrations (Platform Support)
- MyAnimeList (MAL)
- Kitsu
- Trakt

---

## 🎯 Implementation Priority

### High Priority (v1.2.0 - v1.3.0)
1. ✅ Battery saver mode - Better mobile experience
2. ✅ Streaming service integration - Direct episode access
3. ✅ MAL integration - Multi-platform support (README promise)
4. ✅ Achievements system - User engagement

### Medium Priority (v1.3.0 - v1.4.0)
1. Voice commands - Accessibility
2. Watch calendar - Planning tools
3. Leaderboards - Competition
4. Shared lists - Social engagement

### Lower Priority (v1.4.0+)
1. Watch party - Complex feature
2. Kitsu/Trakt integration - Additional platforms

---

## 💡 Key Benefits

### For Users
- **Battery efficiency** - Longer mobile usage
- **Accessibility** - Voice control for visually impaired
- **Social engagement** - Shared lists, leaderboards, achievements
- **Better planning** - Watch calendar with reminders
- **Direct streaming** - No need to search for episodes
- **Multi-platform** - MAL/Kitsu sync for existing users

### For Project
- **Competitive advantage** - Features AniList web doesn't have
- **User retention** - Gamification and social features
- **Accessibility compliance** - Important for inclusivity
- **Platform diversity** - Not locked to AniList only

---

## 📊 Estimated Development Time

| Feature | Effort | Dependencies | Version |
|---------|--------|--------------|---------|
| Battery Saver Mode | Medium | battery_plus | v1.2.0 |
| Streaming Integration | High | JustWatch API | v1.2.0 |
| MAL Integration | Very High | MAL API v2, OAuth | v1.3.0 |
| Achievements | High | Custom system | v1.3.0 |
| Voice Commands | High | speech_to_text | v1.3.0 |
| Watch Calendar | High | Local notifications | v1.3.0 |
| Leaderboards | High | Backend required | v1.3.0 |
| Shared Lists | Very High | WebSocket, Supabase | v1.4.0 |
| Watch Party | Very High | WebRTC | v1.4.0 |

**Total estimated time**: 6-12 months of development work

---

## 🔗 Related Documentation

- [POST_RELEASE_ROADMAP.md](./POST_RELEASE_ROADMAP.md) - Original roadmap
- [TODO.md](./TODO.md) - Complete feature list
- [README.md](../README.md) - Project overview (mentions MAL)

---

## ✅ Next Steps

1. **v1.0.0 "Aoi" release** - Focus on stability and testing
2. **v1.1.0** - Push notifications
3. **v1.2.0** - Battery saver, streaming integration
4. **v1.3.0** - MAL integration, achievements, voice commands
5. **v1.4.0+** - Social features, watch party

---

_Feature expansion completed: October 13, 2025_
