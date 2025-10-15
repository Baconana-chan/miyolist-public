import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../../core/services/local_storage_service.dart';
import '../models/wrapup_data.dart';
import '../models/statistics_overview_data.dart';

/// Service for exporting charts and statistics as images
class ChartExportService {
  final LocalStorageService _storageService = LocalStorageService();

  /// Get export directory based on user settings
  /// Returns: Custom path from settings, or app's "exports" folder
  Future<Directory> _getExportDirectory() async {
    // Get user settings
    final settings = await _storageService.getUserSettings();
    
    // If custom path is set and valid, use it
    if (settings?.exportPath != null && settings!.exportPath!.isNotEmpty) {
      final customDir = Directory(settings.exportPath!);
      if (await customDir.exists()) {
        return customDir;
      } else {
        // Try to create custom directory
        try {
          await customDir.create(recursive: true);
          debugPrint('✅ Created custom export directory: ${settings.exportPath}');
          return customDir;
        } catch (e) {
          debugPrint('⚠️ Failed to create custom directory, using default: $e');
        }
      }
    }
    
    // Default: use app's "exports" folder
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory exportsDir = Directory('${appDir.path}/MiyoList_Exports');
    
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
      debugPrint('✅ Created MiyoList exports directory: ${exportsDir.path}');
    }
    
    return exportsDir;
  }
  
  /// Capture a widget with a styled background wrapper
  Future<String?> captureWidgetWithBackground({
    required GlobalKey key,
    required String filename,
    String? title,
    String? subtitle,
    double pixelRatio = 3.0,
  }) async {
    try {
      // Get the render object
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ Could not find RenderRepaintBoundary');
        return null;
      }

      // Capture the content
      final ui.Image contentImage = await boundary.toImage(pixelRatio: pixelRatio);
      
      // Create a canvas with background
      final int width = (contentImage.width * 1.1).toInt(); // Add 10% padding
      final int height = contentImage.height + 300; // Add space for header/footer
      
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Draw dark background (MiyoList theme)
      final Paint bgPaint = Paint()..color = const Color(0xFF1A1A1A);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        bgPaint,
      );
      
      // Draw header with gradient
      final Paint gradientPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, width.toDouble(), 150));
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), 150),
        gradientPaint,
      );
      
      // Draw title text
      if (title != null) {
        final ui.ParagraphBuilder titleBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.center,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        )
          ..pushStyle(
            ui.TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          )
          ..addText(title);
        
        final ui.Paragraph titleParagraph = titleBuilder.build()
          ..layout(ui.ParagraphConstraints(width: width.toDouble()));
        
        canvas.drawParagraph(titleParagraph, Offset(0, 40));
      }
      
      // Draw subtitle/date
      final String dateStr = subtitle ?? DateFormat('MMMM dd, yyyy').format(DateTime.now());
      final ui.ParagraphBuilder subtitleBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 28,
        ),
      )
        ..pushStyle(
          ui.TextStyle(
            color: Colors.white.withOpacity(0.9),
          ),
        )
        ..addText(dateStr);
      
      final ui.Paragraph subtitleParagraph = subtitleBuilder.build()
        ..layout(ui.ParagraphConstraints(width: width.toDouble()));
      
      canvas.drawParagraph(subtitleParagraph, Offset(0, 100));
      
      // Draw content image with padding
      final double contentX = (width - contentImage.width) / 2;
      final double contentY = 150 + 50; // Header + padding
      canvas.drawImage(contentImage, Offset(contentX, contentY), Paint());
      
      // Draw footer with branding
      final double footerY = height - 100;
      final ui.ParagraphBuilder footerBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 24,
        ),
      )
        ..pushStyle(
          ui.TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        )
        ..addText('Made with MiyoList 📊');
      
      final ui.Paragraph footerParagraph = footerBuilder.build()
        ..layout(ui.ParagraphConstraints(width: width.toDouble()));
      
      canvas.drawParagraph(footerParagraph, Offset(0, footerY));
      
      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(width, height);
      final ByteData? byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Failed to convert image to bytes');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get the export directory (custom or default app folder)
      final Directory exportsDir = await _getExportDirectory();

      // Create file with timestamp
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String filepath = '${exportsDir.path}${Platform.pathSeparator}${filename}_$timestamp.png';
      final File file = File(filepath);

      // Write file
      await file.writeAsBytes(pngBytes);

      debugPrint('✅ Image with background saved: $filepath');
      return filepath;
    } catch (e) {
      debugPrint('❌ Error capturing widget with background: $e');
      return null;
    }
  }
  /// Capture a widget as an image and save it to downloads folder
  /// Returns the path to the saved file
  Future<String?> captureAndSaveWidget({
    required GlobalKey key,
    required String filename,
    double pixelRatio = 3.0,
  }) async {
    try {
      // Get the render object
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ Could not find RenderRepaintBoundary');
        return null;
      }

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Failed to convert image to bytes');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get the export directory (custom or default app folder)
      final Directory exportsDir = await _getExportDirectory();

      // Create file with timestamp
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String filepath = '${exportsDir.path}${Platform.pathSeparator}${filename}_$timestamp.png';
      final File file = File(filepath);

      // Write file
      await file.writeAsBytes(pngBytes);

      debugPrint('✅ Image saved: $filepath');
      return filepath;
    } catch (e) {
      debugPrint('❌ Error capturing widget: $e');
      return null;
    }
  }

  /// Capture a widget and share it
  Future<bool> captureAndShareWidget({
    required GlobalKey key,
    required String filename,
    String? text,
    double pixelRatio = 3.0,
  }) async {
    try {
      // Get the render object
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ Could not find RenderRepaintBoundary');
        return false;
      }

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Failed to convert image to bytes');
        return false;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temp directory
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String filepath = '${tempDir.path}\\${filename}_$timestamp.png';
      final File file = File(filepath);
      await file.writeAsBytes(pngBytes);

      // Share the file
      final XFile xFile = XFile(filepath);
      await Share.shareXFiles(
        [xFile],
        text: text ?? 'Check out my anime statistics! 📊',
      );

      debugPrint('✅ Image shared: $filepath');
      return true;
    } catch (e) {
      debugPrint('❌ Error sharing widget: $e');
      return false;
    }
  }

  /// Capture a widget with styled background and share it
  Future<bool> captureAndShareWidgetWithBackground({
    required GlobalKey key,
    required String filename,
    String? title,
    String? subtitle,
    String? text,
    double pixelRatio = 3.0,
  }) async {
    try {
      // Capture with background first
      final String? filepath = await captureWidgetWithBackground(
        key: key,
        filename: filename,
        title: title,
        subtitle: subtitle,
        pixelRatio: pixelRatio,
      );

      if (filepath == null) {
        debugPrint('❌ Failed to capture widget for sharing');
        return false;
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(filepath)],
        text: text ?? 'Check out my MiyoList statistics! 📊',
      );

      debugPrint('✅ Shared with background: $filepath');
      return true;
    } catch (e) {
      debugPrint('❌ Error sharing widget with background: $e');
      return false;
    }
  }

  /// Capture multiple widgets and save them as a collage
  Future<String?> captureMultipleWidgets({
    required List<GlobalKey> keys,
    required String filename,
    double pixelRatio = 3.0,
  }) async {
    try {
      final List<ui.Image> images = [];

      // Capture all widgets
      for (final key in keys) {
        final RenderRepaintBoundary? boundary =
            key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

        if (boundary == null) continue;

        final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
        images.add(image);
      }

      if (images.isEmpty) {
        debugPrint('❌ No images captured');
        return null;
      }

      // Calculate total height and max width
      int totalHeight = 0;
      int maxWidth = 0;
      for (final image in images) {
        totalHeight += image.height;
        if (image.width > maxWidth) maxWidth = image.width;
      }

      // Create a canvas to combine images
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final Paint paint = Paint();

      int currentY = 0;
      for (final image in images) {
        canvas.drawImage(image, Offset(0, currentY.toDouble()), paint);
        currentY += image.height;
      }

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image combinedImage = await picture.toImage(maxWidth, totalHeight);
      final ByteData? byteData =
          await combinedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Failed to convert combined image to bytes');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get the downloads directory
      Directory? downloadsDir;
      if (Platform.isWindows) {
        final String userProfile = Platform.environment['USERPROFILE'] ?? '';
        downloadsDir = Directory('$userProfile\\Downloads');
      } else if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Create file with timestamp
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String filepath = '${downloadsDir.path}\\${filename}_$timestamp.png';
      final File file = File(filepath);

      // Write file
      await file.writeAsBytes(pngBytes);

      debugPrint('✅ Combined image saved: $filepath');
      return filepath;
    } catch (e) {
      debugPrint('❌ Error capturing multiple widgets: $e');
      return null;
    }
  }

  /// Generate a full wrap-up image from data (not a screenshot)
  /// This allows creating images taller than screen height with all data
  /// Supports weekly, monthly, and yearly wrap-ups
  Future<String?> generateWrapupImage({
    required WrapupData data,
    required String filename,
    double pixelRatio = 3.0,
  }) async {
    try {
      // Image dimensions
      const int width = 1080; // Full HD width
      int height = 2400; // Initial height, will adjust based on content
      
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      double currentY = 0;
      
      // === BACKGROUND ===
      final Paint bgPaint = Paint()..color = const Color(0xFF1A1A1A);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        bgPaint,
      );
      
      // === HEADER WITH GRADIENT ===
      final Paint gradientPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, 1080, 250));
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1080, 250),
        gradientPaint,
      );
      
      // Title with period
      currentY = 60;
      final periodIcon = data.period == WrapupPeriod.week ? '📅' 
          : data.period == WrapupPeriod.month ? '📆' 
          : '🎊';
      _drawText(
        canvas: canvas,
        text: '$periodIcon ${data.periodTitle} Wrap-Up',
        x: 540,
        y: currentY,
        fontSize: 64,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.center,
        maxWidth: 1000,
      );
      
      currentY = 150;
      final dateRange = '${DateFormat('MMM d').format(data.startDate)} - ${DateFormat('MMM d, yyyy').format(data.endDate)}';
      _drawText(
        canvas: canvas,
        text: dateRange,
        x: 540,
        y: currentY,
        fontSize: 32,
        color: Colors.white70,
        textAlign: TextAlign.center,
        maxWidth: 1000,
      );
      
      currentY = 300;
      
      // === MAIN STATS CARDS ===
      const double cardPadding = 40;
      const double cardSpacing = 30;
      const double cardWidth = 480;
      const double cardHeight = 180;
      
      // Row 1: New Entries, Completed
      _drawStatCard(
        canvas: canvas,
        x: cardPadding,
        y: currentY,
        width: cardWidth,
        height: cardHeight,
        icon: '✨',
        value: data.newEntriesCount.toString(),
        label: 'New Entries',
      );
      
      _drawStatCard(
        canvas: canvas,
        x: cardPadding * 2 + cardWidth,
        y: currentY,
        width: cardWidth,
        height: cardHeight,
        icon: '✅',
        value: data.completedCount.toString(),
        label: 'Completed',
      );
      
      currentY += cardHeight + cardSpacing;
      
      // Row 2: Episodes, Days Watched
      _drawStatCard(
        canvas: canvas,
        x: cardPadding,
        y: currentY,
        width: cardWidth,
        height: cardHeight,
        icon: '�',
        value: data.totalEpisodes.toString(),
        label: 'Episodes Watched',
      );
      
      _drawStatCard(
        canvas: canvas,
        x: cardPadding * 2 + cardWidth,
        y: currentY,
        width: cardWidth,
        height: cardHeight,
        icon: '⏱️',
        value: data.daysWatched.toStringAsFixed(1),
        label: 'Days Watched',
      );
      
      currentY += cardHeight + cardSpacing;
      
      // Row 3: Chapters (if any)
      if (data.totalChapters > 0) {
        _drawStatCard(
          canvas: canvas,
          x: cardPadding,
          y: currentY,
          width: cardWidth,
          height: cardHeight,
          icon: '📖',
          value: data.totalChapters.toString(),
          label: 'Chapters Read',
        );
        
        currentY += cardHeight + cardSpacing;
      }
      
      currentY += 40;
      
      // === SCORE DISTRIBUTION ===
      _drawSectionTitle(canvas, 'Score Distribution', currentY);
      currentY += 80;
      
      _drawScoreDistribution(
        canvas: canvas,
        x: cardPadding,
        y: currentY,
        width: width - cardPadding * 2,
        height: 350,
        scoreDistribution: data.scoreDistribution,
        meanScore: data.meanScore,
      );
      
      currentY += 350 + 60;
      
      // === TOP GENRES ===
      if (data.topGenres.isNotEmpty) {
        _drawSectionTitle(canvas, 'Top Genres', currentY);
        currentY += 80;
        
        _drawTopGenres(
          canvas: canvas,
          x: cardPadding,
          y: currentY,
          width: width - cardPadding * 2,
          genres: data.topGenres,
        );
        
        currentY += (data.topGenres.length.clamp(0, 10) * 70) + 60;
      }
      
      // === FOOTER ===
      currentY += 40;
      _drawText(
        canvas: canvas,
        text: 'Made with MiyoList 📊',
        x: 540,
        y: currentY,
        fontSize: 28,
        color: Colors.white54,
        textAlign: TextAlign.center,
        maxWidth: 1000,
      );
      
      currentY += 80;
      
      // Adjust final height
      height = currentY.toInt();
      
      // === CONVERT TO IMAGE ===
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(width, height);
      final ByteData? byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Failed to convert wrap-up image to bytes');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get the export directory
      final Directory exportsDir = await _getExportDirectory();

      // Create file with timestamp
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String filepath = '${exportsDir.path}${Platform.pathSeparator}${filename}_$timestamp.png';
      final File file = File(filepath);

      // Write file
      await file.writeAsBytes(pngBytes);

      debugPrint('✅ Wrap-up image generated: $filepath');
      return filepath;
    } catch (e) {
      debugPrint('❌ Error generating wrap-up image: $e');
      return null;
    }
  }
  
  /// Generate statistics overview image from data (replaces screenshot approach)
  /// This creates a professional export of current statistics
  Future<String?> generateStatisticsOverview({
    required StatisticsOverviewData data,
    required String filename,
    double pixelRatio = 3.0,
  }) async {
    try {
      // Image dimensions
      const int width = 1080;
      int height = 2200;
      
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      double currentY = 0;
      
      // === BACKGROUND ===
      final Paint bgPaint = Paint()..color = const Color(0xFF1A1A1A);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        bgPaint,
      );
      
      // === HEADER ===
      final Paint gradientPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, 1080, 220));
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1080, 220),
        gradientPaint,
      );
      
      currentY = 50;
      _drawText(
        canvas: canvas,
        text: 'MiyoList Statistics Overview',
        x: 540,
        y: currentY,
        fontSize: 56,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.center,
        maxWidth: 1000,
      );
      
      currentY = 130;
      final dateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());
      _drawText(
        canvas: canvas,
        text: '${data.contentType} • $dateStr',
        x: 540,
        y: currentY,
        fontSize: 28,
        color: Colors.white70,
        textAlign: TextAlign.center,
        maxWidth: 1000,
      );
      
      currentY = 270;
      
      // === MAIN STATS (2x2 Grid) ===
      const double cardPadding = 40;
      const double cardSpacing = 30;
      const double cardWidth = 480;
      const double cardHeight = 180;
      
      _drawStatCard(
        canvas: canvas,
        x: cardPadding,
        y: currentY,
        width: cardWidth,
        height: cardHeight,
        icon: '📋',
        value: data.totalEntries.toString(),
        label: 'Total Entries',
      );
      
      _drawStatCard(
        canvas: canvas,
        x: cardPadding * 2 + cardWidth,
        y: currentY,
        width: cardWidth,
        height: cardHeight,
        icon: '📺',
        value: data.totalEpisodes.toString(),
        label: 'Episodes',
      );
      
      currentY += cardHeight + cardSpacing;
      
      _drawStatCard(
        canvas: canvas,
        x: cardPadding,
        y: currentY,
        width: cardWidth,
        height: cardHeight,
        icon: '📖',
        value: data.totalChapters.toString(),
        label: 'Chapters',
      );
      
      _drawStatCard(
        canvas: canvas,
        x: cardPadding * 2 + cardWidth,
        y: currentY,
        width: cardWidth,
        height: cardHeight,
        icon: '⏱️',
        value: data.daysWatched.toStringAsFixed(1),
        label: 'Days Watched',
      );
      
      currentY += cardHeight + cardSpacing + 50;
      
      // === SCORE DISTRIBUTION ===
      _drawSectionTitle(canvas, 'Score Distribution', currentY);
      currentY += 80;
      
      _drawScoreDistribution(
        canvas: canvas,
        x: cardPadding,
        y: currentY,
        width: width - cardPadding * 2,
        height: 350,
        scoreDistribution: data.scoreDistribution,
        meanScore: data.meanScore,
      );
      
      currentY += 350 + 60;
      
      // === TOP GENRES ===
      if (data.topGenres.isNotEmpty) {
        _drawSectionTitle(canvas, 'Top Genres', currentY);
        currentY += 80;
        
        final genresToShow = data.topGenres.take(10).toList();
        _drawTopGenres(
          canvas: canvas,
          x: cardPadding,
          y: currentY,
          width: width - cardPadding * 2,
          genres: genresToShow,
        );
        
        currentY += (genresToShow.length * 70) + 60;
      }
      
      // === FOOTER ===
      currentY += 40;
      _drawText(
        canvas: canvas,
        text: 'Made with MiyoList 📊',
        x: 540,
        y: currentY,
        fontSize: 28,
        color: Colors.white54,
        textAlign: TextAlign.center,
        maxWidth: 1000,
      );
      
      currentY += 80;
      height = currentY.toInt();
      
      // === CONVERT TO IMAGE ===
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(width, height);
      final ByteData? byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Failed to convert overview image to bytes');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory exportsDir = await _getExportDirectory();
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String filepath = '${exportsDir.path}${Platform.pathSeparator}${filename}_$timestamp.png';
      final File file = File(filepath);
      await file.writeAsBytes(pngBytes);

      debugPrint('✅ Statistics overview image generated: $filepath');
      return filepath;
    } catch (e) {
      debugPrint('❌ Error generating statistics overview: $e');
      return null;
    }
  }
  
  // === HELPER METHODS FOR DRAWING ===
  
  /// Draw text on canvas
  void _drawText({
    required Canvas canvas,
    required String text,
    required double x,
    required double y,
    required double fontSize,
    required Color color,
    FontWeight? fontWeight,
    TextAlign textAlign = TextAlign.left,
    double maxWidth = double.infinity,
  }) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: textAlign,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    )
      ..pushStyle(ui.TextStyle(color: color))
      ..addText(text);
    
    final ui.Paragraph paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    
    final double offsetX = textAlign == TextAlign.center 
        ? x - (paragraph.width / 2)
        : x;
    
    canvas.drawParagraph(paragraph, Offset(offsetX, y));
  }
  
  /// Draw a stat card
  void _drawStatCard({
    required Canvas canvas,
    required double x,
    required double y,
    required double width,
    required double height,
    required String icon,
    required String value,
    required String label,
  }) {
    // Card background
    final RRect cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(20),
    );
    
    final Paint cardPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(cardRect, cardPaint);
    
    // Icon
    _drawText(
      canvas: canvas,
      text: icon,
      x: x + width / 2,
      y: y + 30,
      fontSize: 48,
      color: Colors.white,
      textAlign: TextAlign.center,
      maxWidth: width,
    );
    
    // Value
    _drawText(
      canvas: canvas,
      text: value,
      x: x + width / 2,
      y: y + 90,
      fontSize: 36,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center,
      maxWidth: width,
    );
    
    // Label
    _drawText(
      canvas: canvas,
      text: label,
      x: x + width / 2,
      y: y + 135,
      fontSize: 20,
      color: Colors.white70,
      textAlign: TextAlign.center,
      maxWidth: width,
    );
  }
  
  /// Draw section title
  void _drawSectionTitle(Canvas canvas, String title, double y) {
    _drawText(
      canvas: canvas,
      text: title,
      x: 540,
      y: y,
      fontSize: 40,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center,
      maxWidth: 1000,
    );
  }
  
  /// Draw score distribution bar chart
  void _drawScoreDistribution({
    required Canvas canvas,
    required double x,
    required double y,
    required double width,
    required double height,
    required Map<int, int> scoreDistribution,
    required double meanScore,
  }) {
    // Background
    final RRect bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = const Color(0xFF2A2A2A),
    );
    
    // Find max count for scaling
    int maxCount = 1;
    for (final count in scoreDistribution.values) {
      if (count > maxCount) maxCount = count;
    }
    
    // Draw bars for scores 1-10
    const double barSpacing = 10;
    final double barWidth = (width - 80) / 10 - barSpacing;
    const double chartHeight = 220;
    final double chartY = y + 80;
    
    for (int score = 1; score <= 10; score++) {
      final int count = scoreDistribution[score] ?? 0;
      final double barHeight = (count / maxCount) * chartHeight;
      final double barX = x + 40 + (score - 1) * (barWidth + barSpacing);
      final double barY = chartY + chartHeight - barHeight;
      
      // Color based on score
      Color barColor;
      if (score <= 3) {
        barColor = Colors.red;
      } else if (score <= 5) {
        barColor = Colors.orange;
      } else if (score <= 7) {
        barColor = Colors.yellow;
      } else if (score <= 9) {
        barColor = Colors.lightGreen;
      } else {
        barColor = Colors.green;
      }
      
      // Draw bar
      final RRect barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(barRect, Paint()..color = barColor);
      
      // Draw score label
      _drawText(
        canvas: canvas,
        text: score.toString(),
        x: barX + barWidth / 2,
        y: chartY + chartHeight + 10,
        fontSize: 18,
        color: Colors.white70,
        textAlign: TextAlign.center,
        maxWidth: barWidth,
      );
      
      // Draw count on top of bar
      if (count > 0) {
        _drawText(
          canvas: canvas,
          text: count.toString(),
          x: barX + barWidth / 2,
          y: barY - 25,
          fontSize: 16,
          color: Colors.white,
          textAlign: TextAlign.center,
          maxWidth: barWidth,
        );
      }
    }
    
    // Draw mean score
    _drawText(
      canvas: canvas,
      text: 'Mean Score: ${meanScore.toStringAsFixed(2)}',
      x: x + width / 2,
      y: y + 25,
      fontSize: 24,
      color: const Color(0xFF64B5F6),
      fontWeight: FontWeight.bold,
      textAlign: TextAlign.center,
      maxWidth: width,
    );
  }
  
  /// Draw top genres list with proper text clipping
  void _drawTopGenres({
    required Canvas canvas,
    required double x,
    required double y,
    required double width,
    required List<GenreCount> genres,
  }) {
    // Find max count for bar scaling
    int maxCount = 1;
    for (final genre in genres) {
      if (genre.count > maxCount) maxCount = genre.count;
    }
    
    double currentY = y;
    
    for (int i = 0; i < genres.length && i < 10; i++) {
      final genre = genres[i];
      
      // Background card
      final RRect cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, currentY, width, 60),
        const Radius.circular(12),
      );
      canvas.drawRRect(
        cardRect,
        Paint()..color = const Color(0xFF2A2A2A),
      );
      
      // Progress bar (adjusted to not overlap with count)
      final double maxBarWidth = width - 280; // Space for rank + name + count
      final double barWidth = (genre.count / maxCount) * maxBarWidth;
      final RRect barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 180, currentY + 15, barWidth, 30),
        const Radius.circular(8),
      );
      
      // Color gradient based on rank
      final Color barColor = i < 3 
          ? const Color(0xFF64B5F6) 
          : const Color(0xFF4A4A4A);
      
      canvas.drawRRect(barRect, Paint()..color = barColor);
      
      // Rank number
      _drawText(
        canvas: canvas,
        text: '#${i + 1}',
        x: x + 20,
        y: currentY + 18,
        fontSize: 22,
        color: Colors.white70,
        fontWeight: FontWeight.bold,
      );
      
      // Genre name with max width to prevent overlap
      _drawText(
        canvas: canvas,
        text: genre.genre,
        x: x + 70,
        y: currentY + 18,
        fontSize: 22,
        color: Colors.white,
        maxWidth: 100, // Limit width to prevent overlap
      );
      
      // Count on the right edge
      _drawText(
        canvas: canvas,
        text: genre.count.toString(),
        x: x + width - 50,
        y: currentY + 18,
        fontSize: 22,
        color: const Color(0xFF64B5F6),
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.right,
      );
      
      currentY += 70;
    }
  }
}

