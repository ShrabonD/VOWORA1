import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Birthday-specific visual theme. Used ONLY inside the Birthday module.
/// Implements the premium Blush Floral Luxury aesthetic.
class BirthdayTheme {
  // Birthday Color Palette
  static const Color warmIvory = Color(0xFFFAF5F2);
  static const Color champagneBeige = Color(0xFFEADBCF);
  static const Color roseBeige = Color(0xFFD9B7A7);
  static const Color mutedGold = Color(0xFFB28A63);
  static const Color deepCocoa = Color(0xFF382923);
  static const Color softWhite = Color(0xFFFFFFFF);
  static const Color subtleBorder = Color(0xFFE9D9D2);
  static const Color cardBg = Color(0xFFFFFAF8);
  static const Color successGreen = Color(0xFF6BAF7A);
  static const Color alertOrange = Color(0xFFE8A455);
  static const Color errorRed = Color(0xFFD46B6B);

  // Blush Floral Luxury Signature Palette
  static const Color blushIvoryTop = Color(0xFFFFF9F8);
  static const Color blushRose = Color(0xFFFDF1EE);
  static const Color warmIvoryBase = Color(0xFFFAF3EC);
  static const Color champagneGoldShimmer = Color(0xFFFAF2E6);
  static const Color champagneGold = Color(0xFFF2DFC2);
  static const Color champagneGoldDeep = Color(0xFFE4C69B);
  static const Color champagneBorder = Color(0xFFD4B179);
  static const Color darkWarmBrown = Color(0xFF38231D);
  static const Color warmBrownMuted = Color(0xFF5D4037);

  // Text Styles
  static TextStyle heading1 = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: darkWarmBrown,
    height: 1.3,
  );

  static TextStyle heading2 = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: darkWarmBrown,
    height: 1.3,
  );

  static TextStyle heading3 = GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: darkWarmBrown,
    height: 1.3,
  );

  static TextStyle subtitle = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    color: warmBrownMuted.withValues(alpha: 0.75),
    height: 1.5,
  );

  static TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    color: darkWarmBrown,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    color: warmBrownMuted.withValues(alpha: 0.8),
    height: 1.4,
  );

  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: mutedGold,
    letterSpacing: 0.5,
  );

  static TextStyle buttonText = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );

  // Gradient Background for Blush Floral Luxury Cards
  static const LinearGradient blushFloralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      blushIvoryTop,
      blushRose,
      warmIvoryBase,
    ],
    stops: [0.0, 0.52, 1.0],
  );

  // Decorations
  static BoxDecoration get cardDecoration => blushFloralCardDecoration();

  static BoxDecoration blushFloralCardDecoration({
    Border? border,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      gradient: blushFloralGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: border ??
          Border.all(
            color: const Color(0xFFEAD5CB).withValues(alpha: 0.8),
            width: 1.0,
          ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6B4534).withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFFE8B7A5).withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    gradient: blushFloralGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFEAD5CB), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: deepCocoa.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 9),
      ),
      BoxShadow(
        color: const Color(0xFFE8B7A5).withValues(alpha: 0.15),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  /// Champagne Gold Icon Container Decoration
  static BoxDecoration champagneGoldIconDecoration({
    double radius = 14,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          champagneGoldShimmer,
          champagneGold,
          champagneGoldDeep,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: champagneBorder.withValues(alpha: 0.65),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFC89B55).withValues(alpha: 0.22),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static InputDecoration inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon != null ? Icon(icon, color: mutedGold, size: 20) : null,
    labelStyle: GoogleFonts.plusJakartaSans(
      color: warmBrownMuted.withValues(alpha: 0.75),
      fontSize: 13,
    ),
    hintStyle: GoogleFonts.plusJakartaSans(
      color: warmBrownMuted.withValues(alpha: 0.4),
      fontSize: 14,
    ),
    filled: true,
    fillColor: warmIvory,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEAD5CB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEAD5CB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: champagneBorder, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: errorRed, width: 1.5),
    ),
  );

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFB0895A),
    foregroundColor: softWhite,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: buttonText,
  );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF8B5E34),
    side: const BorderSide(color: Color(0xFFC59F58)),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: buttonText,
  );

  /// Birthday hero image asset path
  static const String heroImage = 'assets/images/birthday/birthday_hero.jpg';

  /// Theme image paths
  static String themeImage(String key) => 'assets/images/birthday/theme_$key.jpg';

  /// Feature image paths
  static String featureImage(String key) => 'assets/images/birthday/$key.jpg';

  /// Reusable Card Container with integrated watercolor floral artwork
  static Widget blushFloralCard({
    required Widget child,
    Border? border,
    BorderRadius? borderRadius,
    bool showCornerDecoration = true,
    bool showBottomAccent = true,
    double cornerScale = 1.0,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: blushFloralCardDecoration(
        border: border,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BlushFloralPainter(
                  showCornerDecoration: showCornerDecoration,
                  showBottomAccent: showBottomAccent,
                  cornerScale: cornerScale,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: onTap != null || onLongPress != null
                  ? InkWell(
                      borderRadius: radius,
                      onTap: onTap,
                      onLongPress: onLongPress,
                      child: child,
                    )
                  : child,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an Image.asset with graceful fallback
  static Widget assetImage(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            gradient: blushFloralGradient,
          ),
          child: const Center(
            child: Icon(Icons.cake_rounded, color: mutedGold, size: 40),
          ),
        );
      },
    );
  }
}

/// Custom painter rendering subtle watercolor floral patterns and corner details.
class BlushFloralPainter extends CustomPainter {
  final bool showCornerDecoration;
  final bool showBottomAccent;
  final double cornerScale;

  const BlushFloralPainter({
    this.showCornerDecoration = true,
    this.showBottomAccent = true,
    this.cornerScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Soft watercolor wash petal blurs (extremely subtle 4-7% opacity)
    final washPaint1 = Paint()
      ..color = const Color(0xFFF7D9D0).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.25),
        width: size.width * 0.65,
        height: size.height * 0.6,
      ),
      washPaint1,
    );

    final washPaint2 = Paint()
      ..color = const Color(0xFFEBC7BC).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      size.width * 0.35,
      washPaint2,
    );

    // 2. Delicate floral corner decorations (Top-Right)
    if (showCornerDecoration) {
      _drawTopRightFloralBranch(canvas, size, cornerScale);
    }

    // 3. Delicate bottom-left leaf / petal accent
    if (showBottomAccent) {
      _drawBottomLeftFoliage(canvas, size, cornerScale);
    }
  }

  void _drawTopRightFloralBranch(Canvas canvas, Size size, double scale) {
    final stemPaint = Paint()
      ..color = const Color(0xFFC7A265).withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale
      ..strokeCap = StrokeCap.round;

    final petalFill = Paint()
      ..color = const Color(0xFFEBBBB0).withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final petalStroke = Paint()
      ..color = const Color(0xFFD4AF7A).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;

    final budPaint = Paint()
      ..color = const Color(0xFFC59F58).withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;

    // Primary gentle curving stem from top-right corner curving inward
    final stemPath = Path();
    stemPath.moveTo(size.width - 4 * scale, 3 * scale);
    stemPath.quadraticBezierTo(
      size.width - 22 * scale,
      8 * scale,
      size.width - 32 * scale,
      26 * scale,
    );
    canvas.drawPath(stemPath, stemPaint);

    // Secondary delicate branchlet
    final branchPath = Path();
    branchPath.moveTo(size.width - 15 * scale, 6 * scale);
    branchPath.quadraticBezierTo(
      size.width - 12 * scale,
      18 * scale,
      size.width - 22 * scale,
      28 * scale,
    );
    canvas.drawPath(branchPath, stemPaint);

    // Blooming rose / peony petal cluster in the corner
    _drawPetal(canvas, Offset(size.width - 18 * scale, 12 * scale), 7.5 * scale, 4.5 * scale, -0.6, petalFill, petalStroke);
    _drawPetal(canvas, Offset(size.width - 25 * scale, 18 * scale), 6.5 * scale, 4.0 * scale, -0.3, petalFill, petalStroke);
    _drawPetal(canvas, Offset(size.width - 12 * scale, 22 * scale), 5.5 * scale, 3.5 * scale, -1.1, petalFill, petalStroke);

    // Small delicate golden stamen / bud accents
    canvas.drawCircle(Offset(size.width - 32 * scale, 26 * scale), 1.5 * scale, budPaint);
    canvas.drawCircle(Offset(size.width - 22 * scale, 28 * scale), 1.2 * scale, budPaint);
    canvas.drawCircle(Offset(size.width - 8 * scale, 10 * scale), 1.2 * scale, budPaint);
  }

  void _drawBottomLeftFoliage(Canvas canvas, Size size, double scale) {
    final stemPaint = Paint()
      ..color = const Color(0xFFC7A265).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale
      ..strokeCap = StrokeCap.round;

    final leafFill = Paint()
      ..color = const Color(0xFFE8B6AB).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final leafStroke = Paint()
      ..color = const Color(0xFFD4AF7A).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6 * scale;

    final stemPath = Path();
    stemPath.moveTo(4 * scale, size.height - 3 * scale);
    stemPath.quadraticBezierTo(
      16 * scale,
      size.height - 8 * scale,
      24 * scale,
      size.height - 20 * scale,
    );
    canvas.drawPath(stemPath, stemPaint);

    _drawPetal(canvas, Offset(14 * scale, size.height - 12 * scale), 6.0 * scale, 3.5 * scale, 0.7, leafFill, leafStroke);
    _drawPetal(canvas, Offset(22 * scale, size.height - 18 * scale), 4.5 * scale, 2.5 * scale, 1.1, leafFill, leafStroke);
  }

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double radiusX,
    double radiusY,
    double angle,
    Paint fill,
    Paint stroke,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(center: Offset.zero, width: radiusX * 2, height: radiusY * 2);
    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BlushFloralPainter oldDelegate) => false;
}
