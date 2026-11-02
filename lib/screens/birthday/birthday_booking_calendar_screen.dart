import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/birthday_provider.dart';
import '../../models/birthday/birthday_booking_model.dart';
import '../../services/supabase_birthday_service.dart';
import 'core/birthday_theme.dart';
import 'birthday_checkout_screen.dart';

class BirthdayBookingCalendarScreen extends StatefulWidget {
  const BirthdayBookingCalendarScreen({super.key});

  @override
  State<BirthdayBookingCalendarScreen> createState() =>
      _BirthdayBookingCalendarScreenState();
}

class _BirthdayBookingCalendarScreenState
    extends State<BirthdayBookingCalendarScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  BirthdayTimeSlot _selectedSlot = BirthdayTimeSlot.evening;
  bool _isCheckingAvailability = false;
  bool _isSlotAvailable = true;
  bool _isReserving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAvailability();
    });
  }

  Future<void> _checkAvailability() async {
    setState(() => _isCheckingAvailability = true);
    final available = await SupabaseBirthdayService.isSlotAvailable(
      _selectedDate,
      _selectedSlot,
    );
    if (mounted) {
      setState(() {
        _isSlotAvailable = available;
        _isCheckingAvailability = false;
      });
    }
  }

  Future<void> _handleProceedToCheckout(BirthdayProvider provider) async {
    setState(() => _isReserving = true);

    provider.selectDateAndSlot(_selectedDate, _selectedSlot);
    final success = await provider.reserveSelectedSlot();

    if (!mounted) return;
    setState(() => _isReserving = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BirthdayCheckoutScreen(),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: BirthdayTheme.warmIvoryBase,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Slot Already Reserved', style: BirthdayTheme.heading3),
          content: Text(
            'This date and time slot has just been locked by another client or confirmed booking. Please select another time slot or date.',
            style: BirthdayTheme.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _checkAvailability();
              },
              child: const Text('Choose Another Slot'),
            ),
          ],
        ),
      );
    }
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
        title: Text('Select Booking Date & Slot', style: BirthdayTheme.heading2),
      ),
      body: Consumer<BirthdayProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Instructions / Booking Policy Banner
                _buildPolicyBanner(),

                const SizedBox(height: 16),

                // 2. Interactive Calendar Date Picker Card
                _buildDatePickerCard(),

                const SizedBox(height: 20),

                // 3. Time Slot Selector
                _buildSlotSelectorCard(),

                const SizedBox(height: 20),

                // 4. Live Availability Status Indicator
                _buildAvailabilityStatusBanner(),

                const SizedBox(height: 32),

                // 5. Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: BirthdayTheme.primaryButton,
                    onPressed: (_isSlotAvailable && !_isCheckingAvailability && !_isReserving)
                        ? () => _handleProceedToCheckout(provider)
                        : null,
                    child: _isReserving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Reserve Slot & Proceed to Checkout'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPolicyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECE1).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BirthdayTheme.champagneBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFFB0895A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'To guarantee flawless execution, our executive culinary and photography teams confirm only 1 celebration per slot. Temporary reservations are held for 15 minutes during checkout.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: BirthdayTheme.darkWarmBrown,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerCard() {
    return BirthdayTheme.blushFloralCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BirthdayTheme.champagneGoldIconDecoration(radius: 10),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF7A4E2B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Date',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BirthdayTheme.darkWarmBrown,
                        ),
                      ),
                      Text(
                        'Select the day of your celebration',
                        style: BirthdayTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: BirthdayTheme.champagneBorder,
                  onPrimary: Colors.white,
                  onSurface: BirthdayTheme.darkWarmBrown,
                ),
                iconTheme: const IconThemeData(color: BirthdayTheme.darkWarmBrown),
                datePickerTheme: const DatePickerThemeData(
                  headerHeadlineStyle: TextStyle(color: BirthdayTheme.darkWarmBrown),
                  weekdayStyle: TextStyle(color: BirthdayTheme.darkWarmBrown),
                  dayStyle: TextStyle(color: BirthdayTheme.darkWarmBrown),
                  yearStyle: TextStyle(color: BirthdayTheme.darkWarmBrown),
                ).copyWith(
                  dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return BirthdayTheme.warmBrownMuted.withValues(alpha: 0.55);
                    }
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return BirthdayTheme.darkWarmBrown;
                  }),
                  dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? BirthdayTheme.champagneBorder
                        : null;
                  }),
                ),
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (newDate) {
                  setState(() => _selectedDate = newDate);
                  _checkAvailability();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSelectorCard() {
    return BirthdayTheme.blushFloralCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BirthdayTheme.champagneGoldIconDecoration(radius: 10),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF7A4E2B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Session',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BirthdayTheme.darkWarmBrown,
                        ),
                      ),
                      Text(
                        'Choose the hours for your party',
                        style: BirthdayTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...BirthdayTimeSlot.values.map((slot) {
              final isSelected = _selectedSlot == slot;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedSlot = slot);
                    _checkAvailability();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? BirthdayTheme.champagneBorder
                            : BirthdayTheme.subtleBorder,
                        width: isSelected ? 1.5 : 0.8,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFC89B55).withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFFB0895A)
                              : BirthdayTheme.warmBrownMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: BirthdayTheme.darkWarmBrown,
                                ),
                              ),
                              Text(
                                slot.timing,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: BirthdayTheme.warmBrownMuted.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityStatusBanner() {
    if (_isCheckingAvailability) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BirthdayTheme.subtleBorder),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB0895A)),
            ),
            SizedBox(width: 10),
            Text('Checking calendar slot availability...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isSlotAvailable
            ? const Color(0xFFE8F4EC)
            : const Color(0xFFFBE8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isSlotAvailable
              ? const Color(0xFF8DC99F)
              : const Color(0xFFE5A8A8),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSlotAvailable
                ? Icons.check_circle_outline_rounded
                : Icons.highlight_off_rounded,
            color: _isSlotAvailable
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSlotAvailable
                  ? 'Slot is available for reservation!'
                  : 'Slot is already booked. Please choose another slot.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _isSlotAvailable
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFB71C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
