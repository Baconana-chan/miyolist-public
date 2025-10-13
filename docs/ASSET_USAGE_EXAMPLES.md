# Asset Usage Examples

This document provides examples of how to use assets in the MiyoList application.

---

## 📦 Import

```dart
import 'package:miyolist/core/constants/app_assets.dart';
```

---

## 🖼️ Images

### Basic Image Display

```dart
// Display v1.0 illustration
Image.asset(
  AppAssets.v1Illustration,
  width: 300,
  height: 200,
  fit: BoxFit.cover,
)
```

### With Error Handling

```dart
Image.asset(
  AppAssets.v1Illustration,
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.broken_image, size: 100);
  },
)
```

### In a Container

```dart
Container(
  width: 400,
  height: 300,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    image: DecorationImage(
      image: AssetImage(AppAssets.v1Illustration),
      fit: BoxFit.cover,
    ),
  ),
)
```

---

## 🐱 Stickers

### Display Specific Sticker

```dart
// Show smile sticker
Image.asset(
  AppAssets.stickerSmile,
  width: 64,
  height: 64,
)
```

### Random Sticker

```dart
// Show random sticker
Image.asset(
  AppAssets.getRandomSticker(),
  width: 48,
  height: 48,
)
```

### Random Emotion Sticker

```dart
// Show random emotion (for companion reactions)
Image.asset(
  AppAssets.getRandomEmotionSticker(),
  width: 56,
  height: 56,
)
```

### Random Action Sticker

```dart
// Show random action (for companion activities)
Image.asset(
  AppAssets.getRandomActionSticker(),
  width: 56,
  height: 56,
)
```

---

## 🎨 Sticker Gallery

### Display All Stickers in Grid

```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 5,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: AppAssets.allStickers.length,
  itemBuilder: (context, index) {
    return GestureDetector(
      onTap: () {
        // Handle sticker selection
        print('Selected: ${AppAssets.allStickers[index]}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          AppAssets.allStickers[index],
          fit: BoxFit.contain,
        ),
      ),
    );
  },
)
```

### Horizontal Scrollable Sticker Row

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: AppAssets.emotionStickers.map((sticker) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () {
            // Send sticker
          },
          child: Image.asset(
            sticker,
            width: 48,
            height: 48,
          ),
        ),
      );
    }).toList(),
  ),
)
```

---

## 🤖 AI Companion Usage

### Contextual Companion Reactions

```dart
class CompanionWidget extends StatelessWidget {
  final String context; // 'happy', 'sad', 'excited', etc.
  
  String _getStickerForContext(String context) {
    switch (context) {
      case 'happy':
        return AppAssets.stickerSmile;
      case 'sad':
        return AppAssets.stickerSick;
      case 'angry':
        return AppAssets.stickerAngry;
      case 'celebrating':
        return AppAssets.stickerBirthday;
      case 'sleeping':
        return AppAssets.stickerSleep;
      case 'eating':
        return AppAssets.stickerEat;
      default:
        return AppAssets.stickerNeko;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Companion character
        Image.asset(
          _getStickerForContext(this.context),
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 8),
        // Message bubble
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('Great choice!'),
        ),
      ],
    );
  }
}
```

### Animated Sticker (with rotation)

```dart
class AnimatedStickerWidget extends StatefulWidget {
  final String stickerPath;
  
  const AnimatedStickerWidget({required this.stickerPath});
  
  @override
  State<AnimatedStickerWidget> createState() => _AnimatedStickerWidgetState();
}

class _AnimatedStickerWidgetState extends State<AnimatedStickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
    );
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: Image.asset(
            widget.stickerPath,
            width: 64,
            height: 64,
          ),
        );
      },
    );
  }
}

// Usage
AnimatedStickerWidget(stickerPath: AppAssets.stickerSmile)
```

---

## 🎯 Preloading Assets

### Preload All Stickers (for smooth UI)

```dart
class StickerPreloader {
  static Future<void> preloadAllStickers(BuildContext context) async {
    for (final sticker in AppAssets.allStickers) {
      await precacheImage(AssetImage(sticker), context);
    }
  }
}

// In app initialization
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  StickerPreloader.preloadAllStickers(context);
}
```

---

## 📱 Responsive Sizing

```dart
class ResponsiveStickerWidget extends StatelessWidget {
  final String stickerPath;
  
  const ResponsiveStickerWidget({required this.stickerPath});
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive size based on screen width
    double size;
    if (screenWidth > 1200) {
      size = 80; // Desktop
    } else if (screenWidth > 600) {
      size = 64; // Tablet
    } else {
      size = 48; // Mobile
    }
    
    return Image.asset(
      stickerPath,
      width: size,
      height: size,
    );
  }
}
```

---

## 🎨 Sticker with Background

```dart
Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    color: Colors.grey[200],
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ],
  ),
  padding: const EdgeInsets.all(12),
  child: Image.asset(
    AppAssets.stickerSmile,
    fit: BoxFit.contain,
  ),
)
```

---

## 🔄 Sticker Carousel

```dart
class StickerCarousel extends StatefulWidget {
  @override
  State<StickerCarousel> createState() => _StickerCarouselState();
}

class _StickerCarouselState extends State<StickerCarousel> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current sticker
        GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = (_currentIndex + 1) % AppAssets.allStickers.length;
            });
          },
          child: Image.asset(
            AppAssets.allStickers[_currentIndex],
            width: 100,
            height: 100,
          ),
        ),
        const SizedBox(height: 16),
        // Navigation dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            AppAssets.allStickers.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == _currentIndex
                    ? Colors.blue
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 💡 Best Practices

1. **Always use AppAssets constants** - Never hardcode asset paths
2. **Preload frequently used assets** - Especially for animations
3. **Handle errors gracefully** - Provide fallback widgets
4. **Use appropriate sizes** - Don't load large images for small displays
5. **Cache appropriately** - Flutter caches assets by default
6. **Test on all platforms** - Ensure assets work on Windows/Android/iOS

---

## 📚 Related Files

- [app_assets.dart](../lib/core/constants/app_assets.dart) - Asset path constants
- [assets/README.md](../assets/README.md) - Asset directory documentation
- [POST_RELEASE_ROADMAP.md](../docs/POST_RELEASE_ROADMAP.md) - AI Companion feature plan

---

**Last Updated:** October 11, 2025
