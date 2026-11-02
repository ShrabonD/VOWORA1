import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/birthday_provider.dart';
import '../../models/birthday/birthday_service_models.dart';
import 'core/birthday_theme.dart';
import 'birthday_booking_calendar_screen.dart';

class BirthdayServiceSelectionScreen extends StatefulWidget {
  final BirthdayServiceCategory initialCategory;

  const BirthdayServiceSelectionScreen({
    super.key,
    this.initialCategory = BirthdayServiceCategory.catering,
  });

  @override
  State<BirthdayServiceSelectionScreen> createState() =>
      _BirthdayServiceSelectionScreenState();
}

class _BirthdayServiceSelectionScreenState
    extends State<BirthdayServiceSelectionScreen> {
  late BirthdayServiceCategory _selectedCategory;
  final Map<String, int> _cateringHeadcounts = {};

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  String _formatCurrency(num amount) {
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '৳$formatted';
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
        title: Text('Select Birthday Services', style: BirthdayTheme.heading2),
        actions: [
          Consumer<BirthdayProvider>(
            builder: (context, provider, _) {
              if (provider.cartItemCount == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          BirthdayTheme.champagneGoldShimmer,
                          BirthdayTheme.champagneGold,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BirthdayTheme.champagneBorder, width: 0.8),
                    ),
                    child: Text(
                      '${provider.cartItemCount} Selected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: BirthdayTheme.darkWarmBrown,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<BirthdayProvider>(
        builder: (context, provider, child) {
          final packages = provider.packages
              .where((p) => p.category == _selectedCategory)
              .toList();

          return Column(
            children: [
              // 1. Category Switcher Tabs
              _buildCategoryTabs(),

              const SizedBox(height: 8),

              // 2. Package List
              Expanded(
                child: packages.isEmpty
                    ? Center(
                        child: Text(
                          'No packages available for this category.',
                          style: BirthdayTheme.body,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: packages.length,
                        itemBuilder: (context, index) {
                          final package = packages[index];
                          return _buildPackageCard(context, provider, package);
                        },
                      ),
              ),

              // 3. Bottom Selected Services Summary Tray
              if (provider.cartItemCount > 0)
                _buildCartSummaryTray(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: BirthdayServiceCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          IconData iconData;
          switch (cat) {
            case BirthdayServiceCategory.catering:
              iconData = Icons.restaurant_menu_rounded;
              break;
            case BirthdayServiceCategory.photography:
              iconData = Icons.camera_alt_rounded;
              break;
            case BirthdayServiceCategory.decoration:
              iconData = Icons.celebration_rounded;
              break;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: BirthdayTheme.blushFloralGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: BirthdayTheme.champagneBorder, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC89B55).withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      )
                    : BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: BirthdayTheme.subtleBorder, width: 0.8),
                      ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconData,
                      size: 20,
                      color: isSelected
                          ? const Color(0xFF7A4E2B)
                          : BirthdayTheme.warmBrownMuted.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.displayName.split(' ').first,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? BirthdayTheme.darkWarmBrown
                            : BirthdayTheme.warmBrownMuted.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    BirthdayProvider provider,
    BirthdayServicePackage package,
  ) {
    final isInCart = provider.isPackageInCart(package.id);
    final cartItem = provider.getCartItem(package.id);
    final isPerPerson = package.priceUnit == 'per_person';
    final currentQty = cartItem?.quantity ?? _cateringHeadcounts[package.id] ?? 25;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BirthdayTheme.blushFloralCard(
        border: Border.all(
          color: isInCart
              ? BirthdayTheme.champagneBorder
              : const Color(0xFFEAD5CB).withValues(alpha: 0.8),
          width: isInCart ? 1.5 : 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Tier Badge + Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BirthdayTheme.champagneGoldIconDecoration(
                      radius: 8,
                      borderWidth: 0.8,
                    ),
                    child: Text(
                      package.tier.label.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A4E2B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(package.price),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: BirthdayTheme.darkWarmBrown,
                        ),
                      ),
                      Text(
                        isPerPerson ? 'per guest' : 'full package',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: BirthdayTheme.warmBrownMuted.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                package.name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: BirthdayTheme.darkWarmBrown,
                ),
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                package.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: BirthdayTheme.warmBrownMuted.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              // Inclusions List
              Text(
                'Inclusions:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7A4E2B),
                ),
              ),
              const SizedBox(height: 6),
              ...package.inclusions.map((inc) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFFB0895A),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          inc,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: BirthdayTheme.darkWarmBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Headcount Selector (for Catering)
              if (isPerPerson) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Guest Headcount:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BirthdayTheme.darkWarmBrown,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: BirthdayTheme.subtleBorder),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_rounded,
                              size: 16,
                              color: BirthdayTheme.darkWarmBrown,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: currentQty > 10
                                ? () {
                                    final newQty = currentQty - 5;
                                    setState(() => _cateringHeadcounts[package.id] = newQty);
                                    if (isInCart) {
                                      provider.updateCartItemQuantity(package.id, newQty);
                                    }
                                  }
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$currentQty',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: BirthdayTheme.darkWarmBrown,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: BirthdayTheme.darkWarmBrown,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () {
                              final newQty = currentQty + 5;
                              setState(() => _cateringHeadcounts[package.id] = newQty);
                              if (isInCart) {
                                provider.updateCartItemQuantity(package.id, newQty);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // Optional Add-ons Section
              if (package.availableAddons.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Customizable Add-ons:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7A4E2B),
                  ),
                ),
                const SizedBox(height: 6),
                ...package.availableAddons.map((addon) {
                  final isAddonSelected = cartItem?.selectedAddons.any((a) => a.id == addon.id) ?? false;

                  return InkWell(
                    onTap: isInCart
                        ? () => provider.toggleCartItemAddon(package.id, addon)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isAddonSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: isAddonSelected
                                ? const Color(0xFFB0895A)
                                : BirthdayTheme.warmBrownMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              addon.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: BirthdayTheme.darkWarmBrown,
                              ),
                            ),
                          ),
                          Text(
                            '+${_formatCurrency(addon.price)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B5E34),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 14),

              // Action Buttons: Add / Remove
              SizedBox(
                width: double.infinity,
                child: isInCart
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BirthdayTheme.errorRed,
                          side: const BorderSide(color: Color(0xFFE5A8A8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => provider.removeCartItem(package.id),
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                        label: const Text('Remove from Event Plan'),
                      )
                    : ElevatedButton.icon(
                        style: BirthdayTheme.primaryButton,
                        onPressed: () {
                          provider.addOrUpdateCartItem(
                            package: package,
                            quantity: currentQty,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${package.name}" to your celebration!'),
                              backgroundColor: BirthdayTheme.darkWarmBrown,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: Text('Select for Celebration • ${_formatCurrency(isPerPerson ? package.price * currentQty : package.price)}'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummaryTray(BuildContext context, BirthdayProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: BirthdayTheme.darkWarmBrown.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.cartItemCount} Services Selected',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: BirthdayTheme.warmBrownMuted,
                    ),
                  ),
                  Text(
                    _formatCurrency(provider.cartTotal),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: BirthdayTheme.darkWarmBrown,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: BirthdayTheme.primaryButton,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BirthdayBookingCalendarScreen(),
                  ),
                );
              },
              child: Row(
                children: const [
                  Text('Select Date & Slot'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
