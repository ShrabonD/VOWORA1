import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/birthday_theme.dart';
import '../../providers/birthday_provider.dart';
import '../../models/birthday/birthday_event.dart';
import 'birthday_create_event_screen.dart';
import 'birthday_ai_designer_screen.dart';
import 'birthday_theme_studio_screen.dart';
import 'birthday_budget_screen.dart';
import 'birthday_cake_studio_screen.dart';
import 'birthday_guests_screen.dart';
import 'birthday_invitation_screen.dart';
import 'birthday_checklist_screen.dart';
import 'birthday_gifts_screen.dart';
import 'birthday_timeline_screen.dart';
import 'birthday_memory_vault_screen.dart';
import 'birthday_service_selection_screen.dart';
import 'birthday_booking_history_screen.dart';

/// The central hub for the Birthday Studio module.
/// Provides access to upcoming celebrations, planning features, and analytics.
class BirthdayHomeScreen extends StatefulWidget {
  const BirthdayHomeScreen({super.key});

  @override
  State<BirthdayHomeScreen> createState() => _BirthdayHomeScreenState();
}

class _BirthdayHomeScreenState extends State<BirthdayHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BirthdayProvider>().loadAll();
      }
    });
  }

  /// Formats currency to Bangladeshi Taka (৳) with commas.
  String _formatCurrency(num amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = absAmount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return isNegative ? '-৳$formatted' : '৳$formatted';
  }

  /// Formats a DateTime into a friendly string (e.g. "Nov 15, 2026").
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BirthdayTheme.warmIvory,
      appBar: AppBar(
        backgroundColor: BirthdayTheme.warmIvory,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: BirthdayTheme.deepCocoa),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BirthdayTheme.deepCocoa,
            size: 20,
          ),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Birthday Studio', style: BirthdayTheme.heading2),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.receipt_long_rounded,
              color: BirthdayTheme.deepCocoa,
            ),
            tooltip: 'Booking History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BirthdayBookingHistoryScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: BirthdayTheme.deepCocoa,
            ),
            tooltip: 'Refresh',
            onPressed: () => context.read<BirthdayProvider>().loadAll(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<BirthdayProvider>(
        builder: (context, provider, child) {
          final upcomingEvents = provider.upcomingEvents;
          final activeEvent = provider.activeEvent;

          return RefreshIndicator(
            color: BirthdayTheme.mutedGold,
            backgroundColor: BirthdayTheme.softWhite,
            onRefresh: () => provider.loadAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading progress indicator
                  if (provider.isLoading)
                    const LinearProgressIndicator(
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BirthdayTheme.mutedGold,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // B. Header Section
                  _buildHeaderSection(),

                  const SizedBox(height: 24),

                  // C. Hero Banner
                  _buildHeroBanner(context),

                  const SizedBox(height: 24),

                  // C.1 VIP Service Booking & Concierge Banner
                  _buildServiceBookingBanner(context),

                  const SizedBox(height: 32),

                  // D. Upcoming Celebrations
                  _buildUpcomingCelebrations(context, provider, upcomingEvents),

                  const SizedBox(height: 32),

                  // E. Feature Grid (12 items)
                  _buildFeatureGrid(context),

                  const SizedBox(height: 32),

                  // F. Planning Overview Dashboard
                  _buildPlanningOverview(context, provider, activeEvent),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SECTION B: HEADER
  // ===========================================================================
  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Birthday Studio',
                        style: BirthdayTheme.heading1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: BirthdayTheme.champagneBeige.withValues(
                          alpha: 0.38,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BirthdayTheme.mutedGold.withValues(
                            alpha: 0.22,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BirthdayTheme.roseBeige.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cake_rounded,
                        color: BirthdayTheme.mutedGold,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Make their day unforgettable.',
                  style: BirthdayTheme.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION C: HERO BANNER
  // ===========================================================================
  Widget _buildHeroBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 230,
          width: double.infinity,
          decoration: BoxDecoration(
            color: BirthdayTheme.champagneBeige,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: BirthdayTheme.deepCocoa.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero Asset Image with error fallback
              Image.asset(
                BirthdayTheme.heroImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BirthdayTheme.champagneBeige,
                          BirthdayTheme.roseBeige.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.celebration_rounded,
                        color: BirthdayTheme.mutedGold.withValues(alpha: 0.6),
                        size: 64,
                      ),
                    ),
                  );
                },
              ),

              // Rose-tinted shading keeps the image visible while preserving text contrast.
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BirthdayTheme.roseBeige.withValues(alpha: 0.08),
                      BirthdayTheme.deepCocoa.withValues(alpha: 0.18),
                      BirthdayTheme.deepCocoa.withValues(alpha: 0.72),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),

              // Overlay content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: BirthdayTheme.deepCocoa.withValues(
                            alpha: 0.34,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: BirthdayTheme.softWhite.withValues(
                              alpha: 0.28,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Every Celebration Tells a Story',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: BirthdayTheme.softWhite,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Plan a birthday filled with beautiful little moments.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: BirthdayTheme.softWhite.withValues(
                                  alpha: 0.92,
                                ),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 11),
                            ElevatedButton(
                              style: BirthdayTheme.primaryButton,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BirthdayCreateEventScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: BirthdayTheme.softWhite,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plan a Birthday',
                                    style: BirthdayTheme.buttonText.copyWith(
                                      color: BirthdayTheme.softWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION C.1: SERVICE BOOKING & CONCIERGE BANNER
  // ===========================================================================
  Widget _buildServiceBookingBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildBlushFloralCardContainer(
        cornerScale: 1.1,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFAF2E6),
                          Color(0xFFF2DFC2),
                          Color(0xFFE4C69B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD4B179).withValues(alpha: 0.65),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC89B55).withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.room_service_rounded,
                      color: Color(0xFF7A4E2B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Birthday Services',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF38231D),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BirthdayTheme.mutedGold.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PREMIUM',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: BirthdayTheme.deepCocoa,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Catering, Photography & Decor Packages',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5D4037).withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Select verified packages, reserve real-time celebration slots with instant 15-minute holds, and checkout seamlessly with bKash or Cards.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  height: 1.45,
                  color: const Color(0xFF5D4037).withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: BirthdayTheme.primaryButton.copyWith(
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BirthdayServiceSelectionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: BirthdayTheme.softWhite,
                      ),
                      label: Text(
                        'Book Services',
                        style: BirthdayTheme.buttonText.copyWith(
                          fontSize: 13,
                          color: BirthdayTheme.softWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7A4E2B),
                      side: BorderSide(
                        color: const Color(0xFFD4B179).withValues(alpha: 0.7),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BirthdayBookingHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: Color(0xFF7A4E2B),
                    ),
                    label: Text(
                      'Bookings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7A4E2B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION D: UPCOMING CELEBRATIONS
  // ===========================================================================
  Widget _buildUpcomingCelebrations(
    BuildContext context,
    BirthdayProvider provider,
    List<BirthdayEvent> upcomingEvents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title + Count Badge + Add Action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('Upcoming Celebrations', style: BirthdayTheme.heading3),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: BirthdayTheme.mutedGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${upcomingEvents.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: BirthdayTheme.mutedGold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BirthdayCreateEventScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 16,
                  color: BirthdayTheme.mutedGold,
                ),
                label: Text(
                  'Add',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BirthdayTheme.mutedGold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (upcomingEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildEmptyCelebrationsState(context),
          )
        else
          SizedBox(
            height: 215,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = upcomingEvents[index];
                return _buildEventCard(context, provider, event);
              },
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // BLUSH FLORAL LUXURY STYLING HELPERS
  // ===========================================================================

  /// Container decoration for the Blush Floral Luxury design concept
  BoxDecoration _blushFloralCardDecoration({
    Border? border,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF9F8), // Soft blush ivory
          Color(0xFFFDF1EE), // Delicate blush pink
          Color(0xFFFAF3EC), // Warm ivory gold finish
        ],
        stops: [0.0, 0.52, 1.0],
      ),
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

  /// Reusable card container applying the Blush Floral Luxury aesthetic
  Widget _buildBlushFloralCardContainer({
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
      decoration: _blushFloralCardDecoration(
        border: border,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BlushFloralPainter(
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

  /// Empty state when no events exist yet
  Widget _buildEmptyCelebrationsState(BuildContext context) {
    return _buildBlushFloralCardContainer(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFAF2E6),
                    Color(0xFFF2DFC2),
                    Color(0xFFE4C69B),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4B179).withValues(alpha: 0.65),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC89B55).withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cake_outlined,
                color: Color(0xFF7A4E2B),
                size: 38,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No upcoming celebrations yet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF38231D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Start planning a memorable birthday celebration today with personalized themes and budgets.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF5D4037).withValues(alpha: 0.85),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B5E34),
                side: const BorderSide(color: Color(0xFFC59F58)),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: BirthdayTheme.buttonText,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BirthdayCreateEventScreen(),
                  ),
                );
              },
              child: const Text('Plan First Celebration'),
            ),
          ],
        ),
      ),
    );
  }

  /// Single Event Card in horizontal list
  Widget _buildEventCard(
    BuildContext context,
    BirthdayProvider provider,
    BirthdayEvent event,
  ) {
    final isSelected = provider.activeEvent?.id == event.id;
    final readinessPercent = isSelected ? provider.eventReadiness.round() : 65;

    return _buildBlushFloralCardContainer(
      width: 280,
      margin: const EdgeInsets.only(right: 14, bottom: 4, top: 2),
      border: Border.all(
        color: isSelected
            ? const Color(0xFFC79E5E)
            : const Color(0xFFEAD5CB).withValues(alpha: 0.8),
        width: isSelected ? 1.5 : 1.0,
      ),
      onTap: () {
        provider.setActiveEvent(event);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BirthdayCreateEventScreen(event: event),
          ),
        );
      },
      onLongPress: () => _showDeleteConfirmation(context, provider, event),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Person name & Days remaining
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.personName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF38231D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: event.daysRemaining <= 7
                        ? BirthdayTheme.alertOrange.withValues(alpha: 0.15)
                        : const Color(0xFFF1DCBE).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: event.daysRemaining <= 7
                          ? BirthdayTheme.alertOrange.withValues(alpha: 0.3)
                          : const Color(0xFFD4B179).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    event.daysRemaining == 0
                        ? 'Today!'
                        : '${event.daysRemaining}d left',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: event.daysRemaining <= 7
                          ? BirthdayTheme.alertOrange
                          : const Color(0xFF8B5E34),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Row 2: Date & Theme chip
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: Color(0xFFB0895A),
                ),
                const SizedBox(width: 5),
                Text(
                  _formatDate(event.eventDate),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF5D4037).withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF1E4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE5CEAE).withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      event.theme,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A332A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Row 3: Completion progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Readiness',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF5D4037).withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  '$readinessPercent%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9E6E38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (readinessPercent / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFEBDDD5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFC59F58),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: const Color(0xFFE8D3C8).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),

            // Row 4: Budget summary & Guest count
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14,
                  color: Color(0xFFB0895A),
                ),
                const SizedBox(width: 5),
                Text(
                  _formatCurrency(event.totalBudget),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF38231D),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.people_outline_rounded,
                  size: 14,
                  color: Color(0xFFB0895A),
                ),
                const SizedBox(width: 4),
                Text(
                  '${event.expectedGuestCount} guests',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF5D4037).withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Delete confirmation dialog on long-press
  void _showDeleteConfirmation(
    BuildContext context,
    BirthdayProvider provider,
    BirthdayEvent event,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: BirthdayTheme.softWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Celebration?', style: BirthdayTheme.heading3),
        content: Text(
          'Are you sure you want to delete the celebration for "${event.personName}"? All associated tasks, guests, gifts, and budgets will be permanently removed.',
          style: BirthdayTheme.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: BirthdayTheme.deepCocoa.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BirthdayTheme.errorRed,
              foregroundColor: BirthdayTheme.softWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await provider.deleteEvent(event.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Deleted celebration for ${event.personName}',
                    ),
                    backgroundColor: BirthdayTheme.deepCocoa,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION E: FEATURE GRID (12 ITEMS)
  // ===========================================================================
  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      _FeatureConfig(
        title: 'Birthday Planner',
        subtitle: 'Plan & manage',
        icon: Icons.event_note_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayCreateEventScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'AI Designer',
        subtitle: 'Smart suggestions',
        icon: Icons.auto_awesome_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayAiDesignerScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Theme Studio',
        subtitle: 'Palettes & decor',
        icon: Icons.palette_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayThemeStudioScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Budget Manager',
        subtitle: 'Track spending',
        icon: Icons.account_balance_wallet_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayBudgetScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Cake Studio',
        subtitle: 'Custom cakes',
        icon: Icons.cake_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayCakeStudioScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Guest & RSVP',
        subtitle: 'Track attendees',
        icon: Icons.people_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayGuestsScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Invitations',
        subtitle: 'Digital cards',
        icon: Icons.mail_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayInvitationScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Checklist',
        subtitle: 'Task timeline',
        icon: Icons.checklist_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayChecklistScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Gift Wishlist',
        subtitle: 'Registry ideas',
        icon: Icons.card_giftcard_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayGiftsScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Vendors',
        subtitle: 'Find & book',
        icon: Icons.store_rounded,
        onTap: () => Navigator.pushNamed(context, '/birthday-vendors'),
      ),
      _FeatureConfig(
        title: 'Party Timeline',
        subtitle: 'Day schedule',
        icon: Icons.timeline_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayTimelineScreen()),
        ),
      ),
      _FeatureConfig(
        title: 'Memory Vault',
        subtitle: 'Photos & moments',
        icon: Icons.photo_library_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BirthdayMemoryVaultScreen()),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Birthday Features', style: BirthdayTheme.heading3),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 380 ? 2 : 3;
              final childAspectRatio = constraints.maxWidth < 380 ? 1.05 : 0.88;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final item = features[index];
                  return _buildFeatureItem(item);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Single Feature Card styled with Blush Floral Luxury aesthetic
  Widget _buildFeatureItem(_FeatureConfig item) {
    return _buildBlushFloralCardContainer(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFAF2E6),
                    Color(0xFFF2DFC2),
                    Color(0xFFE4C69B),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD4B179).withValues(alpha: 0.65),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC89B55).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF7A4E2B),
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF38231D),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5D4037).withValues(alpha: 0.82),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION F: PLANNING OVERVIEW DASHBOARD
  // ===========================================================================
  Widget _buildPlanningOverview(
    BuildContext context,
    BirthdayProvider provider,
    BirthdayEvent? activeEvent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Planning Overview', style: BirthdayTheme.heading3),
              if (activeEvent != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: BirthdayTheme.champagneBeige.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activeEvent.personName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BirthdayTheme.deepCocoa,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          if (activeEvent == null)
            _buildEmptyOverviewState(context)
          else ...[
            // Active event selector indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF9F8),
                    Color(0xFFFAF2EB),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEAD5CB).withValues(alpha: 0.8),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4534).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    color: Color(0xFFB0895A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Active: ${activeEvent.personName}\'s Birthday (${activeEvent.theme})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF38231D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (provider.events.length > 1)
                    PopupMenuButton<BirthdayEvent>(
                      tooltip: 'Switch event',
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFFB0895A),
                        size: 20,
                      ),
                      onSelected: (event) => provider.setActiveEvent(event),
                      itemBuilder: (context) {
                        return provider.events.map((e) {
                          final isCurrent = e.id == activeEvent.id;
                          return PopupMenuItem<BirthdayEvent>(
                            value: e,
                            child: Row(
                              children: [
                                if (isCurrent)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFFB0895A),
                                    size: 16,
                                  )
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(
                                  e.personName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: const Color(0xFF38231D),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                ],
              ),
            ),

            // 8 Stat Cards Grid
            _buildStatCardsGrid(provider, activeEvent),
          ],
        ],
      ),
    );
  }

  /// Empty state when no active event is present
  Widget _buildEmptyOverviewState(BuildContext context) {
    return _buildBlushFloralCardContainer(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFAF2E6),
                    Color(0xFFF2DFC2),
                    Color(0xFFE4C69B),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4B179).withValues(alpha: 0.65),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC89B55).withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF7A4E2B),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No active celebration selected',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF38231D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a celebration from upcoming events or plan a new one to view planning metrics, task progress, and budget overview.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF5D4037).withValues(alpha: 0.82),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Grid of 8 stats
  Widget _buildStatCardsGrid(
    BirthdayProvider provider,
    BirthdayEvent activeEvent,
  ) {
    final stats = [
      _StatData(
        label: 'Total Events',
        value: '${provider.events.length}',
        icon: Icons.event_available_rounded,
        accentColor: BirthdayTheme.mutedGold,
      ),
      _StatData(
        label: 'Upcoming',
        value: '${provider.upcomingEvents.length}',
        icon: Icons.upcoming_rounded,
        accentColor: BirthdayTheme.deepCocoa,
      ),
      _StatData(
        label: 'Tasks Done',
        value: '${provider.totalTasksCompleted}',
        icon: Icons.task_alt_rounded,
        accentColor: BirthdayTheme.successGreen,
      ),
      _StatData(
        label: 'Tasks Left',
        value: '${provider.totalTasksPending}',
        icon: Icons.pending_actions_rounded,
        accentColor: BirthdayTheme.alertOrange,
      ),
      _StatData(
        label: 'Total Budget',
        value: _formatCurrency(activeEvent.totalBudget),
        icon: Icons.account_balance_wallet_rounded,
        accentColor: BirthdayTheme.mutedGold,
      ),
      _StatData(
        label: 'Actual Spend',
        value: _formatCurrency(provider.totalActualSpending),
        icon: Icons.shopping_bag_outlined,
        accentColor: BirthdayTheme.deepCocoa,
      ),
      _StatData(
        label: 'Remaining',
        value: _formatCurrency(provider.remainingBudget),
        icon: Icons.savings_outlined,
        accentColor: provider.remainingBudget >= 0
            ? BirthdayTheme.successGreen
            : BirthdayTheme.errorRed,
      ),
      _StatData(
        label: 'Readiness',
        value: '${provider.eventReadiness.toStringAsFixed(0)}%',
        icon: Icons.speed_rounded,
        accentColor: BirthdayTheme.mutedGold,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 420 ? 2 : 4;
        final childAspectRatio = constraints.maxWidth < 420 ? 2.1 : 1.8;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildSingleStatCard(stat);
          },
        );
      },
    );
  }

  /// Single Stat Card styled with Blush Floral Luxury aesthetic
  Widget _buildSingleStatCard(_StatData stat) {
    return _buildBlushFloralCardContainer(
      cornerScale: 0.65,
      showBottomAccent: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFAF2E6),
                    Color(0xFFF2DFC2),
                    Color(0xFFE4C69B),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD4B179).withValues(alpha: 0.55),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC89B55).withValues(alpha: 0.16),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(stat.icon, color: stat.accentColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5D4037).withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.value,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF38231D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper data class for features
class _FeatureConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

/// Helper data class for dashboard stats
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });
}

/// Elegant watercolor floral corner decorations and subtle background pattern
/// specifically designed for the Blush Floral Luxury aesthetic.
class _BlushFloralPainter extends CustomPainter {
  final bool showCornerDecoration;
  final bool showBottomAccent;
  final double cornerScale;

  const _BlushFloralPainter({
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
  bool shouldRepaint(covariant _BlushFloralPainter oldDelegate) => false;
}

