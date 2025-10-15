import 'package:flutter/material.dart';

/// Widget to display AniList donator badge
/// Tier levels: 0 = none, 1 = $1 (basic), 2 = $5 (custom text), 3 = $10 (site-wide custom), 4 = $20+ (animated rainbow)
class DonatorBadge extends StatefulWidget {
  final int donatorTier;
  final String? customBadgeText;
  final double fontSize;
  final bool showIcon;
  final EdgeInsets padding;

  const DonatorBadge({
    super.key,
    required this.donatorTier,
    this.customBadgeText,
    this.fontSize = 12,
    this.showIcon = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  State<DonatorBadge> createState() => _DonatorBadgeState();
}

class _DonatorBadgeState extends State<DonatorBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animation for tier 4 (rainbow effect)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    if (widget.donatorTier >= 4) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DonatorBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.donatorTier >= 4 && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.donatorTier < 4 && _controller.isAnimating) {
      _controller.stop();
    }
  }

  /// Get badge color based on tier
  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFFE91E63); // Pink (basic donator)
      case 2:
        return const Color(0xFF9C27B0); // Purple (custom text on profile)
      case 3:
        return const Color(0xFF673AB7); // Deep Purple (site-wide custom)
      case 4:
        return Colors.transparent; // Rainbow (handled by gradient)
      default:
        return Colors.grey;
    }
  }

  /// Get badge text based on tier
  String _getBadgeText() {
    if (widget.customBadgeText != null && widget.customBadgeText!.isNotEmpty) {
      return widget.customBadgeText!;
    }
    
    switch (widget.donatorTier) {
      case 1:
        return 'Donator';
      case 2:
      case 3:
      case 4:
        return 'Supporter'; // Default if no custom text
      default:
        return '';
    }
  }

  /// Get gradient colors for rainbow animation (tier 4)
  List<Color> _getRainbowColors(double animationValue) {
    final hue = (animationValue * 360) % 360;
    return [
      HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, (hue + 60) % 360, 0.8, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, (hue + 120) % 360, 0.8, 1.0).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.donatorTier == 0) return const SizedBox.shrink();

    final badgeText = _getBadgeText();
    if (badgeText.isEmpty) return const SizedBox.shrink();

    // Rainbow animated badge (tier 4)
    if (widget.donatorTier >= 4) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final colors = _getRainbowColors(_controller.value);
          return Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showIcon) ...[
                  Icon(
                    Icons.favorite,
                    size: widget.fontSize + 2,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  badgeText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Static badge (tier 1-3)
    final tierColor = _getTierColor(widget.donatorTier);
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: tierColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierColor.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              Icons.favorite,
              size: widget.fontSize + 2,
              color: tierColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            badgeText,
            style: TextStyle(
              color: tierColor,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to get donator tier description
String getDonatorTierDescription(int tier) {
  switch (tier) {
    case 1:
      return '\$1/month - Donator Badge';
    case 2:
      return '\$5/month - Custom Badge on Profile';
    case 3:
      return '\$10/month - Custom Badge Site-wide';
    case 4:
      return '\$20+/month - Animated Rainbow Badge';
    default:
      return '';
  }
}

/// Helper to check if user is donator
bool isDonator(int donatorTier) => donatorTier > 0;

/// Helper to check if user has custom badge
bool hasCustomBadge(int donatorTier) => donatorTier >= 2;

/// Helper to check if user has rainbow badge
bool hasRainbowBadge(int donatorTier) => donatorTier >= 4;
