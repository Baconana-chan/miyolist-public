# Styled Chart Export - Visual Example

## 📸 Export Template Structure

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ╔════════════════════════════════════════════════════════════╗  │
│  ║ 🔵 Blue Gradient Header (150px height)                    ║  │
│  ║                                                            ║  │
│  ║            MiyoList Statistics Overview                   ║  │ ← 48px bold white
│  ║                  January 15, 2025                         ║  │ ← 28px white 90%
│  ║                                                            ║  │
│  ╚════════════════════════════════════════════════════════════╝  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │                    📊 Chart Content                        │  │
│  │                                                            │  │
│  │    ┌────────────┐  ┌────────────┐  ┌────────────┐        │  │
│  │    │            │  │            │  │            │        │  │
│  │    │   Anime    │  │   Manga    │  │  Formats   │        │  │
│  │    │  (Pie)     │  │  (Pie)     │  │  (Bar)     │        │  │
│  │    │            │  │            │  │            │        │  │
│  │    └────────────┘  └────────────┘  └────────────┘        │  │
│  │                                                            │  │
│  │    ┌──────────────────────────────────────────────────┐   │  │
│  │    │                                                  │   │  │
│  │    │          Score Distribution (Line)              │   │  │
│  │    │                                                  │   │  │
│  │    └──────────────────────────────────────────────────┘   │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │              Made with MiyoList 📊                         │  │ ← 24px white 70%
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Background: #1A1A1A (Dark Gray)
```

## 🎨 Before vs After

### Before (Basic Export):
```
┌────────────────────────────────┐
│ ⚪ Transparent/White Background│
│                                │
│  📊 Chart Content              │
│  (Hard to read on light bg)   │
│                                │
│  ⚠️ No context                 │
│  ⚠️ No branding                │
│  ⚠️ Text visibility issues     │
│                                │
└────────────────────────────────┘
```

### After (Styled Export):
```
┌────────────────────────────────┐
│ 🔵 Gradient Header             │
│    Title + Date                │ ✅ Context
├────────────────────────────────┤
│ ⚫ Dark Background (#1A1A1A)   │
│                                │
│  📊 Chart Content              │ ✅ Perfect readability
│  (Perfect contrast)            │
│                                │
│  10% padding on sides          │ ✅ Professional spacing
│                                │
├────────────────────────────────┤
│ 📊 Footer with Branding        │ ✅ Made with MiyoList
└────────────────────────────────┘
```

## 🎯 Tab-Specific Exports

### 1. Overview Tab
```
┌────────────────────────────────────────┐
│  🔵 Gradient Header                    │
│     MiyoList Statistics Overview       │
│     January 15, 2025                   │
├────────────────────────────────────────┤
│  Overall Statistics:                   │
│  • Total anime: 247                    │
│  • Total manga: 89                     │
│  • Mean score: 7.8                     │
│                                        │
│  📊 Genre Distribution (Pie)           │
│  📊 Format Distribution (Pie)          │
├────────────────────────────────────────┤
│  Made with MiyoList 📊                 │
└────────────────────────────────────────┘
```

### 2. Activity Tab
```
┌────────────────────────────────────────┐
│  🔵 Gradient Header                    │
│     Activity History                   │
│     January 15, 2025                   │
├────────────────────────────────────────┤
│  Activity Statistics:                  │
│  • Total activities: 1,234             │
│  • Active days: 156 days               │
│  • Current streak: 7 days              │
│  • Longest streak: 45 days             │
│                                        │
│  📊 Activity Heatmap (GitHub-style)    │
│  📊 Activity Breakdown                 │
├────────────────────────────────────────┤
│  Made with MiyoList 📊                 │
└────────────────────────────────────────┘
```

### 3. Anime Tab
```
┌────────────────────────────────────────┐
│  🔵 Gradient Header                    │
│     Anime Statistics                   │
│     January 15, 2025                   │
├────────────────────────────────────────┤
│  Anime Overview:                       │
│  • Total: 247                          │
│  • Completed: 189                      │
│  • Watching: 12                        │
│  • Mean score: 7.9                     │
│                                        │
│  📊 Status Distribution (Pie)          │
│  📊 Format Distribution (Pie)          │
│  📊 Score Distribution (Bar)           │
├────────────────────────────────────────┤
│  Made with MiyoList 📊                 │
└────────────────────────────────────────┘
```

### 4. Manga Tab
```
┌────────────────────────────────────────┐
│  🔵 Gradient Header                    │
│     Manga Statistics                   │
│     January 15, 2025                   │
├────────────────────────────────────────┤
│  Manga Overview:                       │
│  • Total: 89                           │
│  • Completed: 67                       │
│  • Reading: 8                          │
│  • Mean score: 7.6                     │
│                                        │
│  📊 Status Distribution (Pie)          │
│  📊 Format Distribution (Pie)          │
│  📊 Score Distribution (Bar)           │
├────────────────────────────────────────┤
│  Made with MiyoList 📊                 │
└────────────────────────────────────────┘
```

### 5. Timeline Tab
```
┌────────────────────────────────────────┐
│  🔵 Gradient Header                    │
│     Watching Timeline                  │
│     January 15, 2025                   │
├────────────────────────────────────────┤
│  Timeline Statistics:                  │
│  • View: Monthly / Yearly              │
│  • Total episodes: 2,345               │
│                                        │
│  📊 Monthly Activity (Bar Chart)       │
│  or                                    │
│  📊 Yearly Trend (Line Chart)          │
├────────────────────────────────────────┤
│  Made with MiyoList 📊                 │
└────────────────────────────────────────┘
```

## 🎨 Color Palette

```
🌈 Header Gradient:
┌───────────────────────┐
│ #2196F3 (Blue)    →   │
│ #1976D2 (Dark Blue)   │
└───────────────────────┘

⚫ Background:
#1A1A1A (Dark Gray)

⚪ Text Colors:
• Title:    White (100% opacity)
• Subtitle: White (90% opacity)
• Footer:   White (70% opacity)
```

## 📐 Dimensions Example

```
For a 1080x1920 chart content:

Width  = 1080 + 10%   = 1188px
Height = 1920 + 300px = 2220px
  └─ 150px header
  └─ 50px top padding
  └─ 1920px content
  └─ 100px footer

Resolution: 3x pixel ratio
  = 3564x6660 actual pixels
  = High quality for social media
```

## 📱 Use Cases

### Discord Share:
```
[User Avatar] @username
Just reached 250 anime! 🎉

[Attached Image: miyolist_anime_2025-01-15T12-30-45.png]
┌────────────────────────────────────────┐
│  🔵 Anime Statistics                   │
│                                        │
│  📊 250 anime watched                  │
│  📊 Mean score: 7.9                    │
│  📊 Most watched: Action (32%)         │
│                                        │
│  Made with MiyoList 📊                 │
└────────────────────────────────────────┘

👍 3  💬 5  🔁 2
```

### Twitter/X Post:
```
Just hit 250 anime watched! 🎬✨
My top genres are Action (32%) and Romance (24%)

#anime #anilist #miyolist

[Image attached with dark background and branding]
```

### Reddit Post:
```
r/anime

[OC] My 2024 Anime Statistics - 247 completed!

[Image: miyolist_overview_2025-01-15.png]
- Dark background for readability ✅
- Professional layout ✅
- High resolution ✅

Made with MiyoList desktop client

↑ 245  💬 12  ⭐ Save
```

## ✨ Benefits

✅ **Readability**: Dark background works on any surface
✅ **Context**: Title + date provide information
✅ **Branding**: "Made with MiyoList" promotes the app
✅ **Professional**: Gradient header adds polish
✅ **Shareable**: Perfect for social media
✅ **High Quality**: 3x resolution = crisp images
✅ **Recognizable**: Consistent style = brand identity

---

**Version**: v1.1.0 "Botan (牡丹)"
**Status**: ✅ Complete and Ready to Use
