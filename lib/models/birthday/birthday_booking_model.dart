import 'birthday_service_models.dart';

/// Available time slots for a birthday event day.
enum BirthdayTimeSlot {
  morning,
  afternoon,
  evening;

  String get displayName {
    switch (this) {
      case BirthdayTimeSlot.morning:
        return 'Morning Session';
      case BirthdayTimeSlot.afternoon:
        return 'Afternoon Celebration';
      case BirthdayTimeSlot.evening:
        return 'Evening Gala';
    }
  }

  String get timing {
    switch (this) {
      case BirthdayTimeSlot.morning:
        return '10:00 AM – 02:00 PM';
      case BirthdayTimeSlot.afternoon:
        return '03:00 PM – 07:00 PM';
      case BirthdayTimeSlot.evening:
        return '07:30 PM – 11:30 PM';
    }
  }

  static BirthdayTimeSlot fromString(String val) {
    switch (val.toLowerCase()) {
      case 'morning':
        return BirthdayTimeSlot.morning;
      case 'afternoon':
        return BirthdayTimeSlot.afternoon;
      case 'evening':
      default:
        return BirthdayTimeSlot.evening;
    }
  }
}

/// Lifecycle status for birthday bookings.
enum BirthdayBookingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case BirthdayBookingStatus.pending:
        return 'Pending Confirmation';
      case BirthdayBookingStatus.confirmed:
        return 'Confirmed';
      case BirthdayBookingStatus.completed:
        return 'Completed';
      case BirthdayBookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  static BirthdayBookingStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'confirmed':
        return BirthdayBookingStatus.confirmed;
      case 'completed':
        return BirthdayBookingStatus.completed;
      case 'cancelled':
        return BirthdayBookingStatus.cancelled;
      case 'pending':
      default:
        return BirthdayBookingStatus.pending;
    }
  }
}

/// Booking slot representation with availability status and temporary hold expiration.
class BirthdayBookingSlot {
  final String id;
  final DateTime date;
  final BirthdayTimeSlot timeSlot;
  final String status; // 'available', 'reserved', 'booked'
  final DateTime? reservedUntil;
  final String? reservationToken;
  final String? bookingId;

  const BirthdayBookingSlot({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.reservedUntil,
    this.reservationToken,
    this.bookingId,
  });

  bool get isAvailable {
    if (status == 'booked') return false;
    if (status == 'reserved' && reservedUntil != null) {
      return DateTime.now().isAfter(reservedUntil!);
    }
    return status == 'available';
  }

  bool get isTemporaryHoldActive {
    if (status == 'reserved' && reservedUntil != null) {
      return DateTime.now().isBefore(reservedUntil!);
    }
    return false;
  }

  factory BirthdayBookingSlot.fromJson(Map<String, dynamic> json) {
    return BirthdayBookingSlot(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['slot_date'] as String? ?? '') ?? DateTime.now(),
      timeSlot: BirthdayTimeSlot.fromString(json['time_slot'] as String? ?? 'evening'),
      status: json['status'] as String? ?? 'available',
      reservedUntil: json['reserved_until'] != null
          ? DateTime.tryParse(json['reserved_until'] as String)
          : null,
      reservationToken: json['reservation_token'] as String?,
      bookingId: json['booking_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slot_date': date.toIso8601String().split('T').first,
        'time_slot': timeSlot.name,
        'status': status,
        'reserved_until': reservedUntil?.toIso8601String(),
        'reservation_token': reservationToken,
        'booking_id': bookingId,
      };
}

/// Full birthday booking model.
class BirthdayBooking {
  final String id;
  final String? userId;
  final String? eventId;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final DateTime eventDate;
  final BirthdayTimeSlot timeSlot;
  final int guestCount;
  final String venueAddress;
  final String specialNotes;
  final List<BirthdayServiceCartItem> items;
  final double subtotalAmount;
  final double serviceFee;
  final double discountAmount;
  final double totalAmount;
  final BirthdayBookingStatus bookingStatus;
  final String paymentStatus; // 'pending', 'successful', 'failed', 'cancelled', 'refunded'
  final DateTime createdAt;

  const BirthdayBooking({
    required this.id,
    this.userId,
    this.eventId,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.eventDate,
    required this.timeSlot,
    required this.guestCount,
    required this.venueAddress,
    this.specialNotes = '',
    required this.items,
    required this.subtotalAmount,
    this.serviceFee = 0.0,
    this.discountAmount = 0.0,
    required this.totalAmount,
    this.bookingStatus = BirthdayBookingStatus.pending,
    this.paymentStatus = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'event_id': eventId,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'event_date': eventDate.toIso8601String().split('T').first,
        'time_slot': timeSlot.name,
        'guest_count': guestCount,
        'venue_address': venueAddress,
        'special_notes': specialNotes,
        'subtotal_amount': subtotalAmount,
        'service_fee': serviceFee,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
        'booking_status': bookingStatus.name,
        'payment_status': paymentStatus,
        'created_at': createdAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      };
}
