# Assets Directory

This directory contains all static resources bundled with the MiyoList application.

---

## 📁 Structure

```
assets/
├── images/           # App illustrations and branding
│   └── illustation-for-v1.0.0.png
└── stickers/         # Stickers for AI Companion feature
    ├── adopt.png
    ├── angry.png
    ├── arrogant.png
    ├── back.png
    ├── birthday.png
    ├── eat.png
    ├── eat (1).png
    ├── hungry.png
    ├── jump.png
    ├── lick.png
    ├── neko.png
    ├── play.png
    ├── playing.png
    ├── scratch.png
    ├── sick.png
    ├── sit.png
    ├── sleep.png
    ├── smile.png
    ├── stretch.png
    └── yawn.png
```

---

## 🖼️ Images

### `images/illustation-for-v1.0.0.png`
- **Purpose:** Illustration for v1.0.0 release announcement
- **Usage:** About page, marketing materials, release notes
- **Size:** To be optimized before release
- **Format:** PNG

**How to use in code:**
```dart
import 'package:miyolist/core/constants/app_assets.dart';

Image.asset(AppAssets.v1Illustration)
```

---

## 🐱 Stickers

All stickers in the `stickers/` directory are part of the **"Cute Funny Orange Cat Illustration Sticker Set"**.

### Credits
- **Author:** [Adorableninana](https://www.flaticon.com/authors/adorableninana)
- **Source:** [Flaticon - Cute Funny Orange Cat Sticker Set](https://www.flaticon.com/stickers-pack/cute-funny-orange-cat-illustration-sticker-set)
- **License:** Free for personal and commercial use with attribution
- **Total Stickers:** 20

### Usage
These stickers will be used in the **AI Companion** feature (planned for v1.3.0 post-release).

**Categories:**

#### Emotion Stickers (6)
Used for companion's emotional reactions:
- `smile.png` - Happy/pleased
- `angry.png` - Frustrated/annoyed
- `arrogant.png` - Confident/proud
- `sick.png` - Sad/disappointed
- `birthday.png` - Celebrating
- `adopt.png` - Loving/caring

#### Action Stickers (13)
Used for companion's activity responses:
- `eat.png` / `eat (1).png` - Eating
- `hungry.png` - Hungry
- `jump.png` - Excited
- `play.png` / `playing.png` - Playing
- `sleep.png` - Sleeping/tired
- `stretch.png` - Stretching
- `yawn.png` - Yawning
- `lick.png` - Grooming
- `scratch.png` - Scratching
- `sit.png` - Sitting
- `back.png` - Back view

#### Character Stickers (1)
- `neko.png` - Base character

**How to use in code:**
```dart
import 'package:miyolist/core/constants/app_assets.dart';

// Use specific sticker
Image.asset(AppAssets.stickerSmile)

// Use random sticker
Image.asset(AppAssets.getRandomSticker())

// Use random emotion sticker
Image.asset(AppAssets.getRandomEmotionSticker())

// Get all stickers
for (final sticker in AppAssets.allStickers) {
  Image.asset(sticker)
}
```

---

## 🔧 Configuration

Assets are configured in `pubspec.yaml`:

```yaml
flutter:
  assets:
    # App illustrations and branding
    - assets/images/
    
    # Stickers for AI Companion feature (future)
    # Credits: Adorableninana
    - assets/stickers/
```

---

## 📝 Adding New Assets

### Images
1. Place image in `assets/images/`
2. Add path constant to `lib/core/constants/app_assets.dart`
3. Update this README

### Stickers
1. Place sticker in `assets/stickers/`
2. Add path constant to `AppAssets` class
3. Add to appropriate collection list (`allStickers`, `emotionStickers`, `actionStickers`)
4. Update this README
5. **Important:** Update credits if from different source

---

## 📏 Asset Guidelines

### Images
- **Format:** PNG (with transparency) or JPG
- **Max Size:** 2MB per image
- **Resolution:** 
  - Icons: 512x512px
  - Illustrations: 1920x1080px max
- **Optimization:** Use tools like TinyPNG before committing

### Stickers
- **Format:** PNG with transparency
- **Size:** Under 100KB each
- **Resolution:** 256x256px or 512x512px
- **Style:** Consistent with existing pack
- **Naming:** lowercase, descriptive, no spaces

---

## 🎨 Future Asset Categories

Planned for future releases:

### Fonts (v1.2.0+)
```
assets/fonts/
├── CustomFont-Regular.ttf
├── CustomFont-Bold.ttf
└── CustomFont-Italic.ttf
```

### Animations (v1.3.0+)
```
assets/animations/
├── loading.json
├── success.json
└── companion_idle.json
```

### Audio (v1.4.0+)
```
assets/sounds/
├── notification.mp3
└── success.mp3
```

---

## ⚖️ Legal

### Stickers Attribution
All cat stickers must be attributed to Adorableninana as per Flaticon's free license terms. Attribution is included in:
- `pubspec.yaml` (comments)
- About dialog in app
- This README
- Documentation

### App Illustrations
Custom illustrations created for MiyoList are under MIT License (same as project).

---

## 📚 Related Documentation

- [AppAssets class](../lib/core/constants/app_assets.dart) - Asset path constants
- [About Dialog](../lib/features/profile/presentation/widgets/about_dialog.dart) - Credits display
- [POST_RELEASE_ROADMAP.md](../docs/POST_RELEASE_ROADMAP.md) - AI Companion feature plan

---

**Last Updated:** October 11, 2025
