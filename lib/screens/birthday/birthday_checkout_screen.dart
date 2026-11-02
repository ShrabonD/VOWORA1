import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/birthday_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/birthday/birthday_booking_model.dart';
import '../../models/birthday/birthday_payment_model.dart';
import '../../models/birthday/birthday_service_models.dart';
import 'core/birthday_theme.dart';

class BirthdayCheckoutScreen extends StatefulWidget {
  const BirthdayCheckoutScreen({super.key});

  @override
  State<BirthdayCheckoutScreen> createState() => _BirthdayCheckoutScreenState();
}

class _BirthdayCheckoutScreenState extends State<BirthdayCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();

  BirthdayPaymentMethod _selectedPaymentMethod = BirthdayPaymentMethod.bkash;
  bool _isPartialPayment = false;
  double _depositPercentage = 30.0;
  bool _isProcessingDemoPayment = false;
  bool _showSuccess = false;
  String? _demoBookingId;
  String? _demoTransactionId;
  double _amountPaid = 0;
  double _currentPaymentAmount = 0;
  double _remainingBalance = 0;
  DateTime? _paymentDeadline;
  final List<_DemoTransaction> _demoHistory = [];

  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15 minutes hold

  @override
  void initState() {
    super.initState();
    _startHoldTimer();
    final auth = context.read<AuthProvider>();
    if (auth.userProfile != null) {
      _nameController.text = auth.userProfile!.fullName;
      _phoneController.text = auth.userProfile!.phone;
      _emailController.text = auth.userProfile!.email;
    }
    _loadDemoHistory();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startHoldTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _handleTimerExpired();
      }
    });
  }

  void _handleTimerExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: BirthdayTheme.warmIvoryBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reservation Hold Expired', style: BirthdayTheme.heading3),
        content: Text(
          'Your 15-minute temporary slot reservation has expired to make the slot available to others. Please select your slot again to proceed.',
          style: BirthdayTheme.body,
        ),
        actions: [
          ElevatedButton(
            style: BirthdayTheme.primaryButton,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Return to Calendar'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num amount) {
    final absAmount = amount.abs();
    final formatted = absAmount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '৳$formatted';
  }

  String _formatTimer() {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        title: Text('Checkout & Payment', style: BirthdayTheme.heading2),
      ),
      body: Consumer<BirthdayProvider>(
        builder: (context, provider, child) {
          if (_showSuccess) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: _buildSuccessScreen(),
            );
          }
          final date = provider.selectedBookingDate ?? DateTime.now();
          final slot = provider.selectedBookingSlot ?? BirthdayTimeSlot.evening;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDemoModeBanner(),

                  const SizedBox(height: 14),

                  // 1. Temporary Hold Countdown Bar
                  _buildReservationHoldBar(),

                  const SizedBox(height: 16),

                  // 2. Event Summary Card
                  _buildEventSummaryCard(date, slot),

                  const SizedBox(height: 16),

                  // 3. Itemized Bill Breakdown Card
                  _buildItemizedBillCard(provider),

                  const SizedBox(height: 16),

                  _buildPaymentHistoryCard(),

                  const SizedBox(height: 16),

                  // 4. Contact & Venue Information
                  _buildContactFormCard(),

                  const SizedBox(height: 16),

                  // 5. Payment Gateway Selection
                  _buildPaymentPlanCard(provider.cartTotal, date),

                  const SizedBox(height: 16),

                  _buildPaymentMethodCard(),

                  const SizedBox(height: 12),

                  // 6. Pay & Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BirthdayTheme.champagneGoldDeep,
                        foregroundColor: BirthdayTheme.darkWarmBrown,
                        elevation: 3,
                        shadowColor: BirthdayTheme.mutedGold.withValues(
                          alpha: 0.25,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isProcessingDemoPayment
                          ? null
                          : () => _confirmDemoPayment(
                              provider: provider,
                              date: date,
                              slot: slot,
                            ),
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: Text(
                        _isProcessingDemoPayment
                            ? 'Processing demo…'
                            : 'Pay Now  ·  DEMO',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'No real money is transferred',
                      style: BirthdayTheme.bodySmall.copyWith(fontSize: 11),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReservationHoldBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFE65100), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Temporary Slot Lock: ${_formatTimer()} remaining',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSummaryCard(DateTime date, BirthdayTimeSlot slot) {
    return BirthdayTheme.blushFloralCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reserved Celebration Slot',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BirthdayTheme.darkWarmBrown,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Color(0xFFB0895A),
                ),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: BirthdayTheme.darkWarmBrown,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Color(0xFFB0895A),
                ),
                const SizedBox(width: 6),
                Text(
                  '${slot.displayName} (${slot.timing})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: BirthdayTheme.warmBrownMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemizedBillCard(BirthdayProvider provider) {
    return BirthdayTheme.blushFloralCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text('Booking Bill Summary', style: BirthdayTheme.heading3),
          subtitle: Text(
            'Total booking amount  ${_formatCurrency(provider.cartTotal)}',
            style: BirthdayTheme.bodySmall,
          ),
          leading: const Icon(
            Icons.receipt_long_rounded,
            color: BirthdayTheme.mutedGold,
          ),
          children: [
            for (final category in BirthdayServiceCategory.values) ...[
              _billCategoryRows(provider, category),
            ],
            _additionalServiceRows(provider),
            _billLine('Subtotal', _formatCurrency(provider.cartSubtotal)),
            _billLine(
              'Service & handling (3%)',
              _formatCurrency(provider.cartServiceFee),
            ),
            _billLine('Discounts', _formatCurrency(0)),
            const Divider(height: 20, color: BirthdayTheme.subtleBorder),
            _billLine(
              'Total booking amount',
              _formatCurrency(provider.cartTotal),
              emphasized: true,
            ),
            _billLine(
              'Amount due now',
              _formatCurrency(
                _selectedDueNow(
                  provider.cartTotal,
                  _currentEventDate(provider),
                ),
              ),
            ),
            _billLine(
              'Remaining balance',
              _formatCurrency(
                _selectedBalance(
                  provider.cartTotal,
                  _currentEventDate(provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _billCategoryRows(
    BirthdayProvider provider,
    BirthdayServiceCategory category,
  ) {
    final items = provider.serviceCart
        .where((item) => item.package.category == category)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 5),
          child: Text(
            category.displayName,
            style: BirthdayTheme.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...items.map((item) {
          final baseAmount = item.package.priceUnit == 'per_person'
              ? item.package.price * item.quantity
              : item.package.price;
          return _billLine(item.package.name, _formatCurrency(baseAmount));
        }),
      ],
    );
  }

  Widget _additionalServiceRows(BirthdayProvider provider) {
    final addons = provider.serviceCart
        .expand((item) => item.selectedAddons)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 5),
          child: Text(
            'Additional services',
            style: BirthdayTheme.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (addons.isEmpty)
          Text(
            'No additional services selected',
            style: BirthdayTheme.bodySmall,
          )
        else
          ...addons.map(
            (addon) => _billLine(addon.name, _formatCurrency(addon.price)),
          ),
      ],
    );
  }

  Widget _billLine(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasized
                  ? BirthdayTheme.body.copyWith(fontWeight: FontWeight.bold)
                  : BirthdayTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: emphasized
                ? BirthdayTheme.body.copyWith(fontWeight: FontWeight.bold)
                : BirthdayTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildContactFormCard() {
    return BirthdayTheme.blushFloralCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Celebrant & Venue Information',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BirthdayTheme.darkWarmBrown,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              style: BirthdayTheme.body,
              decoration: _bookingInputDecoration(
                'Full Name',
                hint: 'Celebrant or Host Name',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: BirthdayTheme.body,
              decoration: _bookingInputDecoration(
                'Phone Number',
                hint: '+880 17XXXXXXXX',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: BirthdayTheme.body,
              decoration: _bookingInputDecoration(
                'Email Address',
                hint: 'name@example.com',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _venueController,
              style: BirthdayTheme.body,
              decoration: _bookingInputDecoration(
                'Celebration Venue Address',
                hint: 'Banani / Gulshan / Home Address',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              style: BirthdayTheme.body,
              decoration: _bookingInputDecoration(
                'Special Requests / Theme Notes',
                hint:
                    'Cake cutting time, colour preferences, dietary requirements',
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _bookingInputDecoration(String label, {String? hint}) {
    return BirthdayTheme.inputDecoration(label, hint: hint).copyWith(
      labelStyle: GoogleFonts.plusJakartaSans(
        color: BirthdayTheme.darkWarmBrown,
        fontSize: 13,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: BirthdayTheme.warmBrownMuted,
        fontSize: 14,
      ),
    );
  }

  Widget _buildPaymentPlanCard(double total, DateTime eventDate) {
    final plan = BirthdayPaymentPlan.calculate(
      totalAmount: total,
      depositPercentage: _depositPercentage,
      eventDate: eventDate,
      today: DateTime.now(),
    );

    return BirthdayTheme.blushFloralCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a payment plan', style: BirthdayTheme.heading3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _paymentPlanOption(
                    title: 'Full Payment',
                    detail: 'Settle the total today',
                    amount: total,
                    selected: !_isPartialPayment,
                    icon: Icons.done_all_rounded,
                    onTap: () => setState(() => _isPartialPayment = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _paymentPlanOption(
                    title: 'Partial Payment',
                    detail: '${_depositPercentage.toStringAsFixed(0)}% deposit',
                    amount: plan.depositAmount,
                    selected: _isPartialPayment,
                    icon: Icons.payments_outlined,
                    onTap: () => setState(() => _isPartialPayment = true),
                  ),
                ),
              ],
            ),
            if (_isPartialPayment) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deposit percentage', style: BirthdayTheme.bodySmall),
                  Text(
                    '${_depositPercentage.toStringAsFixed(0)}%',
                    style: BirthdayTheme.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _depositPercentage,
                min: 5,
                max: 80,
                divisions: 15,
                activeColor: BirthdayTheme.champagneBorder,
                inactiveColor: BirthdayTheme.subtleBorder,
                onChanged: (value) =>
                    setState(() => _depositPercentage = value),
              ),
            ],
            const Divider(height: 20, color: BirthdayTheme.subtleBorder),
            _paymentAmountRow(
              'Total booking amount',
              _formatCurrency(plan.totalAmount),
            ),
            _paymentAmountRow(
              'Amount due now',
              _formatCurrency(
                _isPartialPayment ? plan.depositAmount : plan.totalAmount,
              ),
            ),
            if (_isPartialPayment) ...[
              _paymentAmountRow(
                'Remaining balance',
                _formatCurrency(plan.remainingBalance),
              ),
              _paymentAmountRow(
                'Balance payment deadline',
                _formatDate(plan.balanceDueAt),
              ),
            ],
            const SizedBox(height: 12),
            _buildPaymentProgress(total, eventDate),
          ],
        ),
      ),
    );
  }

  Widget _paymentPlanOption({
    required String title,
    required String detail,
    required double amount,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? BirthdayTheme.champagneGoldShimmer
              : BirthdayTheme.softWhite.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? BirthdayTheme.champagneBorder
                : BirthdayTheme.subtleBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: BirthdayTheme.mutedGold.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: BirthdayTheme.mutedGold),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 17,
                  color: selected
                      ? BirthdayTheme.champagneBorder
                      : BirthdayTheme.warmBrownMuted,
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: BirthdayTheme.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(detail, style: BirthdayTheme.bodySmall.copyWith(fontSize: 10)),
            const SizedBox(height: 3),
            Text(
              _formatCurrency(amount),
              style: BirthdayTheme.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProgress(double total, DateTime eventDate) {
    final paid = _demoBookingId == null ? 0.0 : _amountPaid;
    final progress = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
    final balance = (total - paid).clamp(0.0, total);
    final plan = BirthdayPaymentPlan.calculate(
      totalAmount: total,
      depositPercentage: _depositPercentage,
      eventDate: eventDate,
      today: DateTime.now(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Paid so far', style: BirthdayTheme.bodySmall),
            Text(
              _formatCurrency(paid),
              style: BirthdayTheme.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: BirthdayTheme.subtleBorder,
            valueColor: const AlwaysStoppedAnimation(
              BirthdayTheme.champagneBorder,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).round()}% paid',
              style: BirthdayTheme.bodySmall,
            ),
            Text(
              'Remaining ${_formatCurrency(balance)}',
              style: BirthdayTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (balance > 0) ...[
          const SizedBox(height: 5),
          Text(
            'Balance deadline: ${_formatDate(plan.balanceDueAt)}',
            style: BirthdayTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _paymentAmountRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: BirthdayTheme.bodySmall)),
          const SizedBox(width: 8),
          Text(
            value,
            style: BirthdayTheme.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return BirthdayTheme.blushFloralCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BirthdayTheme.darkWarmBrown,
              ),
            ),
            const SizedBox(height: 12),
            ...BirthdayPaymentMethod.values.map(_buildPaymentMethodOption),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(BirthdayPaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;
    final colors = switch (method) {
      BirthdayPaymentMethod.bkash => (
        const Color(0xFFE2136E),
        const Color(0xFFFFF0F6),
      ),
      BirthdayPaymentMethod.nagad => (
        const Color(0xFFF15A24),
        const Color(0xFFFFF2EB),
      ),
      BirthdayPaymentMethod.visa => (
        const Color(0xFF1A1F71),
        const Color(0xFFF0F2FF),
      ),
      BirthdayPaymentMethod.mastercard => (
        const Color(0xFFEB001B),
        const Color(0xFFFFF0F0),
      ),
      BirthdayPaymentMethod.bankTransfer => (
        BirthdayTheme.darkWarmBrown,
        BirthdayTheme.champagneGoldShimmer,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = method),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? BirthdayTheme.softWhite
                : BirthdayTheme.softWhite.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? BirthdayTheme.champagneBorder
                  : BirthdayTheme.subtleBorder,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: BirthdayTheme.mutedGold.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.$2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _paymentBrandMark(method, colors.$1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: BirthdayTheme.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Simulated payment',
                      style: BirthdayTheme.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? BirthdayTheme.champagneBorder
                    : BirthdayTheme.warmBrownMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentBrandMark(BirthdayPaymentMethod method, Color color) {
    if (method == BirthdayPaymentMethod.bankTransfer) {
      return Icon(Icons.account_balance_rounded, color: color, size: 22);
    }
    final label = switch (method) {
      BirthdayPaymentMethod.bkash => 'b',
      BirthdayPaymentMethod.nagad => 'N',
      BirthdayPaymentMethod.visa => 'VISA',
      BirthdayPaymentMethod.mastercard => 'MC',
      BirthdayPaymentMethod.bankTransfer => '',
    };
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: method == BirthdayPaymentMethod.visa ? 11 : 15,
      ),
    );
  }

  Widget _buildDemoModeBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: BirthdayTheme.champagneGoldShimmer,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: BirthdayTheme.champagneBorder.withValues(alpha: 0.8),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.science_outlined,
          color: BirthdayTheme.darkWarmBrown,
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'DEMO MODE  ·  No real money is transferred.',
            style: BirthdayTheme.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildPaymentHistoryCard() => BirthdayTheme.blushFloralCard(
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(
          Icons.history_rounded,
          color: BirthdayTheme.mutedGold,
        ),
        title: Text(
          'Demo Payment History',
          style: BirthdayTheme.heading3.copyWith(fontSize: 16),
        ),
        subtitle: Text(
          '${_demoHistory.length} simulated transaction${_demoHistory.length == 1 ? '' : 's'}',
          style: BirthdayTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: _demoHistory.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Your demo transactions will appear here.',
                    style: BirthdayTheme.bodySmall,
                  ),
                ),
              ]
            : _demoHistory.map(_buildHistoryEntry).toList(),
      ),
    ),
  );

  Widget _buildHistoryEntry(_DemoTransaction transaction) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: BirthdayTheme.softWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: BirthdayTheme.subtleBorder),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: BirthdayTheme.mutedGold,
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transaction.method.displayName}  ·  ${_formatCurrency(transaction.amount)}',
                style: BirthdayTheme.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '${transaction.transactionId}  ·  ${_formatDate(transaction.createdAt)}',
                style: BirthdayTheme.bodySmall.copyWith(fontSize: 10),
              ),
              Text(
                'DEMO SUCCESS  ·  Balance ${_formatCurrency(transaction.remainingBalance)}',
                style: BirthdayTheme.bodySmall.copyWith(
                  color: BirthdayTheme.mutedGold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Download demo receipt',
          onPressed: () => _downloadReceipt(transaction),
          icon: const Icon(
            Icons.download_outlined,
            color: BirthdayTheme.darkWarmBrown,
            size: 20,
          ),
        ),
      ],
    ),
  );

  Widget _buildSuccessScreen() {
    final bookingId = _demoBookingId ?? 'DEMO-BOOKING';
    final transactionId = _demoTransactionId ?? 'DEMO-TRANSACTION';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.55, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: BirthdayTheme.champagneGoldShimmer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: BirthdayTheme.champagneBorder,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: BirthdayTheme.darkWarmBrown,
                size: 52,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Payment Successful',
          textAlign: TextAlign.center,
          style: BirthdayTheme.heading1.copyWith(fontSize: 25),
        ),
        const SizedBox(height: 5),
        Text(
          'DEMO MODE · Simulated only; no real money was transferred.',
          textAlign: TextAlign.center,
          style: BirthdayTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        BirthdayTheme.blushFloralCard(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _paymentAmountRow('Booking ID', bookingId),
                _paymentAmountRow('Demo transaction ID', transactionId),
                _paymentAmountRow(
                  'Payment method',
                  _selectedPaymentMethod.displayName,
                ),
                _paymentAmountRow(
                  'Amount paid this transaction',
                  _formatCurrency(_currentPaymentAmount),
                ),
                _paymentAmountRow(
                  'Remaining balance',
                  _formatCurrency(_remainingBalance),
                ),
                if (_remainingBalance > 0 && _paymentDeadline != null)
                  _paymentAmountRow(
                    'Balance payment deadline',
                    _formatDate(_paymentDeadline!),
                  ),
                const SizedBox(height: 12),
                _buildPaymentProgress(
                  _amountPaid + _remainingBalance,
                  _paymentDeadline ?? DateTime.now(),
                ),
              ],
            ),
          ),
        ),
        if (_remainingBalance > 0) ...[
          const SizedBox(height: 14),
          _buildPaymentMethodCard(),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _demoHistory.isEmpty
              ? null
              : () => _downloadReceipt(_demoHistory.first),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download Receipt'),
          style: OutlinedButton.styleFrom(
            foregroundColor: BirthdayTheme.darkWarmBrown,
            side: const BorderSide(color: BirthdayTheme.champagneBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_remainingBalance > 0) ...[
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: _isProcessingDemoPayment
                ? null
                : _confirmRemainingDemoPayment,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text(
              'Pay Remaining Balance  ·  ${_formatCurrency(_remainingBalance)}',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: BirthdayTheme.darkWarmBrown,
              side: const BorderSide(color: BirthdayTheme.champagneBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            '/birthday-studio',
            (route) => route.isFirst,
          ),
          icon: const Icon(Icons.cake_outlined),
          label: const Text('Return to Birthday Dashboard'),
          style: ElevatedButton.styleFrom(
            backgroundColor: BirthdayTheme.champagneGoldDeep,
            foregroundColor: BirthdayTheme.darkWarmBrown,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildPaymentHistoryCard(),
      ],
    );
  }

  Future<void> _confirmDemoPayment({
    required BirthdayProvider provider,
    required DateTime date,
    required BirthdayTimeSlot slot,
  }) async {
    if (!_formKey.currentState!.validate() || provider.cartTotal <= 0) return;
    final plan = BirthdayPaymentPlan.calculate(
      totalAmount: provider.cartTotal,
      depositPercentage: _depositPercentage,
      eventDate: date,
      today: DateTime.now(),
    );
    final amount = _isPartialPayment ? plan.depositAmount : plan.totalAmount;
    await _showDemoConfirmation(
      amount: amount,
      balance: plan.totalAmount - amount,
      bookingDate: date,
      slot: slot,
      deadline: plan.balanceDueAt,
      totalAmount: plan.totalAmount,
      isInitialPayment: true,
    );
  }

  Future<void> _confirmRemainingDemoPayment() async {
    final provider = context.read<BirthdayProvider>();
    final date = provider.selectedBookingDate ?? DateTime.now();
    final slot = provider.selectedBookingSlot ?? BirthdayTimeSlot.evening;
    await _showDemoConfirmation(
      amount: _remainingBalance,
      balance: 0,
      bookingDate: date,
      slot: slot,
      deadline: _paymentDeadline ?? date,
      totalAmount: _amountPaid + _remainingBalance,
      isInitialPayment: false,
    );
  }

  Future<void> _showDemoConfirmation({
    required double amount,
    required double balance,
    required DateTime bookingDate,
    required BirthdayTimeSlot slot,
    required DateTime deadline,
    required double totalAmount,
    required bool isInitialPayment,
  }) async {
    if (_isProcessingDemoPayment || amount <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BirthdayTheme.warmIvoryBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm demo payment', style: BirthdayTheme.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay ${_formatCurrency(amount)} using ${_selectedPaymentMethod.displayName}?',
              style: BirthdayTheme.body,
            ),
            const SizedBox(height: 10),
            Text(
              'This is a simulated university-project transaction. No real money will be transferred and no gateway will be contacted.',
              style: BirthdayTheme.bodySmall,
            ),
            if (balance > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Remaining balance: ${_formatCurrency(balance)}',
                style: BirthdayTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BirthdayTheme.champagneGoldDeep,
              foregroundColor: BirthdayTheme.darkWarmBrown,
            ),
            child: const Text('Confirm demo payment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessingDemoPayment = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final now = DateTime.now();
    final bookingId =
        _demoBookingId ?? 'DEMO-BKG-${now.millisecondsSinceEpoch}';
    final transactionId = 'DEMO-${now.millisecondsSinceEpoch}';
    final newTotalPaid = (isInitialPayment ? 0 : _amountPaid) + amount;
    final newBalance = (totalAmount - newTotalPaid).clamp(0.0, totalAmount);
    final transaction = _DemoTransaction(
      bookingId: bookingId,
      transactionId: transactionId,
      method: _selectedPaymentMethod,
      amount: amount,
      remainingBalance: newBalance,
      createdAt: now,
      bookingDate: bookingDate,
      slotName: slot.displayName,
    );
    _demoHistory.insert(0, transaction);
    await _saveDemoHistory();
    if (!mounted) return;

    setState(() {
      _countdownTimer?.cancel();
      _isProcessingDemoPayment = false;
      _showSuccess = true;
      _demoBookingId = bookingId;
      _demoTransactionId = transactionId;
      _amountPaid = newTotalPaid;
      _currentPaymentAmount = amount;
      _remainingBalance = newBalance;
      _paymentDeadline = deadline;
    });
  }

  Future<void> _downloadReceipt(_DemoTransaction transaction) async {
    final receipt = [
      'VOWORA BIRTHDAY PAYMENT RECEIPT',
      'DEMO MODE - NO REAL MONEY WAS TRANSFERRED',
      '',
      'Booking ID: ${transaction.bookingId}',
      'Demo Transaction ID: ${transaction.transactionId}',
      'Payment Method: ${transaction.method.displayName}',
      'Amount Paid: ${_formatCurrency(transaction.amount)}',
      'Remaining Balance: ${_formatCurrency(transaction.remainingBalance)}',
      'Event Date: ${_formatDate(transaction.bookingDate)}',
      'Time Slot: ${transaction.slotName}',
      'Transaction Date: ${_formatDate(transaction.createdAt)}',
      'Status: SIMULATED SUCCESS',
    ].join('\n');
    try {
      await FileSaver.instance.saveFile(
        name: 'Vowora-Receipt-${transaction.transactionId}',
        bytes: Uint8List.fromList(utf8.encode(receipt)),
        fileExtension: 'txt',
        mimeType: MimeType.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demo receipt downloaded.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download receipt: $error')),
      );
    }
  }

  Future<void> _loadDemoHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final savedHistory = preferences.getString(
      'birthday_demo_payment_history_v1',
    );
    if (savedHistory == null) return;
    try {
      final decoded = jsonDecode(savedHistory) as List<dynamic>;
      final history = decoded
          .map(
            (entry) => _DemoTransaction.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(
        () => _demoHistory
          ..clear()
          ..addAll(history),
      );
    } catch (_) {
      await preferences.remove('birthday_demo_payment_history_v1');
    }
  }

  Future<void> _saveDemoHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'birthday_demo_payment_history_v1',
      jsonEncode(
        _demoHistory.map((transaction) => transaction.toJson()).toList(),
      ),
    );
  }

  double _selectedDueNow(double total, DateTime eventDate) {
    final plan = BirthdayPaymentPlan.calculate(
      totalAmount: total,
      depositPercentage: _depositPercentage,
      eventDate: eventDate,
      today: DateTime.now(),
    );
    return _isPartialPayment ? plan.depositAmount : plan.totalAmount;
  }

  double _selectedBalance(double total, DateTime eventDate) {
    final plan = BirthdayPaymentPlan.calculate(
      totalAmount: total,
      depositPercentage: _depositPercentage,
      eventDate: eventDate,
      today: DateTime.now(),
    );
    return _isPartialPayment ? plan.remainingBalance : 0;
  }

  DateTime _currentEventDate(BirthdayProvider provider) =>
      provider.selectedBookingDate ?? DateTime.now();

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _DemoTransaction {
  final String bookingId;
  final String transactionId;
  final BirthdayPaymentMethod method;
  final double amount;
  final double remainingBalance;
  final DateTime createdAt;
  final DateTime bookingDate;
  final String slotName;

  const _DemoTransaction({
    required this.bookingId,
    required this.transactionId,
    required this.method,
    required this.amount,
    required this.remainingBalance,
    required this.createdAt,
    required this.bookingDate,
    required this.slotName,
  });

  factory _DemoTransaction.fromJson(Map<String, dynamic> json) =>
      _DemoTransaction(
        bookingId: json['bookingId'] as String,
        transactionId: json['transactionId'] as String,
        method: BirthdayPaymentMethod.fromString(json['method'] as String),
        amount: (json['amount'] as num).toDouble(),
        remainingBalance: (json['remainingBalance'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        bookingDate: DateTime.parse(json['bookingDate'] as String),
        slotName: json['slotName'] as String,
      );

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'transactionId': transactionId,
    'method': method.dbValue,
    'amount': amount,
    'remainingBalance': remainingBalance,
    'createdAt': createdAt.toIso8601String(),
    'bookingDate': bookingDate.toIso8601String(),
    'slotName': slotName,
  };
}
