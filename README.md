# 🎌 MiyoList - Unofficial AniList Client

<div align="center">
A modern, desktop AniList tracker built with Tauri 2 + Preact. Track your anime, manga and light novels with full offline support and automatic sync to your AniList account.

**Track your anime & manga with style**

![Tech Stack](https://img.shields.io/badge/Tech-Tauri_2%20%2B%20Preact-blue)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Android-green)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

[**📦 Download**](https://github.com/Baconana-chan/miyolist-public/releases) • [**🐛 Report Bug**](https://github.com/Baconana-chan/miyolist-public/issues)
</div>

---

## ✨ Why MiyoList?

MiyoList is an **unofficial AniList client** that elevates your anime and manga tracking with:

- ⚡ **Lightning Fast UI**: Built with Preact and Tauri 2 for minimal overhead and memory footprint.
- 💾 **Offline-First Storage**: Full offline support with bundled SQLite database.
- 🔄 **Smart Queue Sync**: Dirty-flag queue that automatically syncs to AniList when you're back online.
- 📱 **Cross-Platform Desktop**: Native-feeling application for Windows, Linux, macOS, and Android.
- 🖼️ **Offline Cover Cache**: Local cover image cache with prefetching to save bandwidth.
- 🔔 **System Integration**: Native OS push notifications for your airing anime.
- 📊 **Rich Statistics**: Comprehensive totals, score histograms, and a 52-week activity heatmap.

---

## 🚀 Key Features

### 📊 Library & Tracking
- ✅ Browse Anime, Manga, and Light Novel lists with advanced status filters and sorting.
- ✅ Multiple view modes: Grid, Compact, and List.
- ✅ Edit entries completely: status, score, episode/chapter/volume progress, dates, notes, and rewatch counters.
- ✅ Instant sync to AniList, falling back to local queue if offline.

### 🔍 Discovery & Details
- ✅ **Global Search**: Find media, characters, staff, studios, and AniList users easily.
- ✅ **Advanced Media Search**: Filter by genre, tag, year, format, status, and adult content toggle.
- ✅ **Rich Media Panels**: View banners, Markdown descriptions, tags, studios, and popularity metrics.
- ✅ **People & Studios**: Dedicated detail panels with favorites tracking.

### 🔔 Stay Updated
- ✅ **Airing Schedule**: Your watchlist grouped by day, complete with episode progress controls.
- ✅ **Native Notifications**: OS push notifications alert you when new episodes air.
- ✅ **Activity Log**: View your last 100 list updates with relative timestamps.

### 💻 Technology & Performance
- ✅ **Tauri 2 Foundation**: Lightweight and secure desktop shell.
- ✅ **SQLite Backend**: Handled via `rusqlite`—bundled and requires no external installs.
- ✅ **Seamless Auth**: Localhost callback on port 43821 integrated with Windows Credential Manager.

---

## 📥 Installation

### Quick Start
1. Download the appropriate installer for your OS from [GitHub Releases](https://github.com/Baconana-chan/miyolist-public/releases).
2. Install and launch MiyoList.
3. Sign in with your AniList account.
4. Enjoy tracking your library natively!

### Platforms
- 🪟 **Windows**: `.exe` (NSIS), `.msi`, or portable `.zip`.
- 🐧 **Linux**: AppImage, `.deb`, or `.rpm`.
- 🍎 **macOS**: `.dmg`.
- 🤖 **Android**: `.apk`.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **UI** | Preact 10 + TypeScript |
| **Styling** | Tailwind CSS v4 |
| **Build** | Vite + Bun |
| **Desktop shell** | Tauri 2 |
| **Database** | SQLite via `rusqlite` (bundled, no external install) |
| **Auth** | AniList OAuth2 — localhost callback + Windows Credential Manager |

---

## 🤝 Contributing

Contributions are welcome! We have moved the developer setup and architecture details to our contribution guide. 
Please check [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to set up the development environment, run checks, and submit PRs.

- 🐛 **Report Bugs**: [Open an issue](https://github.com/Baconana-chan/miyolist-public/issues).
- 💡 **Suggest Features**: Share your ideas.
- 🔧 **Submit PRs**: Code contributions appreciated.
- ⭐ **Star the Repo**: Show your support!

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

---

## ⚠️ Disclaimer

MiyoList is an **unofficial** third-party client and is **not affiliated with AniList**. All anime/manga data is provided by the [AniList API](https://anilist.co/). Use at your own discretion and respect AniList's [Terms of Service](https://anilist.co/terms).

---

<div align="center">
**Made with ❤️ by Baconana-chan**

[⬆ Back to Top](#-miyolist---unofficial-anilist-client)
</div>
