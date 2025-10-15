# 🚀 Pre-Release Checklist - MiyoList v1.0.0 "Aoi"

**Target Release Date:** [TBD]  
**Current Status:** Preparing for release

---

## ✅ Code Changes Completed

### Metadata Updates
- [x] Updated `windows/runner/Runner.rc`:
  - CompanyName: "MiyoList Project"
  - FileDescription: "MiyoList - Unofficial AniList Desktop Client"
  - LegalCopyright: "Copyright (C) 2025 MiyoList Project. Licensed under MIT License."
  - ProductName: "MiyoList"

- [x] Updated `pubspec.yaml`:
  - Description: "MiyoList - Unofficial AniList Desktop Client. Track your anime and manga with a beautiful, fast, and privacy-focused desktop experience."

### TODO Updates
- [x] Added Alternative Authentication section (Discord/Google OAuth) - POSTPONED pending AniList approval
- [x] Added Discord Rich Presence feature - Planned for v1.6.0+

---

## 📋 Pre-Release Tasks

### 1. Build & Testing
- [ ] **Clean build** (DONE: `flutter clean`)
- [ ] **Release build** (IN PROGRESS: `flutter build windows --release`)
- [ ] **Test executable** in clean Windows environment
- [ ] **Verify metadata** (Right-click .exe → Properties → Details)
  - Check Company: "MiyoList Project"
  - Check Description: "MiyoList - Unofficial AniList Desktop Client"
  - Check Copyright: "Licensed under MIT License"
- [ ] **Test OAuth flow** (manual code entry)
- [ ] **Test offline mode**
- [ ] **Test sync functionality**
- [ ] **Performance test** with large list (2000+ entries)

### 2. Documentation
- [ ] Update `CHANGELOG.md` with v1.0.0 changes
- [ ] Review `README.md` for accuracy
- [ ] Check all documentation links work
- [ ] Add installation screenshots to docs
- [ ] Update version numbers in all docs

### 3. Screenshots Preparation
Required screenshots for release (1920x1080 recommended):

- [ ] **Screenshot 1: Activity Feed**
  - Show "Airing Today" section at top
  - Trending Anime & Manga visible
  - Newly Added section
  - Color-coded cards

- [ ] **Screenshot 2: Anime List (Grid View)**
  - Multiple anime covers visible
  - Color-coded status strips clearly visible
  - "All" status filter selected
  - Progress indicators shown

- [ ] **Screenshot 3: Advanced Search**
  - Advanced Search dialog open
  - Filters visible (genre, year, season)
  - Sort options shown
  - Search results below

- [ ] **Screenshot 4: Media Details**
  - Banner image at top
  - Full description visible
  - Characters section
  - Staff section
  - Relations visible

- [ ] **Screenshot 5: Bulk Operations**
  - Multiple anime selected (blue borders)
  - Checkmarks visible
  - Bulk action buttons shown
  - At least 5+ items selected

- [ ] **Screenshot 6: Themes**
  - Theme selector dialog open
  - All three themes visible (Dark, Light, Carrot)
  - Preview of each theme

- [ ] **Screenshot 7: Privacy Settings**
  - Privacy Settings dialog open
  - Profile type selection
  - Selective sync checkboxes
  - Tab visibility controls

- [ ] **Screenshot 8: Airing Schedule**
  - 7-day view visible
  - Episode countdowns showing
  - Day-by-day organization
  - "In Xh Ym" or "Aired Xh ago" visible

- [ ] **Screenshot 9: Character Details**
  - Character page open
  - Media appearances visible
  - Voice actors section

- [ ] **Screenshot 10: Bulk Select Mode**
  - Selection mode active
  - Multiple items selected
  - Action bar visible

**Screenshot Tips:**
- Use default Dark theme for consistency
- Capture at 1920x1080 or 1280x720
- Use real data (your actual AniList account)
- Avoid NSFW content in screenshots
- Save as PNG for quality
- Compress images before uploading

### 4. Website Updates
- [ ] Copy `favicon.ico` to miyomy website:
  ```powershell
  Copy-Item "c:\Users\VIC\flutter_project\miyolist\windows\runner\resources\app_icon.ico" "c:\Users\VIC\miyomy\public\favicon.ico" -Force
  ```
- [ ] Test website build: `npm run build`
- [ ] Deploy website to Cloudflare Pages
- [ ] Verify OAuth callback works: `https://miyo.my/auth/callback`
- [ ] Test full OAuth flow (web → app → login)

### 5. AniList OAuth Setup
- [ ] Verify AniList redirect URI is set to: `https://miyo.my/auth/callback`
- [ ] Test OAuth flow from fresh install
- [ ] Confirm manual code entry works
- [ ] Test URL paste auto-cleanup

### 6. Package Preparation
- [ ] Create release folder structure:
  ```
  MiyoList-v1.0.0-Aoi-Windows/
  ├── miyolist.exe
  ├── flutter_windows.dll
  ├── data/
  ├── README.txt (installation instructions)
  └── LICENSE.txt
  ```
- [ ] Compress to ZIP
- [ ] Calculate SHA256 checksum:
  ```powershell
  Get-FileHash "MiyoList-v1.0.0-Aoi-Windows.zip" -Algorithm SHA256
  ```
- [ ] Test extraction and run on clean system

### 7. GitHub Release
- [ ] Create GitHub release draft
- [ ] Upload ZIP file
- [ ] Copy release notes from `RELEASE_v1.0.0_AOI.md`
- [ ] Add all screenshots with descriptions
- [ ] Add SHA256 checksum
- [ ] Set as "Latest Release"
- [ ] Tag: `v1.0.0`

### 8. Community Announcements

**AniList Forum:**
- [ ] Post using `ANILIST_FORUM_POST.md`
- [ ] Upload all 10 screenshots with captions
- [ ] Monitor for questions/feedback
- [ ] Pin post if possible

**Reddit (r/anime, r/AniList):**
- [ ] Post using Reddit template from `SOCIAL_MEDIA_POSTS.md`
- [ ] Create Imgur album with screenshots
- [ ] Link to GitHub releases
- [ ] Respond to comments actively

**Twitter/X:**
- [ ] Post announcement with key features
- [ ] Include 4 best screenshots
- [ ] Use hashtags: #AniList #Anime #Manga #OpenSource
- [ ] Tag AniList official account (if appropriate)

**Discord:**
- [ ] Post in relevant anime/tech Discord servers
- [ ] Share in r/anime Discord
- [ ] Share in Flutter Discord (showcase channel)

### 9. Post-Release Monitoring
- [ ] Monitor GitHub Issues for bug reports
- [ ] Respond to community feedback
- [ ] Track download counts
- [ ] Note feature requests for v1.1.0
- [ ] Update roadmap based on feedback

---

## 🔧 Build Commands Reference

### Clean Build
```powershell
cd c:\Users\VIC\flutter_project\miyolist
flutter clean
flutter pub get
flutter build windows --release
```

### Output Location
```
build/windows/x64/runner/Release/
```

### Files to Package
- `miyolist.exe` (main executable)
- `flutter_windows.dll` (Flutter engine)
- `data/` folder (Flutter assets)

### Optional: Create Installer
(For future releases - use Inno Setup or NSIS)

---

## 📊 Release Metrics to Track

- [ ] **GitHub Stars** (initial target: 50+)
- [ ] **Downloads** (initial target: 100+ in first week)
- [ ] **Issues reported** (track for v1.0.1 bugfix release)
- [ ] **Community feedback** (positive/negative ratio)
- [ ] **Feature requests** (prioritize for v1.1.0)

---

## 🐛 Known Issues for v1.0.1

Document any issues found during testing:

### Critical
- None

### Medium
- None

### Low
- None

---

## 📝 Version Bump for Next Release

After v1.0.0 release, immediately prepare for v1.0.1:

1. Update version in `pubspec.yaml`: `version: 1.0.1+6`
2. Create `CHANGELOG_v1.0.1.md`
3. Start tracking bugs and small improvements
4. Plan v1.1.0 features based on feedback

---

## ✅ Final Checklist Before Publishing

**DO NOT PUBLISH UNTIL ALL CHECKED:**

- [ ] Release build successful (no errors)
- [ ] Executable tested on clean Windows 10/11
- [ ] All metadata correct (company, description, copyright)
- [ ] OAuth flow works end-to-end
- [ ] All 10 screenshots captured and ready
- [ ] Documentation reviewed and accurate
- [ ] Website deployed and OAuth callback tested
- [ ] ZIP file created and SHA256 calculated
- [ ] Release notes finalized
- [ ] GitHub release draft created
- [ ] Community posts prepared
- [ ] Ready for feedback and support

---

## 🎉 Post-Release Celebration

After successful release:

1. ⭐ Thank beta testers and contributors
2. 📢 Share on social media
3. 💬 Engage with community feedback
4. 📊 Monitor metrics daily for first week
5. 🐛 Be ready for hotfix if critical bugs found
6. 🎯 Start planning v1.1.0 features

---

**Remember:** Release is just the beginning! Community feedback will shape future versions.

**Good luck with the release! 🚀**
