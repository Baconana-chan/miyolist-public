# Advanced Theme Customization Roadmap 🎨

**Status:** 📋 Planned  
**Target Versions:** v1.2.0 - v1.3.0+  
**Base Version:** v1.1.0-dev (Custom Themes completed)

---

## Overview

This document outlines the future expansion of the Custom Themes system, focusing on cloud integration, community sharing, and extended customization capabilities.

---

## 🌐 Phase 1: Cloud Sync & Sharing (v1.2.0)

### Theme Cloud Storage

**Goal:** Sync themes across devices via Supabase

#### Database Schema

```sql
-- themes table
CREATE TABLE themes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  theme_data JSONB NOT NULL, -- All theme colors
  is_public BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  downloads INTEGER DEFAULT 0,
  views INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.0,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- theme_versions (history tracking)
CREATE TABLE theme_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  theme_id UUID REFERENCES themes(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  theme_data JSONB NOT NULL,
  changelog TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- theme_ratings
CREATE TABLE theme_ratings (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  theme_id UUID REFERENCES themes(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, theme_id)
);

-- theme_tags
CREATE TABLE theme_tags (
  theme_id UUID REFERENCES themes(id) ON DELETE CASCADE,
  tag TEXT NOT NULL,
  PRIMARY KEY (theme_id, tag)
);

-- theme_favorites
CREATE TABLE theme_favorites (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  theme_id UUID REFERENCES themes(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, theme_id)
);
```

#### Features

✅ **Auto Sync**
- Upload local themes to cloud on create/edit
- Download cloud themes on other devices
- Conflict resolution (last-write-wins or manual)
- Sync indicator in UI

✅ **Privacy Levels**
- **Private** - Only visible to owner
- **Unlisted** - Accessible via link only
- **Public** - Visible in community store

✅ **Version History**
- Track theme changes over time
- Rollback to previous versions
- Compare versions side-by-side
- Changelog for each version

✅ **Backup & Restore**
- Automatic cloud backup
- One-click restore from backup
- Export all themes as ZIP
- Import from backup file

### Theme Sharing

**Goal:** Share themes easily with friends and community

#### Sharing Methods

**1. Share Link**
```
https://miyo.my/themes/abc123
```
- Unique URL per theme
- Preview theme before installing
- QR code for easy mobile sharing
- Copy link to clipboard
- Direct install button

**2. Share Code**
```
MIYOTHEME-ABC123
```
- 6-character alphanumeric code
- Enter in app to download theme
- Case-insensitive
- Expires after 30 days (optional)

**3. Social Sharing**
- Twitter card with theme preview
- Discord embed with colors
- Reddit-friendly markdown
- Instagram story template
- Custom share image generator

#### Share Dialog UI

```dart
showDialog(
  context: context,
  builder: (context) => ThemeShareDialog(
    theme: selectedTheme,
    onShare: (method) {
      // Handle different share methods
    },
  ),
);
```

**Dialog Features:**
- Theme preview image
- Share link with copy button
- QR code generator
- Social media buttons
- Attribution watermark
- Privacy settings toggle

---

## 🏪 Phase 2: Community Theme Store (v1.3.0)

### Theme Discovery

**Goal:** Browse, search, and discover themes from community

#### Store UI Components

**1. Browse Page**
```dart
CommunityThemeStorePage(
  sections: [
    'Featured',      // Curated by team
    'Trending',      // Most downloaded this week
    'New Releases',  // Recently published
    'Top Rated',     // Highest ratings
    'Popular',       // Most downloads all-time
    'Following',     // From followed creators
  ],
)
```

**2. Search & Filter**
- **Search by:**
  - Theme name
  - Author name
  - Tags (#dark, #anime, #minimal)
  - Colors (find themes with specific colors)

- **Filter by:**
  - Category (Dark, Light, Colorful, Minimal)
  - Rating (1-5 stars)
  - Downloads (>100, >1000, >10000)
  - Date (Today, This Week, This Month, All Time)
  - Author (verified, community)

- **Sort by:**
  - Relevance (search results)
  - Popularity (downloads)
  - Rating (highest first)
  - Date (newest/oldest)
  - Alphabetical (A-Z, Z-A)

**3. Theme Cards**
```dart
CommunityThemeCard(
  theme: theme,
  showAuthor: true,
  showStats: true, // downloads, rating
  showPreview: true, // color swatches
  onTap: () => showThemeDetails(theme),
)
```

**Card Information:**
- Theme name & description
- Author avatar & name
- Color preview (8 swatches)
- Downloads count
- Rating (stars)
- Tags
- "Installed" badge if already owned

### Theme Details Page

**Full theme information and installation**

#### UI Sections

**1. Header**
- Large theme preview image
- Theme name & description
- Author info (avatar, name, verified badge)
- Statistics (downloads, rating, views)

**2. Preview Section**
- Live preview of theme applied to sample UI
- Multiple preview screens (list, details, profile)
- Swipe to see different screens

**3. Colors Section**
- All 15 colors displayed with labels
- Hex codes shown
- Copy color to clipboard

**4. Metadata**
- Created date
- Last updated
- Version number
- Category & tags
- Privacy level

**5. Actions**
- **Install** button (primary)
- **Preview** button (try before installing)
- **Share** button
- **Favorite** button (heart icon)
- **Report** button (flag icon)
- **Fork** button (remix/customize)

**6. Ratings & Reviews**
- Average rating (1-5 stars)
- Rating distribution chart
- User reviews with text
- Helpful/Not Helpful votes
- Write review button (if installed)

**7. Similar Themes**
- Recommendations based on colors/style
- "Users who downloaded this also downloaded"
- Same author's other themes

**8. Version History**
- List of all versions
- Changelogs
- Download older versions

### User Profiles

**Theme creator profiles**

#### Profile Sections

**1. Header**
- Avatar & username
- Verified badge (for official creators)
- Follower/Following counts
- Bio/Description
- Social links

**2. Published Themes**
- Grid of user's public themes
- Sort by date/popularity
- Total downloads across all themes

**3. Collections**
- Curated theme packs
- Thematic collections (anime-inspired, seasonal, etc.)

**4. Stats**
- Total themes published
- Total downloads
- Average rating
- Themes featured count

**5. Actions**
- Follow/Unfollow button
- Message button (optional)
- Report user button

### Community Features

#### Ratings & Reviews

**Star Ratings (1-5 stars)**
```dart
RatingBar(
  initialRating: userRating,
  onRatingUpdate: (rating) {
    submitRating(themeId, rating);
  },
)
```

**Text Reviews**
- 500 character limit
- Optional with rating
- Can be edited/deleted by author
- Helpful/Not Helpful votes
- Report inappropriate reviews

#### Comments & Discussions

- Comment on themes (optional feature)
- Reply to comments
- Upvote/Downvote
- Moderation tools

#### Following System

- Follow favorite theme creators
- Notification when they publish new themes
- "Following" feed in theme store
- Follower/Following lists

#### Featured Themes

**Curated by MiyoList team**
- Weekly featured theme rotation
- Criteria: Quality, originality, popularity
- Special badge for featured themes
- Increased visibility in store

#### Theme Challenges

**Community events**
- Monthly theme contests
- Specific prompts (e.g., "Retro Anime Theme")
- Voting system
- Winner gets featured
- Prizes (badges, exclusive features)

---

## 🎨 Phase 3: Extended Customization (v1.2.0+)

### Font Customization

**Goal:** Let users choose fonts beyond colors

#### Features

✅ **Font Family Selection**
- 20+ Google Fonts pre-loaded
- Categories: Serif, Sans-serif, Monospace, Display
- Preview text in each font
- Search fonts by name
- Favorites system

✅ **Font Size Presets**
- Small (12sp base)
- Medium (14sp base) - Default
- Large (16sp base)
- Extra Large (18sp base)
- Custom (slider 10-24sp)

✅ **Font Weight**
- Thin, Light, Regular, Medium, Bold, Black
- Per text category (titles, body, captions)

✅ **Line Height**
- Tight (1.2x)
- Normal (1.5x) - Default
- Relaxed (1.8x)
- Custom slider

✅ **Letter Spacing**
- Compact (-0.5px)
- Normal (0px) - Default
- Spacious (+0.5px)
- Wide (+1px)

#### UI Implementation

```dart
ThemeFontSettings(
  currentFont: 'Roboto',
  currentSize: FontSize.medium,
  onFontChange: (font) => updateThemeFont(font),
  onSizeChange: (size) => updateFontSize(size),
)
```

### Visual Customization

**Goal:** Customize UI elements beyond fonts

#### Border Radius

**Presets:**
- Sharp (0px) - Square corners
- Slightly Rounded (4px)
- Rounded (8px) - Default
- Very Rounded (12px)
- Circular (50px) - Pill shape

**Custom Slider:** 0-50px

#### Card Styles

**Options:**
- **Flat** - No elevation, border only
- **Elevated** - Shadow, no border (default)
- **Outlined** - Border, no shadow
- **Filled** - Solid background, no border/shadow

#### Icon Style

**Options:**
- **Outlined** - Default Material outlined
- **Filled** - Solid filled icons
- **Rounded** - Rounded corners
- **Sharp** - Sharp edges

#### Animation Speed

**Presets:**
- Instant (0ms) - No animations
- Fast (150ms)
- Normal (300ms) - Default
- Slow (600ms)
- Smooth (900ms)

#### Special Effects

✅ **Blur Effects**
- Glass morphism backgrounds
- Frosted glass dialogs
- Blur intensity slider (0-20px)

✅ **Gradient Backgrounds**
- Linear gradients (top-to-bottom, diagonal)
- Radial gradients (center outward)
- Sweep gradients (circular)
- Multi-stop gradients (3+ colors)
- Gradient editor UI

✅ **Texture Overlays**
- Paper texture
- Fabric texture
- Noise texture
- Custom image upload
- Opacity slider (0-100%)

### Layout Customization

**Goal:** Control spacing and density

#### Density Presets

**Compact**
- Small padding (8px)
- Tight spacing (4px)
- More content visible
- Good for large lists

**Comfortable** (Default)
- Medium padding (16px)
- Normal spacing (8px)
- Balanced layout

**Spacious**
- Large padding (24px)
- Wide spacing (16px)
- Airy, relaxed feel

#### Grid Customization

**Column Count**
- 2 columns (mobile)
- 3 columns (tablet)
- 4 columns (desktop) - Default
- 5-8 columns (custom)
- Auto-responsive

**Card Aspect Ratio**
- Portrait (2:3) - Default for anime covers
- Square (1:1)
- Landscape (3:2)
- Wide (16:9)

#### Navigation Position

**Options:**
- Top (default mobile)
- Bottom (default desktop)
- Side (desktop only)
- Hidden (swipe to reveal)

### Component Customization

**Goal:** Customize individual UI components

#### Button Styles

- Flat
- Raised (default)
- Outlined
- Text-only

#### Chip Styles

- Filled (default)
- Outlined
- Rounded corners
- Custom colors

#### Progress Indicators

- Linear bar
- Circular spinner
- Custom icons
- Percentage display

### Advanced Features

#### Theme Presets

**Pre-made combinations of settings**
- "Minimal" - Sharp corners, no shadows, sans-serif
- "Modern" - Rounded, gradients, animations
- "Classic" - Traditional, serif fonts, subtle
- "Playful" - Very rounded, bright colors, animations

#### Theme Preview Mode

**Try before applying**
- Preview theme in separate window
- Navigate app with preview active
- Side-by-side comparison
- Revert to original with one click

#### A/B Theme Comparison

**Compare two themes directly**
- Split-screen view
- Swipe between themes
- Highlight differences
- Vote which you prefer

#### Random Theme Generator

**AI-powered color scheme**
- Generate random harmonious colors
- Based on color theory
- Regenerate until satisfied
- Save favorites

#### Color Harmony Checker

**Ensure good combinations**
- Check contrast ratios
- Suggest complementary colors
- Warn about bad combinations
- Color blindness simulation

---

## 🎨 Phase 4: Theme Presets & Templates (v1.2.0)

### Preset Categories

#### Anime-Inspired Themes

**Demon Slayer**
- Primary: Red (#E63946)
- Secondary: Black (#1A1A1A)
- Accent: Teal (#1D7874)

**My Hero Academia**
- Primary: Green (#4CAF50)
- Secondary: Yellow (#FFD54F)
- Accent: Blue (#42A5F5)

**Attack on Titan**
- Primary: Brown (#795548)
- Secondary: Tan (#D7CCC8)
- Accent: Forest Green (#388E3C)

**One Piece**
- Primary: Ocean Blue (#0288D1)
- Secondary: Orange (#FF6F00)
- Accent: Sunny Yellow (#FDD835)

**Naruto**
- Primary: Orange (#FF6D00)
- Secondary: Blue (#1976D2)
- Accent: Black (#212121)

**Jujutsu Kaisen**
- Primary: Black (#121212)
- Secondary: Red (#D32F2F)
- Accent: Electric Blue (#2196F3)

**Spy x Family**
- Primary: Soft Pink (#F48FB1)
- Secondary: Mint Green (#81C784)
- Accent: Navy (#1565C0)

#### Seasonal Themes

**Spring Blossom**
- Soft pinks, fresh greens
- Light, airy feel
- Floral accents

**Summer Beach**
- Bright blues, sunny yellows
- High contrast
- Energetic vibe

**Autumn Leaves**
- Warm oranges, browns
- Cozy feeling
- Natural tones

**Winter Frost**
- Cool whites, icy blues
- Clean, minimal
- Crisp aesthetic

#### Aesthetic Themes

**Vaporwave**
- Purple/Pink/Cyan gradient
- Retro-futuristic
- Neon accents

**Cyberpunk**
- Neon colors on black
- High tech feel
- RGB lighting

**Minimalist**
- White/Gray monochrome
- Clean, simple
- Maximum focus

**Retro**
- Warm vintage colors
- Nostalgic feel
- Muted tones

**Pastel**
- Soft, light colors
- Gentle, calming
- Low contrast

**High Contrast**
- Pure black & white
- Maximum readability
- Bold, striking

---

## 🌈 Phase 5: Dynamic Themes (v1.3.0+)

### Context-Based Themes

#### Time of Day

**Automatic switching**
- Morning (6am-12pm): Light, energetic colors
- Afternoon (12pm-6pm): Neutral, comfortable
- Evening (6pm-10pm): Warm, relaxing tones
- Night (10pm-6am): Dark, low blue light

#### Season Detection

**Auto-switch based on calendar**
- Spring (Mar-May): Blossom theme
- Summer (Jun-Aug): Beach theme
- Autumn (Sep-Nov): Leaves theme
- Winter (Dec-Feb): Frost theme

#### Weather-Based

**Match local weather**
- Sunny: Bright, warm colors
- Rainy: Cool blues, grays
- Cloudy: Neutral, soft tones
- Snowy: White, icy colors

**API:** OpenWeatherMap or similar

#### Battery Level

**Preserve battery when low**
- <20%: Switch to pure black OLED theme
- <50%: Disable animations
- Charging: Full theme restored

#### Active Media Adaptive

**Extract colors from current anime/manga**
```dart
Future<CustomTheme> generateFromMedia(MediaDetails media) async {
  final cover = media.coverImage;
  final colors = await extractDominantColors(cover);
  
  return CustomTheme.fromColors(
    primary: colors[0],
    secondary: colors[1],
    accent: colors[2],
    // ... generate full theme
  );
}
```

### Dynamic Elements

#### Animated Backgrounds

**Options:**
- Particle systems (floating orbs)
- Wave animations
- Gradient animations (smooth color transitions)
- Geometric patterns
- Snow/Rain effects

#### Live Wallpapers

**Video/GIF backgrounds**
- Looping animations
- Low opacity for readability
- Performance considerations
- Battery impact warning

#### Parallax Effects

**Depth on scroll**
- Background moves slower than foreground
- Creates 3D illusion
- Smooth, natural feeling

#### Reactive UI

**Elements respond to touch**
- Ripple effects
- Button press animations
- Hover states (desktop)
- Haptic feedback

---

## ♿ Phase 6: Accessibility Themes (v1.2.0)

### Colorblind Modes

**Support for different types**

**Protanopia (Red-blind)**
- Replace reds with browns/oranges
- Avoid red/green combinations

**Deuteranopia (Green-blind)**
- Replace greens with blues/browns
- Avoid red/green combinations

**Tritanopia (Blue-blind)**
- Replace blues with reds/pinks
- Avoid blue/yellow combinations

**Achromatopsia (Total)**
- Grayscale theme
- Rely on patterns, not colors

### High Contrast Mode

**WCAG AAA compliant**
- Minimum 7:1 contrast ratio
- Pure black text on white
- Large, bold fonts
- No subtle colors

### Large Text Mode

**Extra accessibility**
- 18sp+ base font size
- Simplified UI
- Larger touch targets
- More spacing

### Dyslexia-Friendly

**Easier reading**
- OpenDyslexic font
- Increased line spacing
- No italics
- Left-aligned text

### Validation Tools

**Built-in checkers**

**Contrast Ratio Checker**
```dart
double calculateContrastRatio(Color fg, Color bg) {
  // WCAG 2.1 formula
  // Returns ratio (1-21)
}

bool meetsWCAG_AA(double ratio) => ratio >= 4.5;
bool meetsWCAG_AAA(double ratio) => ratio >= 7.0;
```

**Color Blindness Simulator**
- Preview theme as colorblind person sees it
- Side-by-side comparison
- All 4 types supported

---

## 🚀 Implementation Plan

### v1.2.0 (Q1 2026)
- [ ] Cloud theme sync (Supabase integration)
- [ ] Theme sharing (link/code)
- [ ] Font customization
- [ ] Extended visual customization
- [ ] Theme presets
- [ ] Accessibility themes
- [ ] Theme preview mode

### v1.3.0 (Q2 2026)
- [ ] Community theme store
- [ ] Search & discovery
- [ ] Ratings & reviews
- [ ] User profiles
- [ ] Following system
- [ ] Featured themes
- [ ] Advanced filters

### v1.3.5 (Q3 2026)
- [ ] Dynamic themes
- [ ] Animated backgrounds
- [ ] Context-based switching
- [ ] Theme forking
- [ ] Collaborative editing

### v1.4.0+ (Q4 2026)
- [ ] Theme challenges/contests
- [ ] Advanced analytics
- [ ] Theme remix feature
- [ ] Community moderation
- [ ] Premium themes (optional monetization)

---

## 🎯 Success Metrics

**Engagement:**
- 50%+ users create custom theme
- 10,000+ community themes published
- 100,000+ theme downloads

**Quality:**
- 4.0+ average theme rating
- <5% reported themes
- 90%+ accessibility score

**Performance:**
- <100ms theme switch time
- <5MB cloud storage per user
- 99.9% sync success rate

---

## 📚 Dependencies

**New Packages:**
- `google_fonts` - Font customization
- `qr_flutter` - QR code generation
- `share_plus` - Social sharing
- `flutter_colorblind` - Colorblind simulation
- `flutter_weather` - Weather-based themes
- `video_player` - Live wallpapers
- `image_picker` - Custom textures
- `palette_generator` - Extract colors from images

**Backend:**
- Supabase (themes table, storage)
- PostgreSQL (database)
- Supabase Storage (theme assets)

---

## 🔒 Privacy & Security

**User Data:**
- Themes are user-owned
- Can be private/unlisted/public
- Delete at any time
- Export data anytime

**Moderation:**
- Report inappropriate themes
- Automated content filtering
- Manual review for featured themes
- Community guidelines enforcement

**Attribution:**
- Original creator always credited
- Fork/remix attribution chain
- DMCA takedown process

---

**Next Steps:** Complete base theme system in v1.1.0, then begin v1.2.0 planning! 🚀
