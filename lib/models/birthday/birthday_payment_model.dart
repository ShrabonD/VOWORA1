/// Supported payment methods for Bangladesh & International clients.
enum BirthdayPaymentMethod {
  bkash,
  nagad,
  visa,
  mastercard,
  bankTransfer;

  String get displayName {
    switch (this) {
      case BirthdayPaymentMethod.bkash:
        return 'bKash';
      case BirthdayPaymentMethod.nagad:
        return 'Nagad';
      case BirthdayPaymentMethod.visa:
        return 'Visa';
      case BirthdayPaymentMethod.mastercard:
        return 'Mastercard';
      case BirthdayPaymentMethod.bankTransfer:
        return 'Bank Payment / Bank Transfer';
    }
  }

  String get dbValue {
    switch (this) {
      case BirthdayPaymentMethod.bkash:
        return 'bkash';
      case BirthdayPaymentMethod.nagad:
        return 'nagad';
      case BirthdayPaymentMethod.visa:
        return 'visa';
      case BirthdayPaymentMethod.mastercard:
        return 'mastercard';
      case BirthdayPaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  static BirthdayPaymentMethod fromString(String val) {
    switch (val.toLowerCase()) {
      case 'bkash':
        return BirthdayPaymentMethod.bkash;
      case 'nagad':
        return BirthdayPaymentMethod.nagad;
      case 'visa':
        return BirthdayPaymentMethod.visa;
      case 'mastercard':
        return BirthdayPaymentMethod.mastercard;
      case 'card':
        return BirthdayPaymentMethod.visa;
      case 'bank_transfer':
      case 'bank':
      default:
        return BirthdayPaymentMethod.bankTransfer;
    }
  }
}

/// Payment lifecycle status.
enum BirthdayPaymentStatus {
  pending,
  successful,
  failed,
  cancelled,
  refunded;

  String get label {
    switch (this) {
      case BirthdayPaymentStatus.pending:
        return 'Pending Verification';
      case BirthdayPaymentStatus.successful:
        return 'Paid & Verified';
      case BirthdayPaymentStatus.failed:
        return 'Payment Failed';
      case BirthdayPaymentStatus.cancelled:
        return 'Cancelled';
      case BirthdayPaymentStatus.refunded:
        return 'Refunded';
    }
  }

  static BirthdayPaymentStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'successful':
      case 'verified':
      case 'paid':
        return BirthdayPaymentStatus.successful;
      case 'failed':
        return BirthdayPaymentStatus.failed;
      case 'cancelled':
        return BirthdayPaymentStatus.cancelled;
      case 'refunded':
        return BirthdayPaymentStatus.refunded;
      case 'pending':
      default:
        return BirthdayPaymentStatus.pending;
    }
  }
}

/// Payment record model.
class BirthdayPayment {
  final String id;
  final String bookingId;
  final String? userId;
  final double amount;
  final BirthdayPaymentMethod paymentMethod;
  final String transactionId;
  final String senderPhoneOrAccount;
  final String gatewayReference;
  final BirthdayPaymentStatus paymentStatus;
  final DateTime? verifiedAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const BirthdayPayment({
    required this.id,
    required this.bookingId,
    this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionId,
    this.senderPhoneOrAccount = '',
    this.gatewayReference = '',
    this.paymentStatus = BirthdayPaymentStatus.pending,
    this.verifiedAt,
    this.metadata = const {},
    required this.createdAt,
  });

  factory BirthdayPayment.fromJson(Map<String, dynamic> json) {
    return BirthdayPayment(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: BirthdayPaymentMethod.fromString(json['payment_method'] as String? ?? 'bkash'),
      transactionId: json['transaction_id'] as String? ?? '',
      senderPhoneOrAccount: json['sender_phone_or_account'] as String? ?? '',
      gatewayReference: json['gateway_reference'] as String? ?? '',
      paymentStatus: BirthdayPaymentStatus.fromString(json['payment_status'] as String? ?? 'pending'),
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'] as String) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'user_id': userId,
        'amount': amount,
        'payment_method': paymentMethod.dbValue,
        'transaction_id': transactionId,
        'sender_phone_or_account': senderPhoneOrAccount,
        'gateway_reference': gatewayReference,
        'payment_status': paymentStatus.name,
        'verified_at': verifiedAt?.toIso8601String(),
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };
}

    class BirthdayPaymentPlan {
      final double totalAmount;
      final double depositAmount;
      final double remainingBalance;
      final DateTime balanceDueAt;

      const BirthdayPaymentPlan({
        required this.totalAmount,
        required this.depositAmount,
        required this.remainingBalance,
        required this.balanceDueAt,
      });

      factory BirthdayPaymentPlan.calculate({
        required double totalAmount,
        required double depositPercentage,
        required DateTime eventDate,
        required DateTime today,
        int balanceDueDaysBeforeEvent = 7,
      }) {
        if (!totalAmount.isFinite || totalAmount < 0) {
          throw ArgumentError.value(totalAmount, 'totalAmount');
        }
        if (!depositPercentage.isFinite || depositPercentage < 0 || depositPercentage > 100) {
          throw ArgumentError.value(depositPercentage, 'depositPercentage');
        }
        if (balanceDueDaysBeforeEvent < 0) {
          throw ArgumentError.value(balanceDueDaysBeforeEvent, 'balanceDueDaysBeforeEvent');
        }

        final depositAmount =
            (totalAmount * depositPercentage / 100 * 100).roundToDouble() / 100;
        final proposedDueDate = eventDate.subtract(Duration(days: balanceDueDaysBeforeEvent));
        final dueDate = proposedDueDate.isBefore(today) ? eventDate : proposedDueDate;

        return BirthdayPaymentPlan(
          totalAmount: totalAmount,
          depositAmount: depositAmount,
          remainingBalance: totalAmount - depositAmount,
          balanceDueAt: dueDate,
        );
      }
    }
