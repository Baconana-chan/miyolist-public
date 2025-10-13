/// Asset paths for MiyoList application
/// 
/// This file contains all asset paths used in the app.
/// Assets are bundled with the application during build.
class AppAssets {
  AppAssets._(); // Private constructor to prevent instantiation

  // ============================================================================
  // IMAGES
  // ============================================================================
  
  /// App illustrations and branding
  static const String _imagesPath = 'assets/images/';
  
  /// Illustration for v1.0.0 release
  /// Used for: Release announcements, about page, marketing materials
  static const String v1Illustration = '${_imagesPath}illustation-for-v1.0.0.png';

  // ============================================================================
  // STICKERS - AI Companion
  // ============================================================================
  
  /// Cat stickers for AI Companion feature
  /// Credits: Adorableninana - https://www.flaticon.com/stickers-pack/cute-funny-orange-cat-illustration-sticker-set
  /// License: Free for personal and commercial use with attribution
  static const String _stickersPath = 'assets/stickers/';
  
  // Cat Emotions
  static const String stickerAdopt = '${_stickersPath}adopt.png';
  static const String stickerAngry = '${_stickersPath}angry.png';
  static const String stickerArrogant = '${_stickersPath}arrogant.png';
  static const String stickerBack = '${_stickersPath}back.png';
  static const String stickerBirthday = '${_stickersPath}birthday.png';
  static const String stickerSmile = '${_stickersPath}smile.png';
  static const String stickerSick = '${_stickersPath}sick.png';
  
  // Cat Actions
  static const String stickerEat = '${_stickersPath}eat.png';
  static const String stickerEat2 = '${_stickersPath}eat (1).png';
  static const String stickerHungry = '${_stickersPath}hungry.png';
  static const String stickerJump = '${_stickersPath}jump.png';
  static const String stickerLick = '${_stickersPath}lick.png';
  static const String stickerPlay = '${_stickersPath}play.png';
  static const String stickerPlaying = '${_stickersPath}playing.png';
  static const String stickerScratch = '${_stickersPath}scratch.png';
  static const String stickerSit = '${_stickersPath}sit.png';
  static const String stickerSleep = '${_stickersPath}sleep.png';
  static const String stickerStretch = '${_stickersPath}stretch.png';
  static const String stickerYawn = '${_stickersPath}yawn.png';
  
  // Cat Character
  static const String stickerNeko = '${_stickersPath}neko.png';

  // ============================================================================
  // STICKER COLLECTIONS
  // ============================================================================
  
  /// All available stickers (for preloading or selection UI)
  static const List<String> allStickers = [
    stickerAdopt,
    stickerAngry,
    stickerArrogant,
    stickerBack,
    stickerBirthday,
    stickerSmile,
    stickerSick,
    stickerEat,
    stickerEat2,
    stickerHungry,
    stickerJump,
    stickerLick,
    stickerPlay,
    stickerPlaying,
    stickerScratch,
    stickerSit,
    stickerSleep,
    stickerStretch,
    stickerYawn,
    stickerNeko,
  ];
  
  /// Emotion stickers (for contextual reactions)
  static const List<String> emotionStickers = [
    stickerSmile,
    stickerAngry,
    stickerArrogant,
    stickerSick,
    stickerBirthday,
    stickerAdopt,
  ];
  
  /// Action stickers (for activity responses)
  static const List<String> actionStickers = [
    stickerEat,
    stickerHungry,
    stickerJump,
    stickerPlay,
    stickerSleep,
    stickerStretch,
    stickerYawn,
  ];

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get a random emotion sticker
  static String getRandomEmotionSticker() {
    return emotionStickers[DateTime.now().millisecond % emotionStickers.length];
  }
  
  /// Get a random action sticker
  static String getRandomActionSticker() {
    return actionStickers[DateTime.now().millisecond % actionStickers.length];
  }
  
  /// Get a random sticker from all available
  static String getRandomSticker() {
    return allStickers[DateTime.now().millisecond % allStickers.length];
  }

  // ============================================================================
  // STICKER CREDITS
  // ============================================================================
  
  /// Attribution information for stickers
  static const String stickerAuthor = 'Adorableninana';
  static const String stickerSourceUrl = 
      'https://www.flaticon.com/stickers-pack/cute-funny-orange-cat-illustration-sticker-set';
  static const String stickerPackName = 'Cute Funny Orange Cat Illustration Sticker Set';
  static const String stickerLicense = 'Free for personal and commercial use with attribution';
}
