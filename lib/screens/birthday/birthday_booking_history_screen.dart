import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/birthday_provider.dart';
import '../../models/birthday/birthday_booking_model.dart';
import '../../services/supabase_birthday_service.dart';
import 'core/birthday_theme.dart';

class BirthdayBookingHistoryScreen extends StatefulWidget {
  const BirthdayBookingHistoryScreen({super.key});

  @override
  State<BirthdayBookingHistoryScreen> createState() =>
      _BirthdayBookingHistoryScreenState();
}

class _BirthdayBookingHistoryScreenState
    extends State<BirthdayBookingHistoryScreen> {
  String _filter = 'All'; // 'All', 'Confirmed', 'Pending'

  String _formatCurrency(num amount) {
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '৳$formatted';
  }

  void _showReviewDialog(BuildContext context, BirthdayBooking booking) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: BirthdayTheme.warmIvoryBase,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rate & Review Services', style: BirthdayTheme.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How was your experience for booking ${booking.id}?',
                style: BirthdayTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFC59F58),
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: BirthdayTheme.inputDecoration(
                  'Write your feedback...',
                  hint: 'Tell us about the food, decor, and photos!',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: BirthdayTheme.primaryButton,
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isNotEmpty) {
                  await SupabaseBirthdayService.submitReview(
                    bookingId: booking.id,
                    userName: booking.contactName,
                    rating: rating,
                    comment: comment,
                  );
                }
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you! Your celebration review has been recorded.'),
                      backgroundColor: BirthdayTheme.darkWarmBrown,
                    ),
                  );
                }
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BirthdayTheme.warmIvory,
      appBar: AppBar(
        backgroundColor: BirthdayTheme.warmIvory,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BirthdayTheme.darkWarmBrown,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Booking History', style: BirthdayTheme.heading2),
      ),
      body: Consumer<BirthdayProvider>(
        builder: (context, provider, child) {
          final bookings = provider.userBookings.where((b) {
            if (_filter == 'Confirmed') return b.bookingStatus == BirthdayBookingStatus.confirmed;
            if (_filter == 'Pending') return b.bookingStatus == BirthdayBookingStatus.pending;
            return true;
          }).toList();

          return Column(
            children: [
              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: ['All', 'Confirmed', 'Pending'].map((f) {
                    final isSelected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: isSelected,
                        selectedColor: const Color(0xFFF2DFC2),
                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: BirthdayTheme.darkWarmBrown,
                        ),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),

              Expanded(
                child: bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BirthdayTheme.champagneGoldIconDecoration(radius: 20),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFF7A4E2B),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings found',
                              style: BirthdayTheme.heading3,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Explore services in Birthday Studio to plan your next event.',
                              style: BirthdayTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return _buildBookingCard(context, booking);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BirthdayBooking booking) {
    final isConfirmed = booking.bookingStatus == BirthdayBookingStatus.confirmed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BirthdayTheme.blushFloralCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    booking.id,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7A4E2B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isConfirmed
                          ? const Color(0xFFE8F4EC)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isConfirmed
                            ? const Color(0xFF8DC99F)
                            : const Color(0xFFFFB74D),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      booking.bookingStatus.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isConfirmed
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFB0895A)),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.eventDate.day}/${booking.eventDate.month}/${booking.eventDate.year}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BirthdayTheme.darkWarmBrown,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFB0895A)),
                  const SizedBox(width: 6),
                  Text(
                    booking.timeSlot.displayName,
                    style: BirthdayTheme.bodySmall,
                  ),
                ],
              ),
              if (booking.venueAddress.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFB0895A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.venueAddress,
                        style: BirthdayTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16, color: BirthdayTheme.subtleBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Paid: ${_formatCurrency(booking.totalAmount)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: BirthdayTheme.darkWarmBrown,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showReviewDialog(context, booking),
                    icon: const Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFFB0895A)),
                    label: Text(
                      'Rate Services',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB0895A),
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
}
