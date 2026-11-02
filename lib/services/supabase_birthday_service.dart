import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';
import '../../models/birthday/birthday_service_models.dart';
import '../../models/birthday/birthday_booking_model.dart';
import '../../models/birthday/birthday_payment_model.dart';
import '../../models/birthday/birthday_shared_photo_model.dart';

/// Service coordinating Birthday module interactions with Supabase database and storage,
/// with automatic local/demo fallback for offline resiliency.
class SupabaseBirthdayService {
  static bool get isReady => SupabaseService.isInitialized;

  // In-memory demo persistence when Supabase is in offline/demo mode
  static final List<BirthdayBooking> _localBookings = [];
  static final Map<String, BirthdayBookingSlot> _localSlots = {};
  static final List<BirthdaySharedPhoto> _localPhotos = [];

  // ===========================================================================
  // 1. SERVICES & PACKAGES
  // ===========================================================================

  /// Fetches all active birthday services and their packages.
  static Future<List<BirthdayServicePackage>> fetchAllPackages() async {
    if (isReady) {
      try {
        final response = await SupabaseService.client
            .from('birthday_service_packages')
            .select('*, birthday_services(category)')
            .eq('is_active', true);

        if (response.isNotEmpty) {
          return (response as List).map((row) {
            final catStr = row['birthday_services']?['category'] ?? 'decoration';
            return BirthdayServicePackage.fromJson(
              row,
              category: BirthdayServiceCategory.fromString(catStr),
            );
          }).toList();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error fetching packages from Supabase: $e');
      }
    }
    // Return curated luxury catalog fallback
    return _curatedFallbackPackages();
  }

  // ===========================================================================
  // 2. BOOKING SLOTS & AVAILABILITY
  // ===========================================================================

  /// Checks if a date & slot is available.
  static Future<bool> isSlotAvailable(DateTime date, BirthdayTimeSlot slot) async {
    final dateStr = date.toIso8601String().split('T').first;
    final slotKey = '$dateStr-${slot.name}';

    if (isReady) {
      try {
        final response = await SupabaseService.client
            .from('birthday_booking_slots')
            .select()
            .eq('slot_date', dateStr)
            .eq('time_slot', slot.name)
            .maybeSingle();

        if (response == null) return true;
        final slotObj = BirthdayBookingSlot.fromJson(response);
        return slotObj.isAvailable;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error checking slot in Supabase: $e');
      }
    }

    // Local check
    final local = _localSlots[slotKey];
    if (local == null) return true;
    return local.isAvailable;
  }

  /// Temporarily reserves a slot for checkout (e.g. 15 minute hold).
  static Future<bool> reserveSlotTemporary({
    required DateTime date,
    required BirthdayTimeSlot slot,
    required String token,
    Duration duration = const Duration(minutes: 15),
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final expiresAt = DateTime.now().add(duration);
    final slotKey = '$dateStr-${slot.name}';

    // First ensure available
    final available = await isSlotAvailable(date, slot);
    if (!available) return false;

    if (isReady) {
      try {
        await SupabaseService.client.from('birthday_booking_slots').upsert({
          'id': 'slot_$slotKey',
          'slot_date': dateStr,
          'time_slot': slot.name,
          'status': 'reserved',
          'reserved_by_user': SupabaseService.currentUser?.id,
          'reservation_token': token,
          'reserved_until': expiresAt.toIso8601String(),
        });
        return true;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error reserving slot in Supabase: $e');
      }
    }

    _localSlots[slotKey] = BirthdayBookingSlot(
      id: 'slot_$slotKey',
      date: date,
      timeSlot: slot,
      status: 'reserved',
      reservedUntil: expiresAt,
      reservationToken: token,
    );
    return true;
  }

  /// Releases a temporary reservation.
  static Future<void> releaseSlot(DateTime date, BirthdayTimeSlot slot) async {
    final dateStr = date.toIso8601String().split('T').first;
    final slotKey = '$dateStr-${slot.name}';

    if (isReady) {
      try {
        await SupabaseService.client
            .from('birthday_booking_slots')
            .delete()
            .eq('slot_date', dateStr)
            .eq('time_slot', slot.name)
            .eq('status', 'reserved');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error releasing slot in Supabase: $e');
      }
    }

    _localSlots.remove(slotKey);
  }

  // ===========================================================================
  // 3. BOOKINGS & PAYMENTS
  // ===========================================================================

  /// Submits a confirmed booking and records the verified payment transaction.
  static Future<bool> submitBooking({
    required BirthdayBooking booking,
    required BirthdayPayment payment,
  }) async {
    final dateStr = booking.eventDate.toIso8601String().split('T').first;
    final slotKey = '$dateStr-${booking.timeSlot.name}';

    if (isReady) {
      try {
        // 1. Insert booking
        await SupabaseService.client.from('birthday_bookings').insert(booking.toJson());

        // 2. Insert itemized items
        for (final item in booking.items) {
          await SupabaseService.client.from('birthday_booking_items').insert({
            'id': 'item_${DateTime.now().millisecondsSinceEpoch}_${item.package.id}',
            'booking_id': booking.id,
            'service_id': item.package.serviceId,
            'package_id': item.package.id,
            'service_category': item.package.category.dbValue,
            'package_name': item.package.name,
            'unit_price': item.package.price,
            'quantity': item.quantity,
            'selected_addons': item.selectedAddons.map((e) => e.toJson()).toList(),
            'item_total': item.totalCost,
            'custom_instructions': item.customNotes,
          });
        }

        // 3. Lock slot as 'booked'
        await SupabaseService.client.from('birthday_booking_slots').upsert({
          'id': 'slot_$slotKey',
          'slot_date': dateStr,
          'time_slot': booking.timeSlot.name,
          'status': 'booked',
          'booking_id': booking.id,
        });

        // 4. Log verified payment record
        await SupabaseService.client.from('birthday_payments').insert(payment.toJson());

        return true;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error creating booking in Supabase: $e');
      }
    }

    // Local in-memory persistence
    _localBookings.insert(0, booking);
    _localSlots[slotKey] = BirthdayBookingSlot(
      id: 'slot_$slotKey',
      date: booking.eventDate,
      timeSlot: booking.timeSlot,
      status: 'booked',
      bookingId: booking.id,
    );
    return true;
  }

  /// Loads all user bookings.
  static Future<List<BirthdayBooking>> fetchUserBookings(String? userId) async {
    if (isReady && userId != null) {
      try {
        final response = await SupabaseService.client
            .from('birthday_bookings')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        if (response.isNotEmpty) {
          return (response as List).map((row) {
            return BirthdayBooking(
              id: row['id'] as String,
              userId: row['user_id'] as String?,
              eventId: row['event_id'] as String?,
              contactName: row['contact_name'] as String,
              contactPhone: row['contact_phone'] as String,
              contactEmail: row['contact_email'] as String? ?? '',
              eventDate: DateTime.parse(row['event_date'] as String),
              timeSlot: BirthdayTimeSlot.fromString(row['time_slot'] as String),
              guestCount: (row['guest_count'] as num?)?.toInt() ?? 25,
              venueAddress: row['venue_address'] as String? ?? '',
              specialNotes: row['special_notes'] as String? ?? '',
              items: [],
              subtotalAmount: (row['subtotal_amount'] as num).toDouble(),
              serviceFee: (row['service_fee'] as num?)?.toDouble() ?? 0.0,
              discountAmount: (row['discount_amount'] as num?)?.toDouble() ?? 0.0,
              totalAmount: (row['total_amount'] as num).toDouble(),
              bookingStatus: BirthdayBookingStatus.fromString(row['booking_status'] as String),
              paymentStatus: row['payment_status'] as String? ?? 'pending',
              createdAt: DateTime.parse(row['created_at'] as String),
            );
          }).toList();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error loading user bookings: $e');
      }
    }

    return List.from(_localBookings);
  }

  // ===========================================================================
  // 4. SHARED EVENT PHOTO GALLERY
  // ===========================================================================

  /// Fetches shared photos for an event.
  static Future<List<BirthdaySharedPhoto>> fetchEventPhotos(String eventId) async {
    if (isReady) {
      try {
        final response = await SupabaseService.client
            .from('birthday_shared_photos')
            .select()
            .eq('event_id', eventId)
            .order('created_at', ascending: false);

        if (response.isNotEmpty) {
          return (response as List)
              .map((row) => BirthdaySharedPhoto.fromJson(row))
              .toList();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error loading photos from Supabase: $e');
      }
    }

    final localMatches = _localPhotos.where((p) => p.eventId == eventId).toList();
    if (localMatches.isNotEmpty) return localMatches;

    // Default sample luxury photos for demonstration
    return _curatedDefaultEventPhotos(eventId);
  }

  /// Adds a shared photo to the event gallery.
  static Future<bool> addEventPhoto(BirthdaySharedPhoto photo) async {
    if (isReady) {
      try {
        await SupabaseService.client.from('birthday_shared_photos').insert(photo.toJson());
        return true;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error inserting shared photo to Supabase: $e');
      }
    }

    _localPhotos.insert(0, photo);
    return true;
  }

  // ===========================================================================
  // 5. REVIEWS & RATINGS
  // ===========================================================================

  static Future<bool> submitReview({
    required String bookingId,
    required String userName,
    required int rating,
    required String comment,
    String? serviceId,
  }) async {
    if (isReady) {
      try {
        await SupabaseService.client.from('birthday_reviews').insert({
          'id': 'rev_${DateTime.now().millisecondsSinceEpoch}',
          'booking_id': bookingId,
          'service_id': serviceId,
          'user_id': SupabaseService.currentUser?.id,
          'user_name': userName,
          'rating': rating,
          'comment': comment,
        });
        return true;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error submitting review: $e');
      }
    }
    return true;
  }

  // ===========================================================================
  // FALLBACK SEED DATA
  // ===========================================================================

  static List<BirthdayServicePackage> _curatedFallbackPackages() {
    return [
      // 1. Food & Catering Packages
      const BirthdayServicePackage(
        id: 'pkg_cat_silver',
        serviceId: 'svc_catering',
        category: BirthdayServiceCategory.catering,
        name: 'Classic Celebration Feast',
        tier: BirthdayPackageTier.silver,
        price: 650.0,
        priceUnit: 'per_person',
        description: 'Delightful family buffet with aromatic Basmati Chicken Roast / Polao, fresh salad, sweet firni cups, and chilled drinks.',
        imageUrl: 'https://images.unsplash.com/photo-1555244162-803834f70033',
        inclusions: [
          'Basmati Chicken Roast / Polao',
          'Fresh Green Garden Salad & Raita',
          'Shahi Gulab Jamun or Firni Cups',
          'Chilled Soft Drinks & Mineral Water',
          'Standard Buffet Setup & Chafing Dishes',
        ],
        availableAddons: [
          BirthdayServiceAddon(id: 'add_cake', name: '1kg Custom Whipped Cream Cake', price: 1800),
          BirthdayServiceAddon(id: 'add_mocktails', name: 'Live Mocktail & Juice Bar', price: 4000),
        ],
      ),
      const BirthdayServicePackage(
        id: 'pkg_cat_gold',
        serviceId: 'svc_catering',
        category: BirthdayServiceCategory.catering,
        name: 'Royal Moghul Shahi Banquet',
        tier: BirthdayPackageTier.gold,
        price: 1100.0,
        priceUnit: 'per_person',
        description: 'Sumptuous feast featuring Dhaka special Mutton Kacchi Biryani, Saffron Chicken Roast, Jali Kebab, Borhani, and live dessert counter.',
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947',
        inclusions: [
          'Special Mutton Kacchi Biryani',
          'Chicken Roast with Saffron Honey Glaze',
          'Beef Jali Kebab & Mint Chutney',
          'Traditional Old Dhaka Borhani',
          'Shahi Tukra & Faluda Jars',
          'Dedicated Catering Waitstaff & Crockery',
        ],
        availableAddons: [
          BirthdayServiceAddon(id: 'add_pasta', name: 'Live Italian Pasta Station', price: 6000),
          BirthdayServiceAddon(id: 'add_choc', name: 'Belgian Chocolate Fountain with Marshmallows', price: 8000),
        ],
      ),
      const BirthdayServicePackage(
        id: 'pkg_cat_royal',
        serviceId: 'svc_catering',
        category: BirthdayServiceCategory.catering,
        name: 'Imperial Gourmet Extravaganza',
        tier: BirthdayPackageTier.royal,
        price: 1800.0,
        priceUnit: 'per_person',
        description: 'Grand multi-course culinary journey with live BBQ grill, dual Kacchi and seafood platters, imported patisserie bar, and butler service.',
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
        inclusions: [
          'Live BBQ & Tandoori Skewer Counter',
          'Grand Mutton Kacchi & Polao Dual Entree',
          'Golden Prawn Tempura & Finger Food',
          'Artisanal Cheese & Fruit Display Board',
          'Imported Ice Cream & Patisserie Bar',
          'White Glove Butler Dining Setup',
        ],
        availableAddons: [
          BirthdayServiceAddon(id: 'add_barista', name: 'Artisan Specialty Espresso Bar', price: 7500),
        ],
      ),

      // 2. Photography & Reels Packages
      const BirthdayServicePackage(
        id: 'pkg_pho_silver',
        serviceId: 'svc_photo',
        category: BirthdayServiceCategory.photography,
        name: 'Memories Starter Session',
        tier: BirthdayPackageTier.silver,
        price: 18000.0,
        priceUnit: 'package',
        description: '3 hours of senior candid coverage capturing guest arrivals, birthday toasts, cake cutting, and family group portraits.',
        imageUrl: 'https://images.unsplash.com/photo-1537633552985-df8429e8048b',
        inclusions: [
          '1 Senior Candid Photographer',
          '3 Hours Event Day Coverage',
          'Unlimited Raw High-Res Photos',
          '50 Master Color-Graded Portraits',
          'Private Cloud Gallery Link within 4 Days',
        ],
        availableAddons: [
          BirthdayServiceAddon(id: 'add_album', name: 'Hardcover Keepsake Photobook (20 Pages)', price: 6500),
          BirthdayServiceAddon(id: 'add_extra_hour', name: 'Additional Coverage Hour', price: 3000),
        ],
      ),
      const BirthdayServicePackage(
        id: 'pkg_pho_gold',
        serviceId: 'svc_photo',
        category: BirthdayServiceCategory.photography,
        name: 'Cinematic Story & Reel Package',
        tier: BirthdayPackageTier.gold,
        price: 32000.0,
        priceUnit: 'package',
        description: 'Full event photo and video coverage with 4K cinematic highlight film and custom vertical Reels for Instagram & TikTok.',
        imageUrl: 'https://images.unsplash.com/photo-1606800052052-a08af7148866',
        inclusions: [
          '1 Senior Photographer + 1 Cinematographer',
          '5 Hours Event Coverage',
          '100 Master Retouched Photographs',
          '2-3 Minute 4K Cinematic Highlight Film',
          '2 Vertical Instagram Reels / Shorts',
          'Delivered on Custom Engraved USB + Cloud',
        ],
        availableAddons: [
          BirthdayServiceAddon(id: 'add_drone', name: '4K Drone Aerial Venue Shots', price: 8000),
        ],
      ),
      const BirthdayServicePackage(
        id: 'pkg_pho_royal',
        serviceId: 'svc_photo',
        category: BirthdayServiceCategory.photography,
        name: 'Royal Masterpiece Production',
        tier: BirthdayPackageTier.royal,
        price: 55000.0,
        priceUnit: 'package',
        description: 'Elite 4-person crew with pre-birthday mini session, drone footage, luxury flush mount album, and live on-site digital photo booth.',
        imageUrl: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc',
        inclusions: [
          '2 Master Photographers + 2 Senior Cinematographers',
          'Full Event Day Coverage (No Hour Limit)',
          'Pre-Birthday Golden Hour Mini Portrait Shoot',
          'Full 4K Documentary Cut + Teaser Reel',
          'Live On-Site Digital Photo Booth with Instant Prints',
          'Premium Leather-Bound Flush Mount Album (40 Pages)',
        ],
        availableAddons: [],
      ),

      // 3. Styling & Decoration Packages
      const BirthdayServicePackage(
        id: 'pkg_dec_silver',
        serviceId: 'svc_decor',
        category: BirthdayServiceCategory.decoration,
        name: 'Elegance Blush & Pastel Backdrop',
        tier: BirthdayPackageTier.silver,
        price: 25000.0,
        priceUnit: 'package',
        description: 'Chic 8ft circular metal arch with soft blush pink florals, organic pastel balloon garland, and customized acrylic nameplate.',
        imageUrl: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3',
        inclusions: [
          '8ft Circular Metal Arch with Blush Silk Flowers',
          'Custom Birthday Person Name Acrylic Board',
          'Organic Pastel Balloon Garland (Dual Tone)',
          'Cake Table Plinth with Floral Accent Base',
          'Warm LED Ambience Spotlights',
        ],
        availableAddons: [
          BirthdayServiceAddon(id: 'add_neon', name: 'Happy Birthday Warm White Neon Sign', price: 3500),
          BirthdayServiceAddon(id: 'add_easel', name: 'Welcome Easel Board with Floral Spray', price: 4000),
        ],
      ),
      const BirthdayServicePackage(
        id: 'pkg_dec_gold',
        serviceId: 'svc_decor',
        category: BirthdayServiceCategory.decoration,
        name: 'Champagne Gold Glamour Stage',
        tier: BirthdayPackageTier.gold,
        price: 45000.0,
        priceUnit: 'package',
        description: '12ft curved stage backdrop with champagne gold trim, hydrangea floral runners, fairy light entrance tunnel, and dessert pedestals.',
        imageUrl: 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3',
        inclusions: [
          '12ft Curved Stage Backdrop with Champagne Gold Trim',
          'Hydrangea & Rose Silk Floral Runners',
          'Fairy Light Tunnel / Grand Entrance Arch',
          '3 Luxury Cylinder Pedestals for Cake & Desserts',
          'Custom Neon Signboard & Number Lighted Props',
          'Ambient Floor Up-Lighting (6 Units)',
        ],
        availableAddons: [
          BirthdayServiceAddon(id: 'add_centerpieces', name: '10 Guest Table Flower Centerpieces', price: 8000),
          BirthdayServiceAddon(id: 'add_fog', name: 'Low Fog Dry-Ice for Cake Cutting Moment', price: 5000),
        ],
      ),
      const BirthdayServicePackage(
        id: 'pkg_dec_royal',
        serviceId: 'svc_decor',
        category: BirthdayServiceCategory.decoration,
        name: 'Imperial Palace Theme Wonderland',
        tier: BirthdayPackageTier.royal,
        price: 80000.0,
        priceUnit: 'package',
        description: 'Total ballroom transformation featuring fresh imported botanical blossoms, crystal chandeliers, draped ceiling, and coordinator.',
        imageUrl: 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d',
        inclusions: [
          'Complete Venue Theme Styling (Stage, Entrance, Seating)',
          '100% Fresh Imported Floral Installations',
          'Custom Architectural Castle / Royal Arch Backdrop',
          'Crystal Chandeliers & Overhead Ceiling Drapes',
          'Guest Tables with Silk Linen & Floral Candelabras',
          'Dedicated Decor Styling Coordinator On-Site',
        ],
        availableAddons: [],
      ),
    ];
  }

  static List<BirthdaySharedPhoto> _curatedDefaultEventPhotos(String eventId) {
    return [
      BirthdaySharedPhoto(
        id: 'p1',
        eventId: eventId,
        uploaderName: 'Tahsin (Photographer)',
        uploaderRole: 'photographer',
        imageUrl: 'https://images.unsplash.com/photo-1513151233558-d860c5398176',
        caption: 'The golden hour cake cutting moment ✨',
        likesCount: 24,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      BirthdaySharedPhoto(
        id: 'p2',
        eventId: eventId,
        uploaderName: 'Ayesha Rahman (Host)',
        uploaderRole: 'host',
        imageUrl: 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3',
        caption: 'Blowing out the candles with everyone!',
        likesCount: 18,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      BirthdaySharedPhoto(
        id: 'p3',
        eventId: eventId,
        uploaderName: 'Tanvir (Guest)',
        uploaderRole: 'guest',
        imageUrl: 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d',
        caption: 'Beautiful blush floral stage decor!',
        likesCount: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      BirthdaySharedPhoto(
        id: 'p4',
        eventId: eventId,
        uploaderName: 'Tahsin (Photographer)',
        uploaderRole: 'photographer',
        imageUrl: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc',
        caption: 'Family portrait at the entrance arch',
        likesCount: 31,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ];
  }
}
